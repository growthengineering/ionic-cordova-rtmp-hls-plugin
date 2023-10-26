package cordova.plugin.ionicrtmphls;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.hardware.camera2.CameraCharacteristics;
import android.os.Bundle;
import android.view.Display;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.bambuser.broadcaster.SurfaceViewWithAutoAR;

import com.haishinkit.event.Event;
import com.haishinkit.event.IEventListener;
import com.haishinkit.media.AudioRecordSource;
import com.haishinkit.media.Camera2Source;
import com.haishinkit.rtmp.RtmpConnection;
import com.haishinkit.rtmp.RtmpStream;
import com.haishinkit.view.HkSurfaceView;

import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

/**
 * This class echoes a string called from JavaScript.
 */
public class IoniCordovaRTMPandHLS extends CordovaPlugin {
    private RtmpConnection connection;
    private RtmpStream stream;
    private HkSurfaceView cameraView;
    //private CameraSource cameraSource;
    private CordovaWebView webView;
    private CordovaInterface cordova;
    private SurfaceViewWithAutoAR playbackSurfaceView;
    private SurfaceViewWithAutoAR previewSurfaceView;
    private Display mDefaultDisplay;

    @Override
    public void initialize(final CordovaInterface _cordova, final CordovaWebView _webView) {
        super.initialize(_cordova, _webView);
        webView = _webView;
        cordova = _cordova;
    }

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
        Context context = cordova.getActivity().getApplicationContext();
        Toast.makeText(context, "previewCamera", Toast.LENGTH_SHORT).show();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @SuppressLint("ResourceAsColor")
            @Override
            public void run() {
                Toast.makeText(context, "1 Permissions", Toast.LENGTH_SHORT).show();
                // Ensure you have the necessary permissions
                requestPermissions(callbackContext);

                Toast.makeText(context, "2 After Permissions", Toast.LENGTH_SHORT).show();

                // Initialize RTMP connection and stream

               // RtmpConnection connection = new RtmpConnection();
               // RtmpStream stream = new RtmpStream(connection);



                // Attach audio and video sources
               // stream.attachAudio(new AudioRecordSource(context, true));
                Camera2Source cameraSource = new Camera2Source(context, true);
                cameraSource.open(CameraCharacteristics.LENS_FACING_BACK);
             //   stream.attachVideo(cameraSource);
                Toast.makeText(context, "3 ", Toast.LENGTH_SHORT).show();
                HkSurfaceView cameraView = new HkSurfaceView(cordova.getActivity());
              //  cameraView.attachStream(stream);
                Toast.makeText(context, "4 ", Toast.LENGTH_SHORT).show();
                ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                );
                cameraView.setLayoutParams(layoutParams);
                Toast.makeText(context, "5 ", Toast.LENGTH_SHORT).show();
                ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                if (parentView instanceof FrameLayout) {
                    Toast.makeText(context, "5.1 ", Toast.LENGTH_SHORT).show();
                    FrameLayout frameLayout = (FrameLayout) parentView;
                    frameLayout.addView(cameraView, layoutParams);
                    frameLayout.bringChildToFront(cameraView);
                } else {
                    Toast.makeText(context, "5.2 ", Toast.LENGTH_SHORT).show();
                    // If the parent view is not a FrameLayout, just add the cameraView directly to the activity
                    cordova.getActivity().addContentView(cameraView, layoutParams);
                }
                Toast.makeText(context, "6 ", Toast.LENGTH_SHORT).show();
                // Add the camera view to your Cordova WebView
                webView.getView().setBackgroundColor(Color.TRANSPARENT);
                cameraView.bringToFront();
                Toast.makeText(context, "7 ", Toast.LENGTH_SHORT).show();
                cameraView.setTranslationZ(1.0f);
                cameraView.setVisibility(View.VISIBLE);
                webView.getView().setTranslationZ(-1.0f);
                Toast.makeText(context, "8 ", Toast.LENGTH_SHORT).show();
                // Optionally, return success to the JavaScript side
                callbackContext.success("Camera preview started!");
            }
        });
        callbackContext.success("previewCamera Executed!");
    }

    private void swapCamera(CallbackContext callbackContext) {
        callbackContext.success("swapCamera Executed!");
    }

    private void startBroadcasting(CallbackContext callbackContext) {
        callbackContext.success("startBroadcasting Executed!");
    }

    private void stopBroadcasting(CallbackContext callbackContext) {
        callbackContext.success("stopBroadcasting Executed!");
    }

    private void viewLiveStream(CallbackContext callbackContext) {
        callbackContext.success("viewLiveStream Executed!");
    }

    private void requestPermissions(CallbackContext callbackContext) {
        String[] permissions = {
                Manifest.permission.CAMERA,
                Manifest.permission.RECORD_AUDIO
        };

        // Check if permissions are granted
        boolean hasPermissions = true;
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(cordova.getActivity(), permission) != PackageManager.PERMISSION_GRANTED) {
                hasPermissions = false;
                break;
            }
        }

        // Request permissions if not granted
        if (!hasPermissions) {
            cordova.requestPermissions(this, 1, permissions);
        }
        callbackContext.success("requestPermissions Executed!");
    }
}