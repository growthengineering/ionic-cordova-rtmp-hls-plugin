var exec = require('cordova/exec');

exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'coolMethod', [arg0]);
};

exports.previewCamera = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'previewCamera', []);
};

exports.swapCamera = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'swapCamera', []);
};

exports.startBroadcasting = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'startBroadcasting', []);
};

exports.stopBroadcasting = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'stopBroadcasting', []);
};

exports.viewLiveStream = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'viewLiveStream', []);
};

exports.requestPermissions = function (success, error) {
    exec(success, error, 'IoniCordovaRTMPandHLS', 'requestPermissions', []);
};


