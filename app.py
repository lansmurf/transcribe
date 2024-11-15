import os
import traceback
import tempfile
import soundfile as sf
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
        # Save the uploaded file temporarily and load it properly
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
            audio_file.save(temp_file.name)
            print(f"Transcribing audio from {temp_file.name}...")
            
            result = mlx_whisper.transcribe(temp_file.name, path_or_hf_repo=MODEL_NAME)
            transcribed_text = result["text"]
            
            # Clean up the temporary file
            os.unlink(temp_file.name)
            
            return jsonify({"text": transcribed_text})
    except Exception as e:
        error_traceback = traceback.format_exc()
        print(f"Error during transcription: {str(e)}")
        print(f"Traceback: {error_traceback}")
        
        # Ensure temp file is cleaned up even if there's an error
        if 'temp_file' in locals():
            try:
                os.unlink(temp_file.name)
            except:
                pass
                
        return jsonify({"error": str(e), "traceback": error_traceback}), 500

def main():
    print(f"Starting transcription server using model {MODEL_NAME}")
    app.run(port=5005, debug=True)

if __name__ == '__main__':
    main()