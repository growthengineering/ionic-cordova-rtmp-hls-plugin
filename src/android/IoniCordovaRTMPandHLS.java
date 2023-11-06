package cordova.plugin.ionicrtmphls;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.hardware.camera2.CameraCharacteristics;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.util.Size;
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

import org.jetbrains.annotations.NotNull;
import org.json.JSONArray;
import org.json.JSONException;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.bambuser.broadcaster.SurfaceViewWithAutoAR;

import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.ui.PlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.haishinkit.event.Event;
import com.haishinkit.event.EventUtils;
import com.haishinkit.event.IEventListener;
import com.haishinkit.graphics.VideoGravity;
import com.haishinkit.media.AudioRecordSource;
import com.haishinkit.media.Camera2Source;
import com.haishinkit.rtmp.RtmpConnection;
import com.haishinkit.rtmp.RtmpStream;
import com.haishinkit.view.HkSurfaceView;
import com.haishinkit.event.Event;
import com.haishinkit.event.IEventListener;
import com.haishinkit.rtmp.RtmpStream;

import java.util.Map;
import android.os.Handler;
import static android.view.ViewGroup.LayoutParams.WRAP_CONTENT;

/**
 * This class echoes a string called from JavaScript.
 */
public class IoniCordovaRTMPandHLS extends CordovaPlugin implements IEventListener {
    private RtmpConnection connection;
    private RtmpStream stream;
    //private HkSurfaceView cameraView;
    private Camera2Source cameraSource;
    private CordovaWebView webView;
    private CordovaInterface cordova;
    private int currentCameraFacing = CameraCharacteristics.LENS_FACING_BACK;  // Default to back-facing camera

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
                this.previewCamera(args.getInt(0), args.getInt(1), args.getInt(2), args.getInt(3), callbackContext);
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

    private void previewCamera(int left, int top, int width, int height, CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @SuppressLint("ResourceAsColor")
            @Override
            public void run() {
                Context context = cordova.getActivity().getApplicationContext();
                Toast.makeText(context, "previewCamera", Toast.LENGTH_SHORT).show();

                // Initialize RTMP connection and stream
                connection = new RtmpConnection();
               // connection.setTimeout(100000);
                stream = new RtmpStream(connection);

                // Video Settings
                //stream.getVideoSetting().setWidth(360);
                //stream.getVideoSetting().setHeight(640);
               // stream.getVideoSetting().setBitRate(2500 * 1000);
                //stream.getVideoSetting().setIFrameInterval(2);
              //  VideoGravity videoGravity = VideoGravity.RESIZE_ASPECT_FILL;
              //  stream.getVideoSetting().setVideoGravity(videoGravity);

                // Audio Settings
              //  stream.getAudioSetting().setBitRate(160 * 1000);
                stream.attachAudio(new AudioRecordSource(context, false));

                // Camera Settings
                cameraSource = new Camera2Source(context, false);
              //  cameraSource.setResolution(new Size(360, 640));
    
                stream.attachVideo(cameraSource);

                HkSurfaceView cameraView = new HkSurfaceView(cordova.getActivity());
                cameraView.attachStream(stream);

                ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                );
                cameraView.setLayoutParams(layoutParams);

                cameraSource.open(currentCameraFacing);

                ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                if (parentView instanceof FrameLayout) {
                    FrameLayout frameLayout = (FrameLayout) parentView;
                    frameLayout.addView(cameraView, 0);  // add cameraView at the bottom
                    webView.getView().bringToFront();  // bring webView to the front
                } else {
                    // If the parent view is not a FrameLayout, just add the cameraView directly to the activity
                    cordova.getActivity().addContentView(cameraView, layoutParams);
                    cameraView.bringToFront();
                }

                // Add the camera view to your Cordova WebView
                webView.getView().setBackgroundColor(Color.TRANSPARENT);
                callbackContext.success("Camera preview started!");
            }
        });
    }

    private void swapCamera(CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                cameraSource.close();

                // Toggle the current camera facing direction
                currentCameraFacing = (currentCameraFacing == CameraCharacteristics.LENS_FACING_BACK)
                        ? CameraCharacteristics.LENS_FACING_FRONT
                        : CameraCharacteristics.LENS_FACING_BACK;

                // Open the new camera
                cameraSource.open(currentCameraFacing);

            }
        });
        callbackContext.success("swapCamera Executed!");
    }
    @Override
    public void handleEvent(Event event) {
        Log.e( "#handleEvent", String.valueOf(event));
        //Map<String, Object> data = EventUtils.toMap(event);
        //String code = data.get("code").toString();
        //if (code.equals(RtmpConnection.Code.CONNECT_SUCCESS.rawValue)) {
       //     stream.publish("641aedc9-d51c-2ff5-1a85-b5e9c6e38611");
        //}
    }
    private void startBroadcasting(CallbackContext callbackContext) {
       cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Context context = cordova.getActivity().getApplicationContext();
                //connection.connect("");
                connection.connect("");

                Toast.makeText(context, "startBroadcasting", Toast.LENGTH_SHORT).show();

                Handler handler = new Handler();
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(context, "Publish", Toast.LENGTH_SHORT).show();
                        Toast.makeText(context, "IsConnected " + connection.isConnected(), Toast.LENGTH_SHORT).show();
                        Toast.makeText(context, "getCurrentFPS" + stream.getCurrentFPS(), Toast.LENGTH_SHORT).show();


                        //stream.publish("", RtmpStream.HowToPublish.LIVE);
                       stream.publish("", RtmpStream.HowToPublish.LIVE);
                    }
                }, 5000); // 5000 milliseconds (5 seconds)
            }
        });
    }

    private void stopBroadcasting(CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Context context = cordova.getActivity().getApplicationContext();
                connection.close();
                stream.close();
                Toast.makeText(context, "stopBroadcasting", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void viewLiveStream(CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Context context = cordova.getActivity().getApplicationContext();

                    String hlsStreamUrl = "";

                    SimpleExoPlayer player = new SimpleExoPlayer.Builder(context).build();

                    PlayerView playerView = new PlayerView(cordova.getActivity());
                    playerView.setPlayer(player);
                    playerView.setUseController(false);

                    MediaSource mediaSource = new HlsMediaSource.Factory(new DefaultHttpDataSource.Factory())
                            .createMediaSource(MediaItem.fromUri(Uri.parse(hlsStreamUrl)));


                    player.setMediaSource(mediaSource);
                    player.prepare();


                    ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                    );
                    playerView.setLayoutParams(layoutParams);

                    ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                    if (parentView instanceof FrameLayout) {
                        FrameLayout frameLayout = (FrameLayout) parentView;
                        frameLayout.addView(playerView, 0);  // add cameraView at the bottom
                        webView.getView().bringToFront();  // bring webView to the front
                    } else {
                        cordova.getActivity().addContentView(playerView, layoutParams);
                        playerView.bringToFront();
                    }

                    // Add the camera view to your Cordova WebView
                    webView.getView().setBackgroundColor(Color.TRANSPARENT);

                    callbackContext.success("viewLiveStream Executed!");
                }catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        });
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