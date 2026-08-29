import queue
import time
import webrtcvad
import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel
import threading

class AudioProcessor:
    def __init__(self, model_size="base", sample_rate=16000, chunk_duration_ms=30, on_transcription_ready=None):
        import os
        self.sample_rate = sample_rate
        self.chunk_duration_ms = chunk_duration_ms
        self.on_transcription_ready = on_transcription_ready
        self.chunk_size = int(self.sample_rate * self.chunk_duration_ms / 1000)
        
        self.vad = webrtcvad.Vad(1) 
        
        # Smart mic auto-detection (prioritize Microphone Array over disconnected jack)
        device_idx = os.getenv("AUDIO_DEVICE_INDEX")
        if device_idx:
            self.device_index = int(device_idx)
        else:
            self.device_index = None
            try:
                devices = sd.query_devices()
                for i, d in enumerate(devices):
                    if d.get('max_input_channels', 0) > 0:
                        name = d['name'].lower()
                        if 'array' in name:
                            self.device_index = i
                            break
                        elif 'microphone' in name and self.device_index is None:
                            self.device_index = i
            except Exception as e:
                print("Device query error:", e)
        
        dev_info = sd.query_devices(self.device_index) if self.device_index is not None else "Default"
        print(f"Using Microphone: [Device {self.device_index}] {dev_info}")

        print(f"Loading Whisper model ({model_size})...")
        try:
            self.model = WhisperModel(model_size, device="cpu", compute_type="int8")
        except Exception as e:
            print(f"Failed to load {model_size}, falling back to tiny: {e}")
            self.model = WhisperModel("tiny", device="cpu", compute_type="int8")
        print("Model loaded.")
        
        self.is_recording = False
        self.audio_queue = queue.Queue()
        self.transcript = ""
        self.transcript_lock = threading.Lock()
        self.stream = None
        self.process_thread = None

    def audio_callback(self, indata, frames, time_info, status):
        if status:
            print("SoundDevice status:", status)
        self.audio_queue.put(bytes(indata))

    def _process_audio_loop(self):
        buffered_audio = bytearray()
        silence_duration = 0.0
        speech_duration = 0.0
        max_silence_duration = 0.35  # 350ms of pause triggers transcription immediately
        ambient_noise = 200.0
        
        while self.is_recording:
            try:
                frame = self.audio_queue.get(timeout=0.1)
                
                # Check amplitude / energy
                samples = np.frombuffer(frame, dtype=np.int16)
                energy = float(np.abs(samples).mean())
                
                # Adaptive speech detection
                threshold = max(ambient_noise * 1.5, 800.0)
                is_speech = energy > threshold
                
                if is_speech:
                    buffered_audio.extend(frame)
                    speech_duration += self.chunk_duration_ms / 1000.0
                    silence_duration = 0.0
                else:
                    # Update background noise level smoothly when quiet
                    ambient_noise = 0.95 * ambient_noise + 0.05 * energy
                    
                    if len(buffered_audio) > 0:
                        buffered_audio.extend(frame)
                        silence_duration += self.chunk_duration_ms / 1000.0
                        
                        # Trigger live transcription as soon as you pause speaking
                        if silence_duration >= max_silence_duration:
                            if speech_duration >= 0.2:
                                self._transcribe_buffer(buffered_audio)
                            buffered_audio.clear()
                            silence_duration = 0.0
                            speech_duration = 0.0
            except queue.Empty:
                continue
                
        # Final flush
        if len(buffered_audio) > 0 and speech_duration >= 0.2:
            self._transcribe_buffer(buffered_audio)

    def _transcribe_buffer(self, byte_data):
        # Convert bytes to numpy float32 array (-1.0 to 1.0)
        audio_int16 = np.frombuffer(byte_data, dtype=np.int16)
        audio_float32 = audio_int16.astype(np.float32) / 32768.0
        
        # Minimum audio length for transcription
        if len(audio_float32) < self.sample_rate * 0.2:
            return
            
        # Peak normalize to ensure quiet speech is clearly heard
        max_abs = np.max(np.abs(audio_float32))
        if max_abs > 0.005:
            audio_float32 = (audio_float32 / max_abs) * 0.95
            
        initial_prompt = "Aavin milk, aavin milk gold, 500ml, 250ml, 1L, sunflower oil, clinic plus shampoo, biscuit, cake, packet, kilo, litre, gram, kaal, ara, mukka, onnu, rendu, moonu, naalu, anju, aaru, ezhu, ettu, ombadhu, pathu, irubadhu, muppadhu, naarpadhu, aimbadhu, nooru, thool, paruppu, arisi, maavu, soap, paste, brush"
        
        segments, info = self.model.transcribe(
            audio_float32, 
            beam_size=1, # Greedy search: 3x-5x faster on CPU!
            best_of=1,
            condition_on_previous_text=False, # Prevents loop hallucinations
            vad_filter=True,
            initial_prompt=initial_prompt
        )
        text = " ".join([segment.text for segment in segments]).strip()
        
        if text:
            with self.transcript_lock:
                self.transcript += " " + text
                self.transcript = self.transcript.strip()
            print("Partial Transcript:", text)
            if self.on_transcription_ready:
                self.on_transcription_ready(text)

    def start_recording(self):
        if self.is_recording:
            return
        self.is_recording = True
        self.transcript = ""
        while not self.audio_queue.empty():
            self.audio_queue.get()
            
        try:
            self.stream = sd.RawInputStream(
                samplerate=self.sample_rate,
                blocksize=self.chunk_size,
                dtype='int16',
                channels=1,
                device=self.device_index,
                callback=self.audio_callback
            )
            self.stream.start()
        except Exception as e:
            print(f"Failed to open audio stream (Device {self.device_index}): {e}")
            self.is_recording = False
            return
        
        self.process_thread = threading.Thread(target=self._process_audio_loop)
        self.process_thread.start()
        print("Microphone started.")

    def stop_recording(self):
        if not self.is_recording:
            return ""
        self.is_recording = False
        if self.stream:
            self.stream.stop()
            self.stream.close()
            
        if self.process_thread:
            self.process_thread.join()
            
        print("Microphone stopped.")
        with self.transcript_lock:
            return self.transcript
