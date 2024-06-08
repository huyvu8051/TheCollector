import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var recording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioURL: URL?
    @State private var responseMessage = ""
    @StateObject private var locationManager = LocationManager()
    @State private var timer: Timer?

    let appGroupID = "group.com.huyvu.TheCollector"

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
            .padding()

            if !responseMessage.isEmpty {
                Text(responseMessage)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .onAppear {
            requestMicrophonePermission()
        }
    }

    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("Microphone permission granted")
            } else {
                print("Microphone permission denied")
            }
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

        // Get current time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let currentTime = dateFormatter.string(from: Date())

        // Set the filename with location name and current time
        let audioFilename = documents.appendingPathComponent("\(currentTime)_\(sanitizeLocationName(locationManager.locationName)).m4a")

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
        setupRecorder()
        audioRecorder?.record()
        recording = true
        startTimer()
        updateSharedRecordingStatus(true)
    }

    func stopRecording() {
        stopTimer()
        audioRecorder?.stop()
        recording = false
        if let audioURL = self.audioURL {
            uploadAudioToServer(audioURL: audioURL)
        }
        updateSharedRecordingStatus(false)
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { _ in
            self.chunkAndRestartRecording()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func chunkAndRestartRecording() {
        audioRecorder?.stop()
        if let audioURL = self.audioURL {
            uploadAudioToServer(audioURL: audioURL)
        }
        setupRecorder()  // Set up recorder again without creating a new timer
        audioRecorder?.record()
    }

    func uploadAudioToServer(audioURL: URL) {
        let serverURL = URL(string: "http://10.147.19.11:8069/upload")!
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
                DispatchQueue.main.async {
                    self.responseMessage = "Failed to upload audio: \(error.localizedDescription)"
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.responseMessage = responseString
                    }
                } else {
                    DispatchQueue.main.async {
                        self.responseMessage = "Audio uploaded successfully"
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.responseMessage = "Failed to upload audio. Server returned an error."
                }
            }
        }.resume()
    }

    func updateSharedRecordingStatus(_ isRecording: Bool) {
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.set(isRecording, forKey: "isRecording")
            sharedDefaults.synchronize()
        }
    }

    func sanitizeLocationName(_ locationName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ", ")
        return locationName.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
