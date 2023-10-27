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

    @objc(previewCamera:left:top:width:height:)
    func previewCamera(_ command: CDVInvokedUrlCommand, left: Int, top: Int, width: Int, height: Int) {
        DispatchQueue.main.async {
            guard let context = self.viewController?.view else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to get context.")
                self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            
            let connection = RTMPConnection()
            let stream = RTMPStream(connection: connection)

            stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
                // print(error)
            }

            stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)) { error in
                // print(error)
            }

            let cameraView = MTHKView(frame: self.webView.bounds)
            cameraView.videoGravity = AVLayerVideoGravity.resizeAspectFill
            cameraView.attachStream(stream)

            // add ViewController#view
            //view.addSubview(hkView)

            //connection.connect("rtmp://localhost/appName/instanceName")
            //stream.publish("streamName")
            
            guard let parentView = self.webView?.superview else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to get parent view.")
                self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
          /*  if let frameLayout = parentView as? FrameLayout {
                frameLayout.insertSubview(cameraView, at: 0)  // add cameraView at the bottom
                self.webView?.bringSubviewToFront()  // bring webView to the front
            } else {
                // If the parent view is not a FrameLayout, just add the cameraView directly to the viewController
                self.viewController?.view.addSubview(cameraView)
                cameraView.bringSubviewToFront()
            } */
            self.viewController?.view.addSubview(cameraView)
            
            self.webView?.backgroundColor = .clear
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Camera preview started!")
            self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "previewCamera Executed!")
        self.commandDelegate?.send(pluginResult, callbackId: command.callbackId)
    }

    @objc(swapCamera:)
    func swapCamera(command: CDVInvokedUrlCommand) {
        // ...
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
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print(error)
        }
        
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
