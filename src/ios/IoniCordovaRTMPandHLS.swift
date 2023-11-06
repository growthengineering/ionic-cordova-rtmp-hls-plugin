/********* IoniCordovaRTMPandHLS.swift Cordova Plugin Implementation *******/
import Foundation
import HaishinKit
import AVFoundation
import Logboard
import Combine


@objc(IoniCordovaRTMPandHLS) class IoniCordovaRTMPandHLS: CDVPlugin {
    
    var connection: RTMPConnection!
    var stream: RTMPStream!
    var isFrontCamera: Bool = true
    //var hkView: PiPHKView!
    var hkView: MTHKView!
    
    var fps: String = "FPS"
    var published = false
    

    @objc(coolMethod:)
    func coolMethod(command: CDVInvokedUrlCommand) {
        // ...
    }
    
    @objc(previewCamera:)
    func previewCamera(command: CDVInvokedUrlCommand) {
        //LBLogger.with(HaishinKitIdentifier).level = .trace
        //   DispatchQueue.main.async { [ in
        // LBLogger.with(HaishinKitIdentifier).level = .trace
        
        guard checkPermissions() else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permissions not granted.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        /* let session = AVAudioSession.sharedInstance()
         do {
         try session.setCategory(AVAudioSession.Category.playAndRecord)
         try session.setMode(AVAudioSession.Mode.videoRecording)
         try session.setActive(true)
         } catch {
         print(error)
         }*/
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print(error)
        }
        
        
        connection = RTMPConnection()
        connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self, useCapture:false)
        stream = RTMPStream(connection: connection)
        //stream.videoOrientation = .portrait
        //stream.sessionPreset = .low
        //stream.frameRate = 30
        //stream.videoCapture(for: 0).isVideoMirrored = false
        //stream.videoCapture(for: 0).preferredVideoStabilizationMode = .auto
        //stream.videoSettings.videoSize = .init(width: 720, height: 1280)
        //stream.mixer.recorder.delegate = self
        //stream.sessionPreset = AVCaptureSession.Preset.low; // Changed from .low to .medium
        
        
        stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print("Error attaching audio: (error)")
        }
        
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: (isFrontCamera ? .front : .back))) { error in
            print("Error attaching camera: (error)")
        }
        
        
        
        //let hkView = MTHKView(frame: webView.bounds)
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        viewController.view.backgroundColor = UIColor.clear
        
        // hkView = PiPHKView(frame: webView.bounds)
        hkView = MTHKView(frame: webView.bounds)
        hkView.layer.zPosition = 0;
        webView.layer.zPosition = 1;
        hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        hkView.attachStream(stream)
        
        // Add ViewController#view
        viewController.view.insertSubview(hkView, belowSubview: webView)
        
        // }
    }
    
    
    @objc(startBroadcasting:)
    func startBroadcasting(command: CDVInvokedUrlCommand) {
        // DispatchQueue.main.async {
        //NotificationCenter.default.addObserver(self, selector: #selector(dummyErrorHandler), name: nil, object: nil)
        
        //LBLogger.with(HaishinKitIdentifier).level = .trace
        
        // Configure the connection and stream
        // Attempt to connect to the server
        // connection.connect("")
        var streamUrl = "";
       
        
        // print("stream ", connection.objectEncoding.rawValue)
        connection.connect(streamUrl)
        //stream.publish(streamName)
        /* DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
           // Thread.sleep(forTimeInterval: 10)
             print("####### streamName" , streamName)
             self.stream.publish(streamName, type:RTMPStream.HowToPublish.live)
         } */
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Broadcast started successfully!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    

    @objc private func rtmpStatusHandler( notification: Notification) {
        print("########## Handler 2 " , notification)
        var streamName = "";
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        print(code)
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            
            print("########## Handler 2  Connected ")
            stream.publish(streamName)
            
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            return
            
        default:
            break
        }
    }
    
    @objc(stopBroadcasting:)
    func stopBroadcasting(command: CDVInvokedUrlCommand) {
        //  DispatchQueue.main.async {
        // LBLogger.with(HaishinKitIdentifier).level = .trace
        stream.close()
        connection.close()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Broadcast stopped successfully!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
        // }
    }

    @objc(viewLiveStream:)
    func viewLiveStream(command: CDVInvokedUrlCommand) {

        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        viewController.view.backgroundColor = UIColor.clear

        let streamUrl = ""
        /*
        guard let streamURLString = command.arguments.first as? String,
            let streamURL = URL(string: streamURLString) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid stream URL")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }*/

        // Initialize AVPlayer with HLS stream URL
        if let url = URL(string: streamUrl) {
            
            let player = AVPlayer(url: url)
            
            // Create a new AVPlayerLayer instance with the player
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            playerLayer.frame = viewController.view.bounds // You might need to adjust this depending on your layout needs
            
            // Set the zPosition to show the playerLayer below the webView
            playerLayer.zPosition = -1
            
            // Add the playerLayer to the view hierarchy
            viewController.view.layer.addSublayer(playerLayer)
            
            // Start playback
            player.play()
            
            // Notify the plugin command delegate that the operation succeeded
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "viewLiveStream executed")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
     
    
    // Function to check permissions
    func checkPermissions() -> Bool {
        let cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        return cameraPermission == .authorized && audioPermission == .authorized
    }
    
    @objc(swapCamera:)
    func swapCamera(command: CDVInvokedUrlCommand) {
        //  DispatchQueue.main.async {
        //LBLogger.with(HaishinKitIdentifier).level = .trace
        
        guard stream != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Stream not initialized.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        // Toggle the camera position
        isFrontCamera.toggle()
        
        let newCameraPosition: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        print("newCameraPosition " , newCameraPosition.rawValue)
        // Get the new camera device
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to get camera.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        
        stream.attachCamera(newCamera) { error in
            // Handle error if needed
            print("attachCamera error " , error)
        }
        
        
        // Return success
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera swapped successfully.")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
        // }
    }
    
    @objc(requestPermissions:)
    func requestPermissions(command: CDVInvokedUrlCommand) {
        // Check for camera permission
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        // Check for microphone permission
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        // If both permissions are granted, return success
        if cameraStatus == .authorized && microphoneStatus == .authorized {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Permissions granted")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        // If not, request the necessary permissions
        var permissionsToRequest: [AVMediaType] = []
        if cameraStatus == .notDetermined {
            permissionsToRequest.append(AVMediaType.video)
        }
        if microphoneStatus == .notDetermined {
            permissionsToRequest.append(AVMediaType.audio)
        }
        
        for mediaType in permissionsToRequest {
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                if !granted {
                    // If any permission is denied, return failure
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permission denied")
                    //commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }
        }
        
        // Return success if permissions were granted or if they were already granted
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Permissions granted")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
        
    }
    
    
    
}
