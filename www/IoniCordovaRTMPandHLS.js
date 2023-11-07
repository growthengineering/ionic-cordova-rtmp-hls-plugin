var exec = require('cordova/exec');

var IoniCordovaRTMPandHLS = {};

IoniCordovaRTMPandHLS.previewCamera = function (CameraOpts, success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'previewCamera', [CameraOpts]);
};

IoniCordovaRTMPandHLS.swapCamera = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'swapCamera', []);
};

IoniCordovaRTMPandHLS.startBroadcasting = function (RTMPUrl, RTMPKey, success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'startBroadcasting', [RTMPUrl, RTMPKey]);
};

IoniCordovaRTMPandHLS.stopBroadcasting = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'stopBroadcasting', []);
};

IoniCordovaRTMPandHLS.viewLiveStream = function (HLSUrl, success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'viewLiveStream', [HLSUrl]);
};

IoniCordovaRTMPandHLS.requestPermissions = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'requestPermissions', []);
};

module.exports = IoniCordovaRTMPandHLS;