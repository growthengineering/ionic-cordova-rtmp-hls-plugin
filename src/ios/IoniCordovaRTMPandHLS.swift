/********* IoniCordovaRTMPandHLS.swift Cordova Plugin Implementation *******/
import Foundation
import HaishinKit
import AVFoundation
import Logboard
import Combine


@objc(IoniCordovaRTMPandHLS) class IoniCordovaRTMPandHLS: CDVPlugin {
    
    var connection: RTMPConnection!
    var stream: RTMPStream!
    var hkView: MTHKView!
    var HLSUrl: String = "";
    var RTMPKey: String = "";
    var isFrontCamera: Bool = true
    
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
            print("Error attaching audio")
        }
        
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: (isFrontCamera ? .front : .back))) { error in
            print("Error attaching camera")
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

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "previewCamera Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(closeCameraPreview:)
    func closeCameraPreview(command: CDVInvokedUrlCommand) {
        stream = nil
        connection = nil
        
         let session = AVAudioSession.sharedInstance()
         do {
             try session.setActive(false)
         } catch {
             print("Error deactivating audio session")
         }


         hkView?.removeFromSuperview()
         hkView = nil

         webView.isOpaque = true
         webView.backgroundColor = UIColor.white
         viewController.view.backgroundColor = UIColor.white

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "closeCameraPreview Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
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
            print("Error attaching camera " , error)
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "swapCamera Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(startBroadcasting:)
    func startBroadcasting(command: CDVInvokedUrlCommand) {
        guard let RTMPSUrl = command.arguments.first as? String else {
              let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid stream URL")
              commandDelegate.send(pluginResult, callbackId: command.callbackId)
              return
        }
        
        guard let _RTMPKey = command.arguments.first as? String else {
              let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid stream URL")
              commandDelegate.send(pluginResult, callbackId: command.callbackId)
              return
        }
        
        RTMPKey = _RTMPKey
        connection.connect(RTMPSUrl)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "startBroadcasting Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(stopBroadcasting:)
    func stopBroadcasting(command: CDVInvokedUrlCommand) {
        stream.close()
        connection.close()
        stream = nil
        connection = nil
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "stopBroadcasting Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(viewLiveStream:)
    func viewLiveStream(command: CDVInvokedUrlCommand) {
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        viewController.view.backgroundColor = UIColor.clear

        guard let streamURLString = command.arguments.first as? String,
            let streamURL = URL(string: streamURLString) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid stream URL")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        if let url = URL(string: streamURL) {
            
            let player = AVPlayer(url: url)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            playerLayer.frame = viewController.view.bounds
            playerLayer.zPosition = -1
            viewController.view.layer.addSublayer(playerLayer)
            
            player.play()
            

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "viewLiveStream executed")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc(closeLiveStream:)
    func closeLiveStream(command: CDVInvokedUrlCommand) {
        // ...
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
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                    return
                }
            }
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "requestPermissions Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }    

    func checkPermissions() -> Bool {
        let cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        return cameraPermission == .authorized && audioPermission == .authorized
    } 
    
    @objc private func rtmpStatusHandler(notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        print(code)
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            stream.publish(RTMPKey)
            
        case RTMPConnection.Code.connectFailed.rawValue, RTMPConnection.Code.connectClosed.rawValue:
            return
            
        default:
            break
        }
    }
}
