package cordova-plugin-ionicrtmphls;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class IoniCordovaRTMPandHLS extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch(action) {
            case "coolMethod":
                String message = args.getString(0);
                this.coolMethod(message, callbackContext);
                return true;
            case "previewCamera":
                this.previewCamera(callbackContext);
                return true;
            case "swapCamera":
                this.swapCamera(callbackContext);
                return true;
            case "startBroadcasting":
                this.startBroadcasting(callbackContext);
                return true;
            case "stopBroadcasting":
                this.stopBroadcasting(callbackContext);
                return true;
            case "viewLiveStream":
                this.viewLiveStream(callbackContext);
                return true;
            case "requestPermissions":
                this.requestPermissions(callbackContext);
                return true;
        }
        return false;
    }

    private void coolMethod(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }

    private void previewCamera(CallbackContext callbackContext) {
        callbackContext.success('previewCamera Executed!');
    }

    private void swapCamera(CallbackContext callbackContext) {
        callbackContext.success('swapCamera Executed!');
    }

    private void startBroadcasting(CallbackContext callbackContext) {
        callbackContext.success('startBroadcasting Executed!');
    }

    private void stopBroadcasting(CallbackContext callbackContext) {
        callbackContext.success('stopBroadcasting Executed!');
    }

    private void viewLiveStream(CallbackContext callbackContext) {
        callbackContext.success('viewLiveStream Executed!');
    }

    private void requestPermissions(CallbackContext callbackContext) {
        callbackContext.success('requestPermissions Executed!');
    }
}
