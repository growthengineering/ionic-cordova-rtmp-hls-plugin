/********* IoniCordovaRTMPandHLS.m Cordova Plugin Implementation *******/
#import <AVFoundation/AVFoundation.h>
#import "IoniCordovaRTMPandHLS.h"


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
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        // Assuming you have a property for the RTMP connection and stream
        self.connection = [[RtmpConnection alloc] init];
        self.stream = [[RtmpStream alloc] initWithConnection:self.connection];

        // Attach audio and video sources
        // These classes and methods are assumed based on your Java code
        AudioRecordSource audioSource = [[AudioRecordSource alloc] initWithContext:self command:command];
        [self.stream attachAudio:audioSource];

        Camera2SourcecameraSource = [[Camera2Source alloc] initWithContext:self command:command];
        [self.stream attachVideo:cameraSource];

        HkSurfaceView cameraView = [[HkSurfaceView alloc] initWithContext:self command:command];
        [cameraView attachStream:self.stream];

        // Set layout parameters
        // This is a simplified example, you'll need to set the actual parameters based on your app's layout
        cameraView.frame = CGRectMake(0, 0, self.webView.frame.size.width, self.webView.frame.size.height);

        // Add the camera view to the Cordova WebView
        [self.webView addSubview:cameraView];

        // Set the background color of the WebView to transparent
        [self.webView setBackgroundColor:[UIColor clearColor]];

        // Create a success result
        CDVPluginResultpluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Camera preview started!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });

   */
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"previewCamera Executed!"];
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
