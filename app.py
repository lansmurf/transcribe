import os
import traceback
from flask import Flask, request, jsonify
import mlx_whisper

app = Flask(__name__)

MODEL_NAME = "mlx-community/whisper-turbo"

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400
    
    audio_file = request.files['audio']
    
    try:
        print("Transcribing audio...")
        result = mlx_whisper.transcribe(audio_file, path_or_hf_repo=MODEL_NAME)
        transcribed_text = result["text"]
        
        return jsonify({"text": transcribed_text})
    except Exception as e:
        error_traceback = traceback.format_exc()
        print(f"Error during transcription: {str(e)}")
        print(f"Traceback: {error_traceback}")
        return jsonify({"error": str(e), "traceback": error_traceback}), 500

if __name__ == '__main__':
    print(f"Starting transcription server using model {MODEL_NAME}")
    app.run(port=5005, debug=True)