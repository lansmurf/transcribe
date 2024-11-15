import Cocoa
import AVFoundation

class AudioRecorder {
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording.wav")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            print("Started recording")
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecordingAndTranscribe() {
        audioRecorder?.stop()
        isRecording = false
        print("Stopped recording")
        
        guard let audioFileURL = audioRecorder?.url else {
            print("No audio file URL")
            return
        }
        
        sendAudioForTranscription(audioFileURL: audioFileURL) { result in
            if let text = result {
                print("Transcribed text: \(text)")
                self.pasteText(text)
            } else {
                print("Transcription failed")
            }
        }
    }
    
    func sendAudioForTranscription(audioFileURL: URL, completion: @escaping (String?) -> Void) {
        let url = URL(string: "http://localhost:5000/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        data.append(try! Data(contentsOf: audioFileURL))
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let text = json["text"] as? String {
                    completion(text)
                } else {
                    print("Invalid response format")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func pasteText(_ text: String) {
        DispatchQueue.main.async {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            
            let source = CGEventSource(stateID: .hidSystemState)
            
            let pasteCommandDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let pasteCommandUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            
            pasteCommandDown?.flags = .maskCommand
            pasteCommandUp?.flags = .maskCommand
            
            pasteCommandDown?.post(tap: .cgAnnotatedSessionEventTap)
            pasteCommandUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}

var recorder = AudioRecorder()

func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .flagsChanged {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if keyCode == 63 {  // Fn key
            let flags = event.flags
            let isFnPressed = flags.contains(.maskSecondaryFn)
            
            if isFnPressed && !recorder.isRecording {
                recorder.startRecording()
            } else if !isFnPressed && recorder.isRecording {
                recorder.stopRecordingAndTranscribe()
            }
        }
    }
    return Unmanaged.passRetained(event)
}

let eventMask = (1 << CGEventType.flagsChanged.rawValue)
guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                       place: .headInsertEventTap,
                                       options: .defaultTap,
                                       eventsOfInterest: CGEventMask(eventMask),
                                       callback: eventTapCallback,
                                       userInfo: nil) else {
    print("Failed to create event tap")
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

print("Listening for Fn key press. Press and hold to record, release to transcribe. Press Ctrl+C to exit.")
CFRunLoopRun()