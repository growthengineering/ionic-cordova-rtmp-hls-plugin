/********* IoniCordovaRTMPandHLS.swift Cordova Plugin Implementation *******/
import Foundation
import HaishinKit
import AVFoundation

@objc(IoniCordovaRTMPandHLS) class IoniCordovaRTMPandHLS: CDVPlugin {
    var connection: RTMPConnection?
    var stream: RTMPStream?

    @objc(coolMethod:)
    func coolMethod(command: CDVInvokedUrlCommand) {
        // ...
    }

    @objc(previewCamera:)
    func previewCamera(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            guard self.checkPermissions() else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permissions not granted.")
                self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                return
            }

            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSession.Category.playAndRecord)
                try session.setMode(AVAudioSession.Mode.videoRecording)
                try session.setActive(true)
            } catch {
                print(error)
            }

            print(AVCaptureDevice.default(for: .audio))
            print(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front))

            let connection = RTMPConnection()
            let stream = RTMPStream(connection: connection)
            stream.sessionPreset = AVCaptureSession.Preset.medium; // Changed from .low to .medium

            stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
                print("Error attaching audio: (error)")
            }

            stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)) { error in
                print("Error attaching camera: (error)")
            }

            let hkView = MTHKView(frame: self.webView.bounds)
            hkView.layer.zPosition = 1;
            hkView.frame = CGRect(x: 0, y: 0, width: self.webView.bounds.width, height: self.webView.bounds.height)
            hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
            hkView.attachStream(stream)
            print(hkView)

            // Add ViewController#view
            self.webView.addSubview(hkView)

            // Uncomment the following lines if you want to test the RTMP connection
            // connection.connect("rtmp://localhost/appName/instanceName")
            // stream.publish("streamName")

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "previewCamera Executed!")
            self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
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
            /*
            DispatchQueue.main.async {
                guard self.stream != nil else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Stream not initialized.")
                    self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                    return
                }

                // Toggle the camera position
                self.isFrontCamera.toggle()
                let newCameraPosition: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back

                // Get the new camera device
                guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition) else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to get camera.")
                    self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                    return
                }

                // Attach the new camera to the stream
                self.stream?.attachCamera(newCamera) { error in
                    // Handle error if needed
                }

                // Return success
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera swapped successfully.")
                self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
            }
        }*/
    }

    @objc(startBroadcasting:)
    func startBroadcasting(command: CDVInvokedUrlCommand) {
        // ...
    }

    @objc(stopBroadcasting:)
    func stopBroadcasting(command: CDVInvokedUrlCommand) {
        // ...
    }

    @objc(viewLiveStream:)
    func viewLiveStream(command: CDVInvokedUrlCommand) {
        // ...
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
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
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
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }
        }

        // Return success if permissions were granted or if they were already granted
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Permissions granted")
        self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        
    }
}
