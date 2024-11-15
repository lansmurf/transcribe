#!/bin/bash

PROJECT_DIR="$(dirname "$(realpath "$0")")"
cd "$PROJECT_DIR"

# First check if the model is downloaded
echo "Checking Whisper model..."
python3 download_model.py
if [ $? -ne 0 ]; then
    echo "Failed to verify/download model. Exiting."
    exit 1
fi

# Check if the compiled client exists and is newer than the source file
if [ ! -f asr_client ] || [ front.swift -nt asr_client ]; then
    echo "Compiling Swift client..."
    swiftc -o asr_client front.swift
    if [ $? -ne 0 ]; then
        echo "Compilation failed. Exiting."
        exit 1
    fi
fi

# Start the Flask server in the background
echo "Starting transcription server..."
python3 app.py &
FLASK_PID=$!

# Wait a bit for the server to start
sleep 5

echo "Starting voice recognition client..."
echo "Press and hold Fn key to record, release to transcribe."

# Start the compiled Swift client
./asr_client

# When the Swift client exits, also stop the Flask server
kill $FLASK_PID