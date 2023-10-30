/********* IoniCordovaRTMPandHLS.swift Cordova Plugin Implementation *******/
import Foundation
import HaishinKit
import AVFoundation
import Logboard

@objc(IoniCordovaRTMPandHLS) class IoniCordovaRTMPandHLS: CDVPlugin {
    var connection: RTMPConnection?
    var stream: RTMPStream?
    var isFrontCamera: Bool = true
    var hkView: PiPHKView?
    
    @objc(coolMethod:)
    func coolMethod(command: CDVInvokedUrlCommand) {
        // ...
    }

    @objc(previewCamera:)
    func previewCamera(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            LBLogger.with(HaishinKitIdentifier).level = .trace
            
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


            let connection = RTMPConnection()
            self.stream = RTMPStream(connection: connection)
            //
            self.stream?.sessionPreset = AVCaptureSession.Preset.low; // Changed from .low to .medium

            self.stream?.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
                print("Error attaching audio: (error)")
            }

            self.stream?.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: (self.isFrontCamera ? .front : .back))) { error in
                print("Error attaching camera: (error)")
            }

            //let hkView = MTHKView(frame: self.webView.bounds)
            self.webView.isOpaque = false
            self.webView.backgroundColor = UIColor.clear
            self.viewController.view.backgroundColor = UIColor.clear
            
            self.hkView = PiPHKView(frame: self.webView.bounds)
            self.hkView?.layer.zPosition = 0;
            self.webView.layer.zPosition = 1;
            self.hkView?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.hkView?.attachStream(self.stream)
           
            // key 9e4d8f66-5f60-8155-db2e-e4c61411211f
            // id 1OPcGxKzghlhIrmSmLFqNylx2Zy202bbq02JUaGhx9vY4
            
            // Add ViewController#view
            self.viewController.view.insertSubview(self.hkView!, belowSubview: self.webView)
            
            

            // Uncomment the following lines if you want to test the RTMP connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 1460.0) {
                connection.connect("rtmp://global-live.mux.com:5222/app/1OPcGxKzghlhIrmSmLFqNylx2Zy202bbq02JUaGhx9vY4/9e4d8f66-5f60-8155-db2e-e4c61411211f")
                self.stream?.publish("TestIOS")
                self.stream?.startRecording()

                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "previewCamera Executed!")
                self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
            }
         
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
            DispatchQueue.main.async {
                /*
                guard self.stream != nil else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Stream not initialized.")
                    self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                    return
                }*/

                // Toggle the camera position
                self.isFrontCamera.toggle()
                
                let newCameraPosition: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back
                print("newCameraPosition " , newCameraPosition.rawValue)
                // Get the new camera device
                guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition) else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to get camera.")
                    self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                    return
                }

                // Attach the new camera to the stream
                print("newCamera " , newCamera)
                print(" self.stream " ,  self.stream)
  
                 self.stream?.attachCamera(newCamera) { error in
                    // Handle error if needed
                     print("attachCamera error " , error)
                }
                /*
                self.hkView?.attachStream(self.stream)
                */
                // Return success
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera swapped successfully.")
                self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
        }
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
