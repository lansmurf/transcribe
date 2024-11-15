import os
import sys
import mlx_whisper

def download_model():
    MODEL_NAME = "mlx-community/whisper-turbo"
    MODEL_DIR = os.path.expanduser("~/whisper_models")
    
    print(f"Checking for Whisper model in {MODEL_DIR}...")
    
    try:
        os.makedirs(MODEL_DIR, exist_ok=True)
        print("Downloading/verifying Whisper model (this may take a while if downloading)...")
        mlx_whisper.load_model(MODEL_NAME)
        print("✓ Model ready!")
        return True
    except Exception as e:
        print(f"Error downloading model: {str(e)}")
        return False

if __name__ == "__main__":
    success = download_model()
    sys.exit(0 if success else 1)