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
    var hkView: MTHKView!
    var HLSUrl: String = "";
    

    @objc(previewCamera:)
    func previewCamera(command: CDVInvokedUrlCommand) {
        guard checkPermissions() else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permissions not granted.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

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

        
        stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print("Error attaching audio: (error)")
        }
        
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: (isFrontCamera ? .front : .back))) { error in
            print("Error attaching camera: (error)")
        }
        
        
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        viewController.view.backgroundColor = UIColor.clear
        hkView = MTHKView(frame: webView.bounds)
        hkView.layer.zPosition = 0;
        webView.layer.zPosition = 1;
        hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        hkView.attachStream(stream)
        viewController.view.insertSubview(hkView, belowSubview: webView)

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "CameraPreview started!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    
    @objc(startBroadcasting:)
    func startBroadcasting(RTMPSUrl, command: CDVInvokedUrlCommand) {
        connection.connect(RTMPSUrl)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Broadcast started successfully!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    

    @objc private func rtmpStatusHandler(notification: Notification) {

        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        print(code)
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:=
            stream.publish("")
            
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            return
            
        default:
            break
        }
    }
    
    @objc(stopBroadcasting:)
    func stopBroadcasting(command: CDVInvokedUrlCommand) {
        stream.close()
        connection.close()
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Broadcast stopped successfully!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(viewLiveStream:)
    func viewLiveStream(command: CDVInvokedUrlCommand) {
        // ...
    }
    
    // Function to check permissions
    func checkPermissions() -> Bool {
        let cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        return cameraPermission == .authorized && audioPermission == .authorized
    }
    
    @objc(swapCamera:)
    func swapCamera(command: CDVInvokedUrlCommand) {
        guard stream != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Stream not initialized.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        isFrontCamera.toggle()
        
        let newCameraPosition: AVCaptureDevice.Position = isFrontCamera ? .front : .back

        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to get camera.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        stream.attachCamera(newCamera) { error in
            print("attachCamera error " , error)
        }
        

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera swapped successfully.")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(requestPermissions:)
    func requestPermissions(command: CDVInvokedUrlCommand) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)

        if cameraStatus == .authorized && microphoneStatus == .authorized {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Permissions granted")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        

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
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permission denied")
                    commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Permissions granted")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    
    
}
