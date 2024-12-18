/********* IoniCordovaRTMPandHLS.swift Cordova Plugin Implementation *******/
import Foundation
import HaishinKit
import AVFoundation
import Logboard
import Combine
import VideoToolbox
import AmazonIVSPlayer
import AmazonIVSBroadcast

@objc(IoniCordovaRTMPandHLS) class IoniCordovaRTMPandHLS: CDVPlugin, IVSPlayer.Delegate, IVSBroadcastSession.Delegate  {
    @objc(broadcastSession:didChangeState:) func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
        
    }
    
    @objc func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
        
    }
    
    
    var connection: RTMPConnection!
    var stream: RTMPStream!
    var hkView: IVSImagePreviewView!
    var avPlayer: IVSPlayer!
    var avPlayerLayer: IVSPlayerLayer!
    var HLSUrl: String = ""
    var RTMPKey: String = ""
    var isFrontCamera: Bool = true
    var broadcastSession: IVSBroadcastSession!
    var currentCamera: IVSImageDevice!
    var ivsVideoConfig: IVSBroadcastConfiguration!
    var eventsCallbackCommand: CDVInvokedUrlCommand!
    var eventsCallbackCommand2: CDVInvokedUrlCommand!
    var volumeObserver: NSKeyValueObservation?
    
    @objc(previewCamera:)
    func previewCamera(command: CDVInvokedUrlCommand) {
        guard hasPermissions(command: nil) else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Permissions not granted.")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
        }
        
       
        createBroadcastSession { result in
            switch result {
            case .success:
                self.webView.layer.zPosition = 1;
                self.webView.isOpaque = false
                self.webView.backgroundColor = UIColor.clear
                self.viewController.view.backgroundColor = UIColor.clear
                
                
                self.broadcastSession.awaitDeviceChanges {
                    do {
                        if let devicePreview = try self.broadcastSession.listAttachedDevices()
                           .compactMap({ $0 as? IVSImageDevice })
                           .first {
                            self.currentCamera = devicePreview;
                            var newView: IVSImagePreviewView = try devicePreview.previewView()
                            
             
                            newView.frame = self.webView.frame
                            newView.bounds = self.webView.bounds
                            newView.layer.zPosition = 0
                            self.hkView = newView
                            self.hkView.backgroundColor  = UIColor.clear
                            self.viewController.view.insertSubview(self.hkView , belowSubview: self.webView)

                        }
                    } catch {
                    }
                 }
                
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "previewCamera Executed!")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)

                
            case .failure(let error):
                print("Error initializing broadcast session:", error)
            }
        }
       

      
    }
    
    @objc(closeCameraPreview:)
    func closeCameraPreview(command: CDVInvokedUrlCommand) {
         let session = AVAudioSession.sharedInstance()
         do {
             try session.setActive(false)
         } catch {
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
   
        let wants: IVSDevicePosition = (currentCamera.descriptor().position == .front) ? .back : .front
        hkView?.removeFromSuperview()
        hkView = nil
        
        let foundCamera = IVSBroadcastSession
                .listAvailableDevices()
                .first { $0.type == .camera && $0.position == wants }
        
        guard let newCamera = foundCamera else { return }
        
        broadcastSession.exchangeOldDevice(currentCamera, withNewDevice: newCamera) { newDevice, _ in
            self.currentCamera = newDevice as! IVSImageDevice
            if let camera = newDevice as? IVSImageDevice {
                do {
                    var newView: IVSImagePreviewView = try camera.previewView()
                    newView.frame = self.webView.frame
                    newView.bounds = self.webView.bounds
                    newView.layer.zPosition = 0
                    self.hkView = newView
                    self.hkView.backgroundColor  = UIColor.clear
                     
                    try self.viewController.view.insertSubview(self.hkView, belowSubview: self.webView)
                } catch {
                }
            }
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
            
            guard let RTMPSUrl = URL(string: RTMPSUrl) else {
                    return
                }
            
            guard let _RTMPKey = command.arguments[1] as? String else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid Key")
                commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }

            RTMPKey = _RTMPKey
            try broadcastSession.start(with: RTMPSUrl, streamKey: _RTMPKey)

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
            hkView?.removeFromSuperview()
            hkView = nil
            broadcastSession.stop()
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
            
            let audioSession = AVAudioSession.sharedInstance()
            volumeObserver = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] (session, change) in
                guard let newVolume = change.newValue else { return }
 
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                } catch {}
            }
        
            HLSUrl = streamURLString
            setupLivestream()
            avPlayer.load(url)
            avPlayer.play()

            UIApplication.shared.isIdleTimerDisabled = true

            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "viewLiveStream executed")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    @objc(closeLiveStream:)
    func closeLiveStream(command: CDVInvokedUrlCommand) {
        if let _player = avPlayer {
            _player.pause()
        }
        avPlayer = nil
        
        if let _playerLayer = avPlayerLayer {
            _playerLayer.removeFromSuperlayer()
        }
        avPlayerLayer = nil

        webView.isOpaque = true
        webView.backgroundColor = UIColor.white
        viewController.view.backgroundColor = UIColor.white
        
        UIApplication.shared.isIdleTimerDisabled = false
        
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

    @objc(hasPermissions:)
    func hasPermissions(command: CDVInvokedUrlCommand?) -> Bool {
        let cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        let audioPermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let _hasPermissions = cameraPermission == .authorized && audioPermission == .authorized
        
        if(command == nil) {
            return _hasPermissions
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: _hasPermissions)
            commandDelegate.send(pluginResult, callbackId: command?.callbackId)
            return _hasPermissions
        }
    }
    
    @objc private func rtmpStatusHandler(notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }

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
        do {
            ivsVideoConfig = IVSBroadcastConfiguration()
            try ivsVideoConfig.audio.setBitrate(128_000)
            try ivsVideoConfig.video.setMaxBitrate(8_000_000)
            try ivsVideoConfig.video.setMinBitrate(2_500_000)
            try ivsVideoConfig.video.setInitialBitrate(5_000_000)
            try ivsVideoConfig.video.setSize(CGSize(width: 1080, height: 1920))
            try ivsVideoConfig.video.setKeyframeInterval(1)
            try ivsVideoConfig.video.setTargetFramerate(30)
            
        } catch { }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)  {
        if keyPath == #keyPath(IVSPlayer.state) {
            // Now we safely have access to the player's state
            if( avPlayer == nil) {
                return
            }
            switch avPlayer.state {
                case .ready:
                        avPlayer.play()
                        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "{\"connected\": true}")
                        commandDelegate.send(pluginResult, callbackId: eventsCallbackCommand.callbackId)
                    break
                case .ended:
                        let pluginResult2 = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "{\"connected\": false}")
                        commandDelegate.send(pluginResult2, callbackId: eventsCallbackCommand2.callbackId)
                    break
                case .playing:
                    print("IVSPlayer state is playing")
                default:
                    break
            }
        }
        
        if keyPath == #keyPath(IVSPlayer.error)  {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.setupLivestream()
            }
        }
    }
    
    func createBroadcastSession(completion: @escaping (Result<Void, Error>) -> Void) {

        do {
                setVideoSettings()
                broadcastSession = try IVSBroadcastSession(
                    configuration: ivsVideoConfig,
                       descriptors: IVSPresets.devices().backCamera(),
                       delegate: self)
                    completion(.success(()))
           } catch {
                completion(.failure((error)))
           }
    }
    
    func setupLivestream() {
        avPlayer = IVSPlayer()
        avPlayerLayer = IVSPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = .resizeAspectFill
        avPlayerLayer.frame = viewController.view.bounds
        avPlayerLayer.zPosition = -1
        viewController.view.layer.addSublayer(avPlayerLayer)
        avPlayer.addObserver(self, forKeyPath: #keyPath(IVSPlayer.state), options: [.new], context: nil)
        avPlayer.addObserver(self, forKeyPath: #keyPath(IVSPlayer.error), options: [.new], context: nil)
        avPlayer.load(URL(string:HLSUrl))
    }
    
    @objc(onConnectionChange:)
    func onConnectionChange(command: CDVInvokedUrlCommand) {
        eventsCallbackCommand = command;
    }
    
    @objc(offConnectionChange:)
    func offConnectionChange(command: CDVInvokedUrlCommand) {
        //eventsCallbackCommand = nil;
        //eventsCallbackCommand2 = nil;
    }
    @objc(addConnectiontListenerOffline:)
    func addConnectiontListenerOffline(command: CDVInvokedUrlCommand) {
        eventsCallbackCommand2 = command;
    }
}
