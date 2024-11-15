import os
import traceback
import numpy as np
import soundfile as sf
from flask import Flask, request, jsonify
import mlx_whisper
import tempfile

app = Flask(__name__)

MODEL_NAME = "mlx-community/whisper-turbo"
MODEL_DIR = os.path.expanduser("~/whisper_models")

os.makedirs(MODEL_DIR, exist_ok=True)

print(f"Using model {MODEL_NAME}")
print(f"Model directory: {MODEL_DIR}")

def create_empty_audio(duration=3, sample_rate=16000):
    """Create an empty audio file."""
    samples = np.zeros(int(duration * sample_rate))
    return samples, sample_rate

def preload_model():
    """Preload the model by transcribing an empty audio file."""
    print("Preloading model...")
    samples, sample_rate = create_empty_audio()
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
        sf.write(temp_audio.name, samples, sample_rate)
        try:
            mlx_whisper.transcribe(temp_audio.name, path_or_hf_repo=MODEL_NAME)
            print("Model preloaded successfully.")
        except Exception as e:
            print(f"Error preloading model: {str(e)}")
            print(traceback.format_exc())
        finally:
            os.unlink(temp_audio.name)

@app.route('/transcribe', methods=['POST'])
def transcribe():
    if 'audio' not in request.files:
        return jsonify({"error": "No audio file provided"}), 400
    
    audio_file = request.files['audio']
    
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
        audio_file.save(temp_audio.name)
        temp_audio_path = temp_audio.name
    
    try:
        print(f"Transcribing audio file: {temp_audio_path}")
        result = mlx_whisper.transcribe(temp_audio_path, path_or_hf_repo=MODEL_NAME)
        transcribed_text = result["text"]
        
        os.unlink(temp_audio_path)
        
        return jsonify({"text": transcribed_text})
    except Exception as e:
        error_traceback = traceback.format_exc()
        print(f"Error during transcription: {str(e)}")
        print(f"Traceback: {error_traceback}")
        
        os.unlink(temp_audio_path)
        return jsonify({"error": str(e), "traceback": error_traceback}), 500

if __name__ == '__main__':
    preload_model()
    app.run(port=5000, debug=True)