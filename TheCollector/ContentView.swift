import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var receivedAudioURL: URL?

    var body: some View {
        Text("Waiting for audio...")
            .onAppear {
                setupWatchConnectivity()
            }
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = WatchSessionDelegate.shared
            session.activate()
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

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // Save received audio data to a temporary file and upload to server
        let tempDir = FileManager.default.temporaryDirectory
        let audioURL = tempDir.appendingPathComponent("receivedRecording.m4a")
        do {
            try messageData.write(to: audioURL)
            uploadAudioToServer(audioURL: audioURL)
        } catch {
            print("Error saving received audio data: \(error.localizedDescription)")
        }
    }

    func uploadAudioToServer(audioURL: URL) {
        let serverURL = URL(string: "https://yourserver.com/upload")!
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let filename = audioURL.lastPathComponent
        let mimetype = "audio/m4a"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
        if let audioData = try? Data(contentsOf: audioURL) {
            body.append(audioData)
        }
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("Failed to upload audio: \(error)")
                return
            }
            print("Audio uploaded successfully")
        }.resume()
    }

    // Required methods to conform to WCSessionDelegate
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session inactive state
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivate state
        WCSession.default.activate()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
