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
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.PlayerView;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.haishinkit.event.EventUtils;
import com.haishinkit.media.AudioRecordSource;
import com.haishinkit.media.Camera2Source;
import com.haishinkit.rtmp.RtmpConnection;
import com.haishinkit.rtmp.RtmpStream;
import com.haishinkit.view.HkSurfaceView;
import java.util.Map;

public class IoniCordovaRTMPandHLS extends CordovaPlugin {
    private RtmpConnection connection;
    private RtmpStream stream;
    private Camera2Source cameraSource;
    private HkSurfaceView cameraView;
    private PlayerView playerView;
    private SimpleExoPlayer exoPlayer;
    private CordovaWebView webView;
    private CordovaInterface cordova;
    private int currentCameraFacing = CameraCharacteristics.LENS_FACING_BACK;

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
                Context context = cordova.getActivity().getApplicationContext();
            
                connection = new RtmpConnection();
                stream = new RtmpStream(connection);
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
                connection.addEventListener("rtmpStatus", (event -> {
                    Map<String, Object> data = EventUtils.INSTANCE.toMap(event);
                    String code = data.get("code").toString();
                    if (code.equals(RtmpConnection.Code.CONNECT_SUCCESS.getRawValue())) {
                        stream.publish(RTMPKey, RtmpStream.HowToPublish.LIVE);
                        callbackContext.success("startBroadcasting Executed!");
                    }
                }), false);

                connection.connect(RTMPSUrl);
            }
        });
    }

    private void stopBroadcasting(CallbackContext callbackContext) {
        new AsyncTask<Void, Void, Void>() {
            @Override
            protected Void doInBackground(Void... voids) {
                connection.close();
                stream.close();
                connection = null;
                stream = null;
                return null;
            }

            @Override
            protected void onPostExecute(Void aVoid) {
                callbackContext.success("stopBroadcasting Executed!");
            }
        }.execute();
    }

    private void viewLiveStream(String HLSUrl, CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Context context = cordova.getActivity().getApplicationContext();

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

                    ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                    );
                    playerView.setLayoutParams(layoutParams);

                    ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                    if (parentView instanceof FrameLayout) {
                        FrameLayout frameLayout = (FrameLayout) parentView;
                        frameLayout.addView(playerView, 0);
                        webView.getView().bringToFront();
                    } else {
                        cordova.getActivity().addContentView(playerView, layoutParams);
                        playerView.bringToFront();
                    }

                    exoPlayer.play();
                    webView.getView().setBackgroundColor(Color.TRANSPARENT);

                    callbackContext.success("viewLiveStream Executed!");
                }catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
        });
    }

    private void closeLiveStream(CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(playerView != null) {
                    exoPlayer.stop();
                    exoPlayer.release();
                    exoPlayer = null;

                    ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                    if (parentView instanceof FrameLayout) {
                        FrameLayout frameLayout = (FrameLayout) parentView;
                        frameLayout.removeView(playerView);
                        webView.getView().bringToFront();
                        webView.getView().setBackgroundColor(Color.WHITE);
                        playerView = null;
                    }
                    callbackContext.success("closeLiveStream Executed!");
                }
            }
        });
    }

    private void requestPermissions(CallbackContext callbackContext) {
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
        }
        callbackContext.success("requestPermissions Executed!");
    }
}