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