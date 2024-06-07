import SwiftUI
import AVFoundation
import WatchConnectivity

struct ContentView: View {
    @State private var recording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioURL: URL?

    var body: some View {
        VStack {
            Button(action: {
                if self.recording {
                    self.stopRecording()
                } else {
                    self.startRecording()
                }
            }) {
                Text(self.recording ? "Stop Recording" : "Start Recording")
            }
        }
        .onAppear {
            self.setupRecorder()
            self.setupWatchConnectivity()
        }
    }

    func setupRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session")
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documents.appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            self.audioURL = audioFilename
        } catch {
            print("Failed to set up recorder")
        }
    }

    func startRecording() {
        audioRecorder?.record()
        recording = true
    }

    func stopRecording() {
        audioRecorder?.stop()
        recording = false
        if let audioURL = self.audioURL {
            sendAudioToPhone(audioURL: audioURL)
        }
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = WatchSessionDelegate.shared
            session.activate()
        }
    }

    func sendAudioToPhone(audioURL: URL) {
        if WCSession.default.isReachable {
            do {
                let audioData = try Data(contentsOf: audioURL)
                WCSession.default.sendMessageData(audioData, replyHandler: nil, errorHandler: { error in
                    print("Error sending audio data: \(error.localizedDescription)")
                })
            } catch {
                print("Error reading audio file: \(error.localizedDescription)")
            }
        }
    }
}

class WatchSessionDelegate: NSObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation state
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    // Required methods to conform to WCSessionDelegate
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // Handle received message data
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
