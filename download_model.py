import os
import sys
import tempfile
import numpy as np
import soundfile as sf
import mlx_whisper

def download_model():
    MODEL_NAME = "mlx-community/whisper-turbo"
    MODEL_DIR = os.path.expanduser("~/whisper_models")
    
    print(f"Checking for Whisper model in {MODEL_DIR}...")
    
    try:
        os.makedirs(MODEL_DIR, exist_ok=True)
        
        # Create a tiny audio file for model verification
        print("Downloading/verifying Whisper model (this may take a while if downloading)...")
        samples = np.zeros(16000)  # 1 second of silence at 16kHz
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
            sf.write(temp_file.name, samples, 16000)
            mlx_whisper.transcribe(temp_file.name, path_or_hf_repo=MODEL_NAME)
            os.unlink(temp_file.name)
            
        print("✓ Model ready!")
        return True
    except Exception as e:
        print(f"Error downloading model: {str(e)}")
        return False

def main():
    success = download_model()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()