![Ionic Cordova RTMP and HLS Plugin Header Image](https://github.com/growthengineering/ionic-cordova-rtmp-hls-plugin/assets/92361796/4ab394ee-5bda-471e-bc9a-567c8589ff7a)

# Ionic Cordova RTMP and HLS Plugin

This Cordova plugin enables live broadcasting of the camera feed via RTMP and playback via HLS for both iOS and Android platforms within an Ionic Cordova application.

![License](https://img.shields.io/github/license/growthengineering/ionic-cordova-rtmp-hls-plugin)




## 🚀 Sample Project

You can find a sample project demonstrating the usage of this plugin at:
[ionic-cordova-rtmp-hls-sample-project](https://github.com/joaolourencoge/ionic-cordova-rtmp-hls-sample-project)

## 🛣 Roadmap

- [ ] Transition from callbacks to Promises and Observables for a more modern API interface.
- [ ] Ensure the Player and Camera Preview fully match the parent size without including headers and footers.
- [ ] Plan migration from ExoPlayer to Media3 as per Android's latest best practices.
- [ ] Incorporate Unit Testing for improved code reliability and maintenance.

## 📦 Installation

To install the plugin, simply add it to your Ionic project using the following command:

```bash
cordova plugin add https://github.com/growthengineering/ionic-cordova-rtmp-hls-plugin/
```

## 🔗 Dependencies

- **iOS HaishinKit**: `v1.5.6`
- **iOS AVPlayer**: From iOS Core Library (iOS Target SDK)
- **Android HaishinKit**: `v0.10.4`
- **Android ExoPlayer**: `v2.19.1`

## 🛠 Usage

Ensure you have the necessary permissions before attempting to broadcast or view streams:

```javascript
const ionicRtmpHls = (<any>window).cordova.plugin.ionicrtmphls;

ionicRtmpHls.requestPermissions(successCallback, errorCallback);
```

### 🎨 Styling

Include the following styles in your global stylesheet to ensure the player and camera have the correct background when active:

```css
body.show-player,
body.show-camera {
  --ion-background-color: transparent;

  .nav-decor,
  ion-tabs,
  ion-app,
  ion-content {
    --ion-background-color: transparent;
    --background: transparent;
  }
}
```

### 📺 Broadcasting

To preview the camera feed:

```javascript
ionicRtmpHls.previewCamera(CameraOpts, successCallback, errorCallback);
```

To swap the camera:

```javascript
ionicRtmpHls.swapCamera(successCallback, errorCallback);
```

To close the camera preview:

```javascript
ionicRtmpHls.closeCameraPreview(successCallback, errorCallback);
```

To start an RTMP broadcast:

```javascript
ionicRtmpHls.startBroadcasting(RTMPUrl, RTMPKey, successCallback, errorCallback);
```

To stop the broadcast:

```javascript
ionicRtmpHls.stopBroadcasting(successCallback, errorCallback);
```

### 🎬 Playback

To view an HLS stream:

```javascript
ionicRtmpHls.viewLiveStream(HLSUrl, successCallback, errorCallback);
```

To close the stream playback:

```javascript
ionicRtmpHls.closeLiveStream(successCallback, errorCallback);
```

## 📱 Support

This plugin supports:
- Android 7.0 (Nougat) and above
- iOS 12 and above

## 🔒 License

This Cordova plugin is released under the [MIT License](LICENSE).
