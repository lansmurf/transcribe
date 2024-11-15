# Transcribe tool

Local voice-to-text transcription tool for macOS. Hold Fn key to record, release to transcribe, and the text appears at your cursor position.

## Features
- Quick recording trigger using the Fn key
- Uses whisper turbo via mlx
- Automatic clipboard insertion of transcribed text
- Fully offline

## Prerequisites
- macOS
- Python 3.10+
- Xcode Command Line Tools (for Swift)
```bash
xcode-select --install
```

## Installation
1. Clone the repository:
```bash
git clone [your-repo-url]
cd asr
```

2. Install dependencies:
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. Make the script executable:
```bash
chmod +x voice.sh
```

## Usage
1. Start the application:
```bash
./voice.sh
```

2. Once running:
   - Press and hold the Fn key to start recording
   - Speak clearly into your microphone
   - Release the Fn key to stop recording and trigger transcription
   - The transcribed text will automatically be pasted at your cursor position

3. To exit the application, press Ctrl+C in the terminal.

## Troubleshooting
- If you get Swift compiler errors, run `xcode-select --install`
