//
//  ScanView.swift
//  Pocket Trainer 3
//
//  Created by Bashir Adeniran on 3/28/25.

import SwiftUI
import ARKit
// import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// MARK: - ChatGPT Vision Helpers

func callChatGPTVision(with image: UIImage, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        completion(.failure(NSError(domain: "ImageEncoding", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode image"])))
        return
    }
    let base64Image = imageData.base64EncodedString()
    guard let url = URL(string: "https://api.openai.com/v1/images/vision") else {
        completion(.failure(NSError(domain: "URLCreation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(Secrets.chatGPTAPIKey)", forHTTPHeaderField: "Authorization")

    let payload: [String: Any] = [
        "model": "vision-001",
        "image": ["base64": base64Image],
        "features": [
            ["type": "FACE_DETECTION", "max_results": 10],
            ["type": "OBJECT_DETECTION", "max_results": 10]
        ]
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        completion(.failure(error))
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data,
              let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            completion(.failure(NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No or invalid data"])))
            return
        }
        completion(.success(jsonResponse))
    }.resume()
}

func extractMeasurements(from visionResponse: [String: Any]) -> String {
    // Adapted to use OpenAI Vision response format
    if let faces = visionResponse["face_annotations"] as? [[String: Any]], !faces.isEmpty {
        return "Faces detected: \(faces.count)"
    } else if let objects = visionResponse["object_annotations"] as? [[String: Any]], !objects.isEmpty {
        let measurements = objects.compactMap { obj -> String? in
            if let name = obj["name"] as? String, let score = obj["confidence"] as? Double {
                return "\(name): \(Int(score * 100))% confidence"
            }
            return nil
        }
        return measurements.joined(separator: ", ")
    } else {
        return "No measurements extracted"
    }
}


// MARK: - ChatGPT API Call

// Updated callChatGPT function now takes a googleFindings parameter and a prompt override.
func callChatGPT(with photoURLs: [String], googleFindings: String, promptOverride: String? = nil, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion(nil)
        return
    }
    
    // Use promptOverride if provided; otherwise build a default prompt.
    let prompt: String
    if let override = promptOverride {
        prompt = override
    } else {
        prompt = #"""
        Based on the following findings from the Google Cloud Vision API: \(googleFindings)
        Please generate a JSON object with the following keys: "picture", "height", "weight", "bodyFat", "chest", "waist", "bicep", "neck", "leg", "calf", and "workoutRoutine". Each measurement should be a single number with a single decimal if needed (no ranges) in inches (except weight in lbs and bodyFat as a percentage). If there is no person detected in any one of the images or the images are not valid (i.e. all four images are not present), return a JSON object with a key "error" whose value is "retake photos".
        """#
    }
    
    let parameters: [String: Any] = [
        "model": "gpt-4o-mini",
        "messages": [
            ["role": "system", "content": "You are a fitness expert and personal trainer."],
            ["role": "user", "content": prompt]
        ]
    ]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(Secrets.chatGPTAPIKey)", forHTTPHeaderField: "Authorization")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
    } catch {
        print("Error serializing JSON: \(error.localizedDescription)")
        completion(nil)
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error calling ChatGPT: \(error.localizedDescription)")
            completion(nil)
            return
        }
        guard let data = data else {
            print("No data received from ChatGPT")
            completion(nil)
            return
        }
        
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("Raw ChatGPT response: \(rawResponse)")
        }
        
        if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let errorMessage = responseJSON["error"] as? String, errorMessage == "retake photos" {
                completion("error: retake photos")
                return
            }
            if let choices = responseJSON["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                if let jsonData = content.data(using: .utf8),
                   let _ = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    completion(content)
                    return
                } else {
                    completion("error: retake photos")
                    return
                }
            } else {
                print("Error parsing ChatGPT response")
                completion(nil)
                return
            }
        } else {
            print("Error converting response to JSON")
            completion(nil)
            return
        }
    }.resume()
}
 
func processCapturedImage(_ images: [UIImage], completion: @escaping (String?) -> Void) {
    print("[ChatGPT] Sending images directly to GPT for analysis.")
    
    let base64Strings = images.compactMap { image in
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        return data.base64EncodedString()
    }
    guard base64Strings.count == images.count else {
        completion("error: image encoding failed")
        return
    }
    
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion("error: invalid URL")
        return
    }
    
    var userContentArray: [[String: Any]] = [
        ["type": "text", "text": """
        These are 4 images of a person. Estimate their body fat percentage and generate a JSON with these keys: "picture", "height", "weight", "bodyFat", "chest", "waist", "bicep", "neck", "leg", "calf", and "workoutRoutine". Each measurement should be a number (one decimal if needed) in inches, weight in lbs, and bodyFat as a percent. If the images are missing or not usable, return: { "error": "retake photos" }
        """]
    ]
    for str in base64Strings {
        userContentArray.append([
            "type": "image_url",
            "image_url": ["url": "data:image/jpeg;base64,\(str)"]
        ])
    }
    
    let messages: [[String: Any]] = [
        ["role": "system", "content": "You are a fitness expert and personal trainer."],
        ["role": "user", "content": userContentArray]
    ]
    
    let payload: [String: Any] = [
        "model": "gpt-4o",
        "messages": messages,
        "max_tokens": 1000
    ]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(Secrets.chatGPTAPIKey)", forHTTPHeaderField: "Authorization")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    } catch {
        print("Error encoding request payload: \(error)")
        completion("error: payload serialization failed")
        return
    }
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending to ChatGPT: \(error)")
            completion("error: retake photos")
            return
        }
        guard let data = data else {
            completion("error: retake photos")
            return
        }
        if let raw = String(data: data, encoding: .utf8) {
            print("Raw ChatGPT response: \(raw)")
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let msg = choices.first?["message"] as? [String: Any],
           let content = msg["content"] as? String {
            // Remove markdown code fences
            var cleaned = content
            // Strip leading ```json if present
            if cleaned.hasPrefix("```json") {
                if let range = cleaned.range(of: "```json") {
                    cleaned.removeSubrange(range)
                }
            }
            // Remove any backticks
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(cleaned)
        } else {
            completion("error: retake photos")
        }
    }.resume()
}

// MARK: - Firestore Storage

func storeChatGPTResponse(_ response: String) {
    guard let user = Auth.auth().currentUser else {
        print("User not authenticated")
        return
    }
    
    guard let jsonData = response.data(using: .utf8),
          let parsedResponse = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
        print("Failed to parse response into JSON")
        return
    }
    
    let db = Firestore.firestore()
    var data = parsedResponse
    data["timestamp"] = FieldValue.serverTimestamp()
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateKey = formatter.string(from: Date())
    
    db.collection("users").document(user.uid).collection("progress").document(dateKey).setData(data, merge: true) { error in
        if let error = error {
            print("Error storing ChatGPT response: \(error.localizedDescription)")
        } else {
            print("ChatGPT response stored successfully.")
        }
    }
}

// MARK: - Dummy Image Helper

func createDummyImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
    return renderer.image { ctx in
        UIColor.gray.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40),
            .foregroundColor: UIColor.white
        ]
        let text = "Photo"
        let textSize = text.size(withAttributes: attributes)
        let rect = CGRect(x: (300 - textSize.width) / 2, y: (300 - textSize.height) / 2, width: textSize.width, height: textSize.height)
        text.draw(in: rect, withAttributes: attributes)
    }
}

// MARK: - ARScanView

struct ARScanView: UIViewRepresentable {
    let session: ARSession
    var useFrontCamera: Bool = false
    
    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        // Add a highlight overlay view to simulate portrait mode subject highlighting
        let highlightView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        highlightView.center = sceneView.center
        highlightView.layer.borderColor = UIColor.yellow.cgColor
        highlightView.layer.borderWidth = 2
        highlightView.backgroundColor = UIColor.clear
        highlightView.isHidden = true
        sceneView.addSubview(highlightView)
        context.coordinator.highlightView = highlightView
        
        sceneView.session = session
        sceneView.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(ARScanView.Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Ensure the highlight overlay remains centered
        if let highlight = context.coordinator.highlightView {
            highlight.center = CGPoint(x: uiView.bounds.midX, y: uiView.bounds.midY)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARScanView
        var highlightView: UIView?
        
        init(_ parent: ARScanView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? ARSCNView else { return }
            let location = gesture.location(in: sceneView)
            // Create and show a focus indicator at the tap location
            let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
            focusView.center = location
            focusView.layer.borderColor = UIColor.yellow.cgColor
            focusView.layer.borderWidth = 2
            focusView.backgroundColor = UIColor.clear
            sceneView.addSubview(focusView)
            UIView.animate(withDuration: 1.0, animations: {
                focusView.alpha = 0
            }) { _ in
                focusView.removeFromSuperview()
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARBodyAnchor || anchor is ARFaceAnchor {
                print("Human detected. Showing subject highlight overlay.")
                DispatchQueue.main.async {
                    self.highlightView?.isHidden = false
                }
            }
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARBodyAnchor || anchor is ARFaceAnchor {
                print("Subject lost. Hiding highlight overlay.")
                DispatchQueue.main.async {
                    self.highlightView?.isHidden = true
                }
            }
        }
    }
}

// MARK: - ScanView

struct ScanView: View {
    @State private var arSession = ARSession()
    @State private var capturedImages: [UIImage] = []         // Local storage until 4 photos.
    @State private var capturedAngles: [String] = []            // Local storage for angles.
    @Environment(\.dismiss) var dismiss
    
    // Timer state: 0, 3, or 10 seconds.
    @State private var timerOption: Int = 0
    let timerOptions = [0, 3, 10]
    
    // Directions for capturing photos.
    let directions = ["Front", "Back", "Left", "Right"]
    
    // States for uploading, countdown, navigation, and zoomed preview.
    @State private var isUploading: Bool = false
    @State private var chatGPTOutput: String? = nil
    @State private var navigateToMain: Bool = false
    @State private var countdown: Int = 0
    
    // State for switching cameras.
    @State private var useFrontCamera: Bool = false
    
    // State for showing the ChatGPT response popup.
    @State private var showChatPopup: Bool = false
    
    // State to show error alert when GPT returns an error.
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // ARKit camera preview.
                ARScanView(session: arSession, useFrontCamera: useFrontCamera)
                    .ignoresSafeArea()
                
                // Countdown overlay.
                if countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                }
                
                // Bottom right preview overlay showing the last captured photo.
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if let lastImage = capturedImages.last {
                            Image(uiImage: lastImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 1))
                                .padding(2)
                        }
                    }
                }
                
                // Overlay showing captured photo count and current angle.
                VStack {
                    Spacer()
                    if !capturedImages.isEmpty {
                        VStack {
                            Text("Captured \(capturedImages.count)/4 photos")
                                .foregroundColor(.white)
                            if capturedImages.count < directions.count {
                                Text(directions[capturedImages.count])
                                    .foregroundColor(.white)
                                    .font(.headline)
                            } else {
                                Text("All angles captured")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        }
                        .padding(.bottom, 140)
                    }
                }
                
                // Top overlay: Cancel and camera switch buttons.
                VStack {
                    HStack {
                        Button(action: {
                            capturedImages = []
                            capturedAngles = []
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Cancel")
                                    .font(.system(size: 20, weight: .regular))
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            useFrontCamera.toggle()
                            reconfigureSession()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                
                // Bottom controls: Timer picker and shutter button.
                VStack {
                    Spacer()
                    VStack {
                        Picker("Timer", selection: $timerOption) {
                            ForEach(timerOptions, id: \.self) { seconds in
                                Text("\(seconds)s")
                                    .tag(seconds)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        .padding(.bottom, 20)
                        
                        Button(action: {
                            takePictureWithTimer()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 100, height: 100)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Loading overlay.
                if isUploading {
                    LoadingView()
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showChatPopup) {
                Alert(
                    title: Text("Workout Plan"),
                    message: Text(chatGPTOutput ?? "No response"),
                    dismissButton: .default(Text("OK"), action: {
                        // After dismissing the popup, navigate to mainView
                        navigateToMain = true
                    })
                )
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text("Retake Photos"), dismissButton: .default(Text("OK"), action: {
                    capturedImages = []
                    capturedAngles = []
                    navigateToMain = true
                }))
            }
            .onAppear {
                startARSession()
            }
            .onDisappear {
                arSession.pause()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AutoCapturePhoto"))) { _ in
                if capturedImages.count < 4 {
                    takePictureWithTimer()
                }
            }
            // NavigationLink to mainView (HomeView)
            NavigationLink(
                destination: mainView().navigationBarBackButtonHidden(true),
                isActive: $navigateToMain
            ) {
                EmptyView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Reconfigure AR session.
    func reconfigureSession() {
        arSession.pause()
        startARSession()
    }
    
    // Capture photo with delay.
    func takePictureWithTimer() {
        print("Timer set to \(timerOption) seconds. Starting capture after delay...")
        if timerOption > 0 {
            countdown = timerOption
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if countdown > 0 {
                    countdown -= 1
                }
                if countdown == 0 {
                    timer.invalidate()
                    capturePhoto()
                }
            }
        } else {
            capturePhoto()
        }
    }
    
    // Capture a photo and update local storage.
    func capturePhoto() {
        // Capture a snapshot from the current AR frame
        let imageToAppend: UIImage
        if let frame = arSession.currentFrame {
            let pixelBuffer = frame.capturedImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                imageToAppend = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            } else {
                imageToAppend = createDummyImage()
            }
        } else {
            imageToAppend = createDummyImage()
        }
        capturedImages.append(imageToAppend)
        if capturedImages.count <= directions.count {
            capturedAngles.append(directions[capturedImages.count - 1].lowercased())
        }
        print("Captured photo \(capturedImages.count)")

        if capturedImages.count == 4 {
            isUploading = true
            // Call ChatGPT Vision on the last captured image’s front view (example: first image)
            let firstImage = capturedImages[0]
            callChatGPTVision(with: firstImage) { result in
                DispatchQueue.main.async {
                    isUploading = false
                    switch result {
                    case .success(let visionData):
                        let measurements = extractMeasurements(from: visionData)
                        // Now pass measurements to ChatGPT for workout (reuse callChatGPT)
                        callChatGPT(with: [], googleFindings: measurements) { response in
                            DispatchQueue.main.async {
                                if let output = response, !output.starts(with: "error") {
                                    chatGPTOutput = output
                                    showChatPopup = true
                                } else {
                                    chatGPTOutput = nil
                                    showErrorAlert = true
                                }
                            }
                        }
                    case .failure(_):
                        chatGPTOutput = nil
                        showErrorAlert = true
                    }
                }
            }
            return
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Ready for next photo.
            }
        }
    }
    
    // Start AR session.
    func startARSession() {
        if useFrontCamera {
            // For front camera, use ARWorldTrackingConfiguration to avoid portrait image errors
            let configuration = ARWorldTrackingConfiguration()
            arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        } else {
            if ARBodyTrackingConfiguration.isSupported {
                let configuration = ARBodyTrackingConfiguration()
                configuration.frameSemantics = .bodyDetection
                arSession.run(configuration)
            } else {
                let configuration = ARWorldTrackingConfiguration()
                configuration.frameSemantics = [.personSegmentation, .personSegmentationWithDepth]
                arSession.run(configuration)
            }
        }
    }
    
    // After 4 photos are taken, upload them to Firebase and process with ChatGPT.
    func uploadPhotos() {
        isUploading = true
        // Upload images to Firebase to get public URLs
        uploadPhotosToFirebase { photoURLs in
            print("Photo URLs: \(photoURLs)")
            guard !photoURLs.isEmpty else {
                DispatchQueue.main.async {
                    isUploading = false
                    chatGPTOutput = "error: retake photos"
                    showErrorAlert = true
                }
                return
            }
            // Build the content array: text prompt + image_url entries
            var userContentArray: [[String: Any]] = [
                ["type": "text", "text": """
                These are 4 images of a person. Estimate their body fat percentage and generate a JSON with these keys: "picture", "height", "weight", "bodyFat", "chest", "waist", "bicep", "neck", "leg", "calf", and "workoutRoutine". Each measurement should be a number (one decimal if needed) in inches, weight in lbs, and bodyFat as a percent. If the images are missing or not usable, return: { "error": "retake photos" }
                """]
            ]
            for urlString in photoURLs {
                userContentArray.append([
                    "type": "image_url",
                    "image_url": ["url": urlString]
                ])
            }
            // Prepare messages
            let messages: [[String: Any]] = [
                ["role": "system", "content": "You are a fitness expert and personal trainer."],
                ["role": "user", "content": userContentArray]
            ]
            // Create payload for ChatGPT
            let payload: [String: Any] = [
                "model": "gpt-4o",
                "messages": messages,
                "max_tokens": 1000
            ]
            // Send to ChatGPT
            guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
                DispatchQueue.main.async {
                    isUploading = false
                    chatGPTOutput = "error: retake photos"
                    showErrorAlert = true
                }
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(Secrets.chatGPTAPIKey)", forHTTPHeaderField: "Authorization")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            } catch {
                DispatchQueue.main.async {
                    isUploading = false
                    chatGPTOutput = "error: retake photos"
                    showErrorAlert = true
                }
                return
            }
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isUploading = false
                }
                if let error = error {
                    print("Error sending to ChatGPT: \(error)")
                    DispatchQueue.main.async {
                        chatGPTOutput = "error: retake photos"
                        showErrorAlert = true
                    }
                    return
                }
                guard let data = data else {
                    DispatchQueue.main.async {
                        chatGPTOutput = "error: retake photos"
                        showErrorAlert = true
                    }
                    return
                }
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw ChatGPT response: \(raw)")
                }
                // Parse and clean response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let msg = choices.first?["message"] as? [String: Any],
                   let content = msg["content"] as? String {
                    var cleaned = content
                    if cleaned.hasPrefix("```json") {
                        if let range = cleaned.range(of: "```json") {
                            cleaned.removeSubrange(range)
                        }
                    }
                    cleaned = cleaned.replacingOccurrences(of: "```", with: "")
                    cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        if cleaned == "{ \"error\": \"retake photos\" }" {
                            chatGPTOutput = "error: retake photos"
                            showErrorAlert = true
                        } else {
                            chatGPTOutput = cleaned
                            showChatPopup = true
                            storeChatGPTResponse(cleaned)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        chatGPTOutput = "error: retake photos"
                        showErrorAlert = true
                    }
                }
            }.resume()
        }
    }
    
    // Upload captured photos to Firebase Storage.
    func uploadPhotosToFirebase(completion: @escaping ([String]) -> Void) {
        let storage = Storage.storage()
        var downloadURLs: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for image in capturedImages {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            let fileName = "\(UUID().uuidString).jpg"
            let storageRef = storage.reference().child("scanPhotos/\(fileName)")
            
            dispatchGroup.enter()
            storageRef.putData(imageData, metadata: nil) { (metadata: StorageMetadata?, error: Error?) in
                if let error = error {
                    print("Error uploading photo: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                storageRef.downloadURL { (url: URL?, error: Error?) in
                    if let url = url {
                        downloadURLs.append(url.absoluteString)
                    } else {
                        print("Error retrieving download URL: \(error?.localizedDescription ?? "Unknown error")")
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(downloadURLs)
        }
    }
    
    // Call GPT with a prompt requiring a JSON object with measurements.
    func callChatGPT(with photoURLs: [String], googleFindings: String, promptOverride: String? = nil, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }
        
        let prompt: String
        if let override = promptOverride {
            prompt = override
        } else {
            prompt = #"""
            Based on the following findings from the Google Cloud Vision API: \(googleFindings)
            Please generate a detailed workout plan that includes:
            1. A list of all measurements found.
            2. A personalized workout routine based solely on those measurements.
            Do not analyze the photo itself as it cannot be seen; only use the provided findings.
            """#
        }
        
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a fitness expert and personal trainer."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Secrets.chatGPTAPIKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling ChatGPT: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("No data received from ChatGPT")
                completion(nil)
                return
            }
            
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw ChatGPT response: \(rawResponse)")
            }
            
            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let errorMessage = responseJSON["error"] as? String, errorMessage == "retake photos" {
                    completion("error: retake photos")
                    return
                }
                if let choices = responseJSON["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    if let jsonData = content.data(using: .utf8),
                       let _ = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        completion(content)
                        return
                    } else {
                        completion("error: retake photos")
                        return
                    }
                } else {
                    print("Error parsing ChatGPT response")
                    completion(nil)
                    return
                }
            } else {
                print("Error converting response to JSON")
                completion(nil)
                return
            }
        }.resume()
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}
