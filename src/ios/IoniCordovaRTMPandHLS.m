/********* IoniCordovaRTMPandHLS.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>

@interface IoniCordovaRTMPandHLS : CDVPlugin {
  // Member variables go here.
}

- (void)coolMethod:(CDVInvokedUrlCommand*)command;
- (void)previewCamera:(CDVInvokedUrlCommand*)command;
- (void)swapCamera:(CDVInvokedUrlCommand*)command;
- (void)startBroadcasting:(CDVInvokedUrlCommand*)command;
- (void)stopBroadcasting:(CDVInvokedUrlCommand*)command;
- (void)viewLiveStream:(CDVInvokedUrlCommand*)command;
- (void)requestPermissions:(CDVInvokedUrlCommand*)command;
@end

@implementation IoniCordovaRTMPandHLS

- (void)coolMethod:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];

    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)previewCamera:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"previewCamera Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)swapCamera:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"swapCamera Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startBroadcasting:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"startBroadcasting Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopBroadcasting:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"stopBroadcasting Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)viewLiveStream:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"viewLiveStream Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)requestPermissions:(CDVInvokedUrlCommand*)command
{
    // Check for camera permission
    AVAuthorizationStatus cameraStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // Check for microphone permission
    AVAuthorizationStatus microphoneStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    // If both permissions are granted, return success
    if (cameraStatus == AVAuthorizationStatusAuthorized && microphoneStatus == AVAuthorizationStatusAuthorized) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Permissions granted"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    // If not, request the necessary permissions
    NSMutableArray *permissionsToRequest = [NSMutableArray array];
    if (cameraStatus == AVAuthorizationStatusNotDetermined) {
        [permissionsToRequest addObject:AVMediaTypeVideo];
    }
    if (microphoneStatus == AVAuthorizationStatusNotDetermined) {
        [permissionsToRequest addObject:AVMediaTypeAudio];
    }
    
    for (NSString *mediaType in permissionsToRequest) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (!granted) {
                // If any permission is denied, return failure
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Permission denied"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }
        }];
    }
    
    // Return success if permissions were granted or if they were already granted
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Permissions granted"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
