var exec = require('cordova/exec');

var IoniCordovaRTMPandHLS = {};

IoniCordovaRTMPandHLS.coolMethod = function (arg0, success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'coolMethod', [arg0]);
};

IoniCordovaRTMPandHLS.previewCamera = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'previewCamera', []);
};

IoniCordovaRTMPandHLS.swapCamera = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'swapCamera', []);
};

IoniCordovaRTMPandHLS.startBroadcasting = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'startBroadcasting', []);
};

IoniCordovaRTMPandHLS.stopBroadcasting = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'stopBroadcasting', []);
};

IoniCordovaRTMPandHLS.viewLiveStream = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'viewLiveStream', []);
};

IoniCordovaRTMPandHLS.requestPermissions = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'requestPermissions', []);
};

module.exports = IoniCordovaRTMPandHLS;