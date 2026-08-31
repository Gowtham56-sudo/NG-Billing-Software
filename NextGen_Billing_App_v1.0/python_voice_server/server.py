import asyncio
import websockets
import json
import os
from audio_processor import AudioProcessor
from nlu_processor import NLUProcessor

def find_db_path():
    possible_paths = [
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".dart_tool", "sqflite_common_ffi", "databases", "nextgen_billing.db")),
        os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "nextgen_billing.db")),
        os.path.expandvars(r"%LOCALAPPDATA%\sqflite_common_ffi\databases\nextgen_billing.db"),
        os.path.expandvars(r"%USERPROFILE%\AppData\Local\sqflite_common_ffi\databases\nextgen_billing.db"),
        os.path.expandvars(r"%USERPROFILE%\Documents\nextgen_billing.db"),
        r"e:\NG-Billing Software\.dart_tool\sqflite_common_ffi\databases\nextgen_billing.db",
    ]
    for path in possible_paths:
        if os.path.exists(path):
            print(f"[Database] Connected to: {path}")
            return path
    print(f"[Database] Using default path: {possible_paths[0]}")
    return possible_paths[0]

DB_PATH = find_db_path()

audio_proc = AudioProcessor()
nlu_proc = NLUProcessor(db_path=DB_PATH)

async def process_queue(websocket, transcript_queue):
    while True:
        try:
            chunk = await transcript_queue.get()
            if not chunk or not chunk.strip():
                continue
                
            print(f"Processing chunk: {chunk}")
            
            # Send processing status
            await websocket.send(json.dumps({"status": "processing", "transcript": chunk}))
            
            # Run NLU in thread to not block event loop
            result_json = await asyncio.to_thread(nlu_proc.process_transcript, chunk)
            print("Gemini Output:", result_json)
            
            try:
                parsed_res = json.loads(result_json)
                parsed_res["type"] = "bill_update"
                await websocket.send(json.dumps(parsed_res))
            except json.JSONDecodeError:
                await websocket.send(json.dumps({"error": "Failed to parse JSON from Gemini"}))
        except asyncio.CancelledError:
            break
        except Exception as e:
            print(f"Error processing chunk: {e}")

async def handler(websocket):
    print("Client connected.")
    loop = asyncio.get_running_loop()
    transcript_queue = asyncio.Queue()
    queue_task = None
    
    def on_transcript(text):
        # Called from background audio thread
        loop.call_soon_threadsafe(transcript_queue.put_nowait, text)

    try:
        async for message in websocket:
            data = json.loads(message)
            command = data.get("command")
            
            if command == "start":
                print("Received START command.")
                # Set up continuous listening
                audio_proc.on_transcription_ready = on_transcript
                
                # Start processing queue if not already started
                if queue_task is None or queue_task.done():
                    queue_task = asyncio.create_task(process_queue(websocket, transcript_queue))
                    
                audio_proc.start_recording()
                await websocket.send(json.dumps({"status": "listening"}))
                
            elif command == "stop":
                print("Received STOP command.")
                final_transcript = audio_proc.stop_recording()
                audio_proc.on_transcription_ready = None
                
                # Process any leftover audio that was flushed during stop
                if not transcript_queue.empty():
                    print("Processing leftover queue items...")
                    while not transcript_queue.empty():
                        chunk = await transcript_queue.get()
                        if chunk and chunk.strip():
                            print(f"Processing final chunk: {chunk}")
                            result_json = await asyncio.to_thread(nlu_proc.process_transcript, chunk)
                            print("NLU Output:", result_json)
                            try:
                                parsed_res = json.loads(result_json)
                                parsed_res["type"] = "bill_update"
                                await websocket.send(json.dumps(parsed_res))
                            except json.JSONDecodeError:
                                pass
                
                if queue_task:
                    queue_task.cancel()
                    queue_task = None
                    
                await websocket.send(json.dumps({"status": "stopped"}))
                    
    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected.")
        audio_proc.stop_recording()
        audio_proc.on_transcription_ready = None
        if queue_task:
            queue_task.cancel()

async def main():
    async with websockets.serve(handler, "localhost", 8765):
        print("WebSocket Server running on ws://localhost:8765")
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
