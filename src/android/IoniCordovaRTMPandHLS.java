package cordova.plugin.ionicrtmphls;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.hardware.camera2.CameraCharacteristics;
import android.net.Uri;
import android.os.AsyncTask;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.core.content.ContextCompat;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import com.haishinkit.event.EventUtils;
import com.haishinkit.media.AudioRecordSource;
import com.haishinkit.media.Camera2Source;
import com.haishinkit.rtmp.RtmpConnection;
import com.haishinkit.rtmp.RtmpStream;
import com.haishinkit.codec.CodecOption;
import com.haishinkit.codec.VideoCodec;
import com.haishinkit.view.HkSurfaceView;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;
import androidx.annotation.NonNull;
import com.amazonaws.ivs.player.Cue;
import com.amazonaws.ivs.player.PlayerException;
import com.amazonaws.ivs.player.Quality;
import com.amazonaws.ivs.player.ResizeMode;
import com.amazonaws.ivs.player.Player;
import com.amazonaws.ivs.player.PlayerView;

public class IoniCordovaRTMPandHLS extends CordovaPlugin {
    private RtmpConnection connection;
    private RtmpStream stream;
    private Camera2Source cameraSource;
    private HkSurfaceView cameraView;
    private PlayerView playerViewIVS;
    private Player player;
    private CordovaWebView webView;
    private CordovaInterface cordova;
    private int currentCameraFacing = CameraCharacteristics.LENS_FACING_BACK;
    private CallbackContext savedCallbackContext;

    @Override
    public void initialize(final CordovaInterface _cordova, final CordovaWebView _webView) {
        super.initialize(_cordova, _webView);
        webView = _webView;
        cordova = _cordova;
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        switch(action) {
            case "previewCamera":
                JSONArray CameraOpts = args;
                this.previewCamera(CameraOpts, callbackContext);
                return true;
            case "closeCameraPreview":
                this.closeCameraPreview(callbackContext);
                return true;
            case "swapCamera":
                this.swapCamera(callbackContext);
                return true;
            case "startBroadcasting":
                String RTMPUrl = args.getString(0);
                String RTMPKey = args.getString(1);
                this.startBroadcasting(RTMPUrl, RTMPKey, callbackContext);
                return true;
            case "stopBroadcasting":
                this.stopBroadcasting(callbackContext);
                return true;
            case "viewLiveStream":
                String HLSUrl = args.getString(0);
                this.viewLiveStream(HLSUrl, callbackContext);
                return true;
            case "closeLiveStream":
                this.closeLiveStream(callbackContext);
                return true;
            case "requestPermissions":
                this.requestPermissions(callbackContext);
                return true;
        }
        return false;
    }

    private void previewCamera(JSONArray CameraOpts, CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @SuppressLint("ResourceAsColor")
            @Override
            public void run() {
                try {
                    Context context = cordova.getActivity().getApplicationContext();

                    connection = new RtmpConnection();
                    stream = new RtmpStream(connection);
                    
                    stream.getVideoSetting().setFrameRate(60);
                    List<CodecOption> options = new ArrayList<>();
                    CodecOption profileOption = new CodecOption("profile", "high");
                    options.add(profileOption);
                    CodecOption levelOption = new CodecOption("level", "5.1");
                    options.add(levelOption);
                    stream.getVideoSetting().setOptions(options);
                    stream.getVideoSetting().setBitRate(8500 * 1000);
                    stream.getVideoSetting().setIFrameInterval(2);
                    stream.getVideoSetting().setWidth(1080);
                    stream.getVideoSetting().setHeight(1920);
                    stream.getAudioSetting().setBitRate(96 * 1000);

                    stream.attachAudio(new AudioRecordSource(context, false));

                    cameraSource = new Camera2Source(context, false);
                    stream.attachVideo(cameraSource);

                    cameraView = new HkSurfaceView(cordova.getActivity());
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
                        frameLayout.addView(cameraView, 0);
                        webView.getView().bringToFront();
                    } else {
                        cordova.getActivity().addContentView(cameraView, layoutParams);
                        cameraView.bringToFront();
                    }

                    webView.getView().setBackgroundColor(Color.TRANSPARENT);
                    callbackContext.success("previewCamera Executed!");

                } catch (Exception ex) {
                    callbackContext.error("Failed to previewCamera");
                }
            }
        });
    }

    private void closeCameraPreview(CallbackContext callbackContext) {
          cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(cameraView != null) {
                    cameraSource.close();
                    cameraSource = null;
                    stream = null;
                    connection = null;

                    ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                    if (parentView instanceof FrameLayout) {
                        FrameLayout frameLayout = (FrameLayout) parentView;
                        frameLayout.removeView(cameraView);
                        webView.getView().bringToFront();
                        webView.getView().setBackgroundColor(Color.WHITE);
                        cameraView = null;
                    }
                    callbackContext.success("closeCameraPreview Executed!");
                }
            }
        });
    }

    private void swapCamera(CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                cameraSource.close();

                currentCameraFacing = (currentCameraFacing == CameraCharacteristics.LENS_FACING_BACK)
                        ? CameraCharacteristics.LENS_FACING_FRONT
                        : CameraCharacteristics.LENS_FACING_BACK;

                cameraSource.open(currentCameraFacing);
                callbackContext.success("swapCamera Executed!");
            }
        });
    }

    private void startBroadcasting(String RTMPSUrl, String RTMPKey, CallbackContext callbackContext) {
       cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    connection.addEventListener("rtmpStatus", (event -> {
                        Map<String, Object> data = EventUtils.INSTANCE.toMap(event);
                        String code = data.get("code").toString();
                        if (code.equals(RtmpConnection.Code.CONNECT_SUCCESS.getRawValue())) {
                            stream.publish(RTMPKey, RtmpStream.HowToPublish.LIVE);
                            callbackContext.success("startBroadcasting Executed!");
                        }
                    }), false);

                    connection.connect(RTMPSUrl);
                } catch (Exception ex) {
                    callbackContext.error("Failed to startBroadcasting");
                }
            }
        });
    }

    private void stopBroadcasting(CallbackContext callbackContext) {
        new AsyncTask<Void, Void, Void>() {
        @Override
        protected Void doInBackground(Void... voids) {
            if(connection != null) {
                connection.close();
                connection = null;
            }
            if(stream != null) {
                stream.close();
                stream = null;
            }
            return null;
        }

        @Override
        protected void onPostExecute(Void aVoid) {
            callbackContext.success("stopBroadcasting Executed!");
        }}.execute();
    }

    private void viewLiveStream(String HLSUrl, CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Context context = cordova.getActivity().getApplicationContext();
                    /*
                    exoPlayer = new SimpleExoPlayer.Builder(context).build();
                    exoPlayer.setPlayWhenReady(true);

                    playerView = new PlayerView(cordova.getActivity());
                    playerView.setPlayer(exoPlayer);
                    playerView.setUseController(false);
                    playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_FILL);

                    MediaSource mediaSource = new HlsMediaSource.Factory(new DefaultHttpDataSource.Factory())
                            .createMediaSource(MediaItem.fromUri(Uri.parse(HLSUrl)));

                    exoPlayer.setMediaSource(mediaSource);
                    exoPlayer.prepare();
                    */

                    playerViewIVS = new PlayerView(context);
                    playerViewIVS.setControlsEnabled(false);
                    playerViewIVS.setResizeMode(ResizeMode.FILL);

                    player = playerViewIVS.getPlayer();

                    player.addListener(new Player.Listener() {
                        @Override
                        public void onStateChanged(@NonNull Player.State state) {

                        switch (state) {
                            case READY:
                                    player.play();
                                break;
                            }
                        }

                        @Override
                        public void onError(@NonNull PlayerException e) {

                        }

                        @Override
                        public void onRebuffering() {

                        }

                        @Override
                        public void onSeekCompleted(long l) {

                        }

                        @Override
                        public void onVideoSizeChanged(int i, int i1) {

                        }

                        @Override
                        public void onQualityChanged(@NonNull Quality quality) {

                        }
                    });

                    ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                    );
                    playerViewIVS.setLayoutParams(layoutParams);

                    ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                    if (parentView instanceof FrameLayout) {
                        FrameLayout frameLayout = (FrameLayout) parentView;
                        frameLayout.addView(playerViewIVS, 0);
                        webView.getView().bringToFront();
                    } else {
                        cordova.getActivity().addContentView(playerViewIVS, layoutParams);
                        playerViewIVS.bringToFront();
                    }

                    player.load(Uri.parse(HLSUrl));
                    webView.getView().setBackgroundColor(Color.TRANSPARENT);

                    callbackContext.success("viewLiveStream Executed!");
                } catch (Exception ex) {
                    callbackContext.error("Failed to viewLiveStream");
                }
            }
        });
    }

    private void closeLiveStream(CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(playerViewIVS != null) {
                    player.release();
                    player = null;

                    ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                    if (parentView instanceof FrameLayout) {
                        FrameLayout frameLayout = (FrameLayout) parentView;
                        frameLayout.removeView(playerViewIVS);
                        webView.getView().bringToFront();
                        webView.getView().setBackgroundColor(Color.WHITE);
                        playerViewIVS = null;
                    }
                    callbackContext.success("closeLiveStream Executed!");
                }
            }
        });
    }

    private void requestPermissions(CallbackContext callbackContext) {
        savedCallbackContext = callbackContext;

        String[] permissions = {
                    Manifest.permission.CAMERA,
                    Manifest.permission.RECORD_AUDIO
        };

        boolean hasPermissions = true;
        for (String permission : permissions) {
            if (ContextCompat.checkSelfPermission(cordova.getActivity(), permission) != PackageManager.PERMISSION_GRANTED) {
                hasPermissions = false;
                break;
            }
        }

        if (!hasPermissions) {
            cordova.requestPermissions(this, 1, permissions);
        } else {
            savedCallbackContext.success("requestPermissions Executed!");
        }
    }

    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
        if (requestCode == 1) {
            boolean allPermissionsGranted = true;

            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                allPermissionsGranted = false;
                break;
                }
            }

            if (allPermissionsGranted) {
                // Call success in the onRequestPermissionResult
                savedCallbackContext.success("Permissions granted!");
            } else {
                // Call error in the onRequestPermissionResult
                savedCallbackContext.error("Permissions denied!");
            }

            // Reset the stored callback context after using it
            savedCallbackContext = null;

        } else {
            // Handle other permission requests if any
            super.onRequestPermissionResult(requestCode, permissions, grantResults);
        }
    }
}
