/********* IoniCordovaRTMPandHLS.swift Cordova Plugin Implementation *******/
import Foundation
import HaishinKit
import AVFoundation
import Logboard
import Combine
import VideoToolbox
import AmazonIVSPlayer

@objc(IoniCordovaRTMPandHLS) class IoniCordovaRTMPandHLS: CDVPlugin, IVSPlayer.Delegate {
    
    var connection: RTMPConnection!
    var stream: RTMPStream!
    var hkView: MTHKView!
    var avPlayer: IVSPlayer!
    var avPlayerLayer: IVSPlayerLayer!
    var HLSUrl: String = ""
    var RTMPKey: String = ""
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
        
        hkView = MTHKView(frame: webView.bounds)
        hkView.layer.zPosition = 0;
        webView.layer.zPosition = 1;
        hkView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        connection = RTMPConnection()
        connection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self, useCapture:false)
        stream = RTMPStream(connection: connection)
        
        setVideoSettings();
        
        stream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print("Error attaching audio")
        }
        
        stream.attachCamera(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: (isFrontCamera ? .front : .back))) { error in
            print("Error attaching camera")
        }
        
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        viewController.view.backgroundColor = UIColor.clear
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
        
        setVideoSettings();

        stream.attachCamera(newCamera) { error in
            print("Error attaching camera " , error)
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "swapCamera Executed!")
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc(startBroadcasting:)
    func startBroadcasting(command: CDVInvokedUrlCommand) {
        do {
            guard let RTMPSUrl = command.arguments[0] as? String else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid URL")
                commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            guard let _RTMPKey = command.arguments[1] as? String else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid Key")
                commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            guard connection != nil else {
               let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Connection Failed")
               commandDelegate.send(pluginResult, callbackId: command.callbackId)
               return
            }

            RTMPKey = _RTMPKey
            connection.connect(RTMPSUrl)

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "startBroadcasting Executed!")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)

        } catch {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Failed to startBroadcasting")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc(stopBroadcasting:)
    func stopBroadcasting(command: CDVInvokedUrlCommand) {
       DispatchQueue.main.async { [weak self] in
           guard let self = self else { return }
           if let stream = self.stream {
               stream.close()
               self.stream = nil
           }

           if let connection = self.connection {
               connection.close()
               self.connection = nil
           }
            
           let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "stopBroadcasting Executed!")
           self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
       }
    }
    
    @objc(viewLiveStream:)
    func viewLiveStream(command: CDVInvokedUrlCommand) {
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        viewController.view.backgroundColor = UIColor.clear

        guard let streamURLString = command.arguments[0] as? String else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid stream URL")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        if let url = URL(string: streamURLString) {
            
            /*avPlayer = AVPlayer(url: url)
            avPlayerLayer = AVPlayerLayer(player: avPlayer)
            avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            avPlayerLayer.frame = viewController.view.bounds
            avPlayerLayer.zPosition = -1
            viewController.view.layer.addSublayer(avPlayerLayer)
            
            avPlayer.play()
            */

            avPlayer = IVSPlayer()
            avPlayerLayer = IVSPlayerLayer(player: avPlayer)
            avPlayerLayer.videoGravity = .resizeAspectFill
            avPlayerLayer.frame = viewController.view.bounds
            avPlayerLayer.zPosition = -1
            viewController.view.layer.addSublayer(avPlayerLayer)
            avPlayer.addObserver(self, forKeyPath: #keyPath(IVSPlayer.state), options: [.new], context: nil)
            avPlayer.load(url)
            //avPlayer.play()
            

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "viewLiveStream executed")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc(closeLiveStream:)
    func closeLiveStream(command: CDVInvokedUrlCommand) {
        avPlayer.pause()
        avPlayer = nil
        
        avPlayerLayer.removeFromSuperlayer()
        avPlayerLayer = nil

        webView.isOpaque = true
        webView.backgroundColor = UIColor.white
        viewController.view.backgroundColor = UIColor.white

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "closeCameraPreview Executed!")
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

        guard !permissionsToRequest.isEmpty else {
            // Permissions are already denied for both
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permission denied for both permissions")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        var grantedPermissions: [AVMediaType] = []

        // Request permissions sequentially
        for mediaType in permissionsToRequest {
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                if granted {
                    grantedPermissions.append(mediaType)
                }

                if grantedPermissions.count == permissionsToRequest.count {
                    // All requested permissions are granted
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "Permissions granted for \(grantedPermissions)")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                } else if !granted {
                    // At least one permission is denied
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permission denied for \(mediaType)")
                    self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                }
            }
        }
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

    func setVideoSettings() {
        stream.frameRate = 60;
        stream.videoOrientation = .portrait;
        stream.videoSettings.videoSize = .init(width: 1080, height: 1920);
        stream.videoSettings.profileLevel = kVTProfileLevel_H264_High_AutoLevel as String;
        stream.videoSettings.bitRate = 8500 * 1000;
        stream.videoSettings.maxKeyFrameIntervalDuration = 2;
        stream.videoSettings.scalingMode = .trim;
        stream.videoSettings.bitRateMode = .average;
        stream.videoSettings.isHardwareEncoderEnabled = false;
        stream.videoSettings.allowFrameReordering = false;
        stream.audioSettings.bitRate = 96*1000;
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(IVSPlayer.state), let newValue = change?[.newKey] as? IVSPlayer.State {
            if newValue == .ready {
                avPlayer.play()
            }
        }
    }
}
