#!/bin/bash

# Directory where your project is located
PROJECT_DIR="$HOME/Projects/asr"

# Change to the project directory
cd "$PROJECT_DIR"

# Check if the compiled client exists and is newer than the source file
if [ ! -f asr_client ] || [ front.swift -nt asr_client ]; then
    echo "Compiling Swift script..."
    swiftc -o asr_client front.swift
    if [ $? -ne 0 ]; then
        echo "Compilation failed. Exiting."
        exit 1
    fi
else
    echo "Using existing compiled client."
fi

# Start the Flask server in the background
uv run app.py &

# Store the PID of the Flask server
FLASK_PID=$!

# Wait a bit for the server to start up
sleep 5

# Start the compiled Swift client
./asr_client

# When the Swift client exits, also stop the Flask server
kill $FLASK_PID