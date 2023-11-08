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
    CDVPluginResult* pluginResult  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:"previewCamera Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)swapCamera:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:"swapCamera Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startBroadcasting:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:"startBroadcasting Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopBroadcasting:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:"stopBroadcasting Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)viewLiveStream:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:"viewLiveStream Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)requestPermissions:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:"requestPermissions Executed!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
