import queue
import time
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

        cpu_threads = max(1, (os.cpu_count() or 4))
        
        # Check for local bundled offline model first for 100% offline instant startup
        local_model_path = os.path.join(os.path.dirname(__file__), "models", f"faster-whisper-{model_size}")
        if not os.path.exists(local_model_path):
            local_model_path = os.path.join(os.path.dirname(__file__), "models", "faster-whisper-base")
            
        load_target = local_model_path if (os.path.exists(local_model_path) and os.path.exists(os.path.join(local_model_path, "model.bin"))) else model_size
        print(f"Loading Whisper model from: {load_target} with {cpu_threads} CPU threads...")
        try:
            self.model = WhisperModel(load_target, device="cpu", compute_type="int8", cpu_threads=cpu_threads)
        except Exception as e:
            print(f"Failed to load {load_target}, falling back to {model_size}: {e}")
            self.model = WhisperModel(model_size, device="cpu", compute_type="int8", cpu_threads=cpu_threads)
        print("Model loaded successfully.")
        
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
        max_silence_duration = 0.18  # Fast pause: 180ms pause triggers instant transcription
        max_speech_chunk = 1.5       # Fast streaming chunk: 1.5 seconds maximum continuous speech window
        ambient_noise = 150.0
        
        while self.is_recording:
            try:
                frame = self.audio_queue.get(timeout=0.03)
                
                # Check amplitude / energy
                samples = np.frombuffer(frame, dtype=np.int16)
                energy = float(np.abs(samples).mean())
                
                # Adaptive speech threshold
                threshold = max(ambient_noise * 1.2, 100.0)
                is_speech = energy > threshold
                
                if is_speech:
                    buffered_audio.extend(frame)
                    speech_duration += self.chunk_duration_ms / 1000.0
                    silence_duration = 0.0
                    
                    if speech_duration >= max_speech_chunk:
                        self._transcribe_buffer(buffered_audio)
                        overlap_bytes = int(self.sample_rate * 0.20 * 2)
                        buffered_audio = bytearray(buffered_audio[-overlap_bytes:])
                        speech_duration = 0.20
                        silence_duration = 0.0
                else:
                    ambient_noise = 0.95 * ambient_noise + 0.05 * energy
                    
                    if len(buffered_audio) > 0:
                        buffered_audio.extend(frame)
                        silence_duration += self.chunk_duration_ms / 1000.0
                        
                        if silence_duration >= max_silence_duration:
                            if speech_duration >= 0.15:
                                self._transcribe_buffer(buffered_audio)
                            buffered_audio.clear()
                            silence_duration = 0.0
                            speech_duration = 0.0
            except queue.Empty:
                continue
                
        # Final flush
        if len(buffered_audio) > 0 and speech_duration >= 0.15:
            self._transcribe_buffer(buffered_audio)

    def _transcribe_buffer(self, byte_data):
        audio_int16 = np.frombuffer(byte_data, dtype=np.int16)
        audio_float32 = audio_int16.astype(np.float32) / 32768.0
        
        if len(audio_float32) < self.sample_rate * 0.15:
            return
            
        max_abs = np.max(np.abs(audio_float32))
        if max_abs > 0.002:
            audio_float32 = (audio_float32 / max_abs) * 0.95
            
        initial_prompt = "Customer billing list: 2 tomato, 1kg onion, 500g Aachi Chilli Powder, 100g Sakthi Turmeric, 1L Gold Winner Sunflower Oil, 500ml Aavin Milk, Toor Dal, Atta, Green Chilli, Bread, Biscuit, 20 rupees."
        
        segments, info = self.model.transcribe(
            audio_float32, 
            language="en",
            beam_size=1,
            best_of=1,
            temperature=0.0,
            compression_ratio_threshold=2.4,
            log_prob_threshold=-1.0,
            no_speech_threshold=0.6,
            repetition_penalty=1.25,
            no_repeat_ngram_size=2,
            without_timestamps=True,
            condition_on_previous_text=False,
            vad_filter=False,
            initial_prompt=initial_prompt
        )
        text = " ".join([segment.text for segment in segments]).strip()
        
        # Deduplicate repetition loops (e.g. "kudu kudu kudu kudu")
        if text:
            words = text.split()
            if len(words) >= 2:
                # Remove consecutive duplicate words
                deduped = []
                for w in words:
                    if not deduped or deduped[-1].lower() != w.lower():
                        deduped.append(w)
                text = " ".join(deduped).strip()
        
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
            try:
                print("Trying fallback to default system recording device...")
                self.stream = sd.RawInputStream(
                    samplerate=self.sample_rate,
                    blocksize=self.chunk_size,
                    dtype='int16',
                    channels=1,
                    device=None,
                    callback=self.audio_callback
                )
                self.stream.start()
            except Exception as e2:
                print(f"Default microphone fallback also failed: {e2}")
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
