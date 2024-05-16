package cordova.plugin.ionicrtmphls;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.hardware.camera2.CameraCharacteristics;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Handler;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.core.content.ContextCompat;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.LOG;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.amazonaws.ivs.broadcast.BroadcastConfiguration;
import com.amazonaws.ivs.broadcast.BroadcastException;
import com.amazonaws.ivs.broadcast.BroadcastSession;
import com.amazonaws.ivs.broadcast.Device;
import com.amazonaws.ivs.broadcast.ImageDevice;
import com.amazonaws.ivs.broadcast.ImagePreviewView;
import com.amazonaws.ivs.broadcast.Presets;
import com.amazonaws.ivs.broadcast.TypedLambda;
import com.haishinkit.media.Camera2Source;
import com.haishinkit.rtmp.RtmpConnection;
import com.haishinkit.rtmp.RtmpStream;
import com.haishinkit.view.HkSurfaceView;

import androidx.annotation.NonNull;
import com.amazonaws.ivs.player.Cue;
import com.amazonaws.ivs.player.PlayerException;
import com.amazonaws.ivs.player.Quality;
import com.amazonaws.ivs.player.ResizeMode;
import com.amazonaws.ivs.player.Player;
import com.amazonaws.ivs.player.PlayerView;
import org.apache.cordova.PluginResult;


import java.util.List;

public class IoniCordovaRTMPandHLS extends CordovaPlugin {
  private RtmpConnection connection;
  private RtmpStream stream;
  private BroadcastSession broadcastSession;
  private Camera2Source cameraSource;
  private ImagePreviewView cameraView;
  private PlayerView playerViewIVS;
  private Player player;
  private CordovaWebView webView;
  private CordovaInterface cordova;
  private Device currentCamera;
  private CallbackContext savedCallbackContext;
  private CallbackContext eventsCallbackContext;
  private CallbackContext eventsCallbackContext2;
  private BroadcastConfiguration ivsVideoConfig;

  @Override
  public void initialize(final CordovaInterface _cordova, final CordovaWebView _webView) {
    super.initialize(_cordova, _webView);
    webView = _webView;
    cordova = _cordova;
  }

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    switch(action) {
      case "addConnectiontListenerOffline":
        eventsCallbackContext2 = callbackContext;
        return true;
      case "onConnectionChange":
        eventsCallbackContext = callbackContext;
        return true;
      case "offConnectionChange":
        eventsCallbackContext = null;
        return true;
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

          createBroadcastSession();

          broadcastSession.awaitDeviceChanges(() -> {
            for(Device device: broadcastSession.listAttachedDevices()) {

              if(device.getDescriptor().type == Device.Descriptor.DeviceType.CAMERA) {
                ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                  ViewGroup.LayoutParams.MATCH_PARENT,
                  ViewGroup.LayoutParams.MATCH_PARENT
                );

                currentCamera = device;

                cameraView = ((ImageDevice)device).getPreviewView();
                cameraView.setLayoutParams(layoutParams);

                ViewGroup parentView = (ViewGroup) webView.getView().getParent();
                if (parentView instanceof FrameLayout) {
                  FrameLayout frameLayout = (FrameLayout) parentView;
                  frameLayout.addView(cameraView, 0);
                  webView.getView().bringToFront();
                } else {
                  cordova.getActivity().addContentView(cameraView, layoutParams);
                  cameraView.bringToFront();
                }
              }
            }
          });

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
          broadcastSession.release();
          ViewGroup parentView = (ViewGroup) webView.getView().getParent();
          if (parentView instanceof FrameLayout) {
            FrameLayout frameLayout = (FrameLayout) parentView;
            frameLayout.removeView(cameraView);
            webView.getView().bringToFront();
            webView.getView().setBackgroundColor(Color.WHITE);
            cameraView = null;
          }
          if(callbackContext != null ) {
            callbackContext.success("closeCameraPreview Executed!");
          }
        }
      }
    });
  }

  private void swapCamera(CallbackContext callbackContext) {
    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        for(Device.Descriptor device: broadcastSession.listAvailableDevices(cordova.getActivity().getApplicationContext())) {
          if(device.type == Device.Descriptor.DeviceType.CAMERA &&
            device.position != currentCamera.getDescriptor().position) {

            ViewGroup parentView = (ViewGroup) webView.getView().getParent();

            if (parentView instanceof FrameLayout) {
              FrameLayout frameLayout = (FrameLayout) parentView;
              frameLayout.removeView(cameraView);
              webView.getView().bringToFront();
              webView.getView().setBackgroundColor(Color.TRANSPARENT);
              cameraView = null;
            }

            broadcastSession.exchangeDevices(currentCamera, device, _camera -> {

              ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
              );

              currentCamera = _camera;
              cameraView = ((ImageDevice)_camera).getPreviewView();
              cameraView.setLayoutParams(layoutParams);

              ViewGroup parentView2 = (ViewGroup) webView.getView().getParent();

              if (parentView2 instanceof FrameLayout) {
                FrameLayout frameLayout = (FrameLayout) parentView2;
                frameLayout.addView(cameraView, 0);
                webView.getView().bringToFront();
                webView.getView().setBackgroundColor(Color.TRANSPARENT);
              } else {
                cordova.getActivity().addContentView(cameraView, layoutParams);
                cameraView.bringToFront();
              }

            });
            break;
          }
        }};
    });
  }

  private void startBroadcasting(String RTMPSUrl, String RTMPKey, CallbackContext callbackContext) {
    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        try {
          broadcastSession.start(RTMPSUrl, RTMPKey);
          callbackContext.success("startBroadcasting Executed!");
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

        return null;
      }

      @Override
      protected void onPostExecute(Void aVoid) {
        cordova.getActivity().runOnUiThread(new Runnable() {
          @Override
          public void run() {
            broadcastSession.stop();
          }
        });
        callbackContext.success("stopBroadcasting Executed!");
      }}.execute();
  }

  private void viewLiveStream(String HLSUrl, CallbackContext callbackContext) {
    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        try {
          Context context = cordova.getActivity().getApplicationContext();
          savedCallbackContext = callbackContext;
          playerViewIVS = new PlayerView(context);
          playerViewIVS.setControlsEnabled(false);
          playerViewIVS.setResizeMode(ResizeMode.FILL);

          player = playerViewIVS.getPlayer();

          player.addListener(new Player.Listener() {
            @Override
            public void onCue(@NonNull Cue cue) {
            
            }

            @Override
            public void onDurationChanged(long l) {

            }

            @Override
            public void onStateChanged(@NonNull Player.State state) {

              switch (state) {
                case ENDED:
                  try {
                    JSONObject eventData = new JSONObject();
                    eventData.put("connected", false);
                    sendConnectionEvent(eventData, "addConnectiontListenerOffline");
                  } catch (Exception e) {

                    Log.d("TESTJL",  "error 1 ended");
                  }
                  break;
              
                case READY:
                  player.play();

                  try {
                    JSONObject eventData = new JSONObject();
                    eventData.put("connected", true);
                    sendConnectionEvent(eventData, "onConnectionChange");
                  } catch (Exception e) {

                    Log.d("TESTJL",  "error 1");
                  }
                  break;
              }
            }

            @Override
            public void onError(@NonNull PlayerException e) {
              if (e.getCode() == 404) {
                new Handler().postDelayed(new Runnable() {
                  @Override
                  public void run() {
                    viewLiveStream(HLSUrl, callbackContext);
                  }
                }, 5000);
              } 
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
  
  BroadcastSession.Listener broadcastListener =
    new BroadcastSession.Listener() {
      @Override
      public void onStateChanged(@NonNull BroadcastSession.State state) {
        Log.d("D", "State=" + state);
      }

      @Override
      public void onError(@NonNull BroadcastException exception) {
        Log.e("D", "Exception: " + exception);
      }
    };

  private void setVideoSettings() {
    ivsVideoConfig = new BroadcastConfiguration();
    ivsVideoConfig.audio.setBitrate(128_000);
    ivsVideoConfig.video.setMaxBitrate(8_000_000);
    ivsVideoConfig.video.setMinBitrate(2_500_000);
    ivsVideoConfig.video.setInitialBitrate(5_000_000);
    ivsVideoConfig.video.setSize(1080, 1920);
    ivsVideoConfig.video.setKeyframeInterval(1);
    ivsVideoConfig.video.setTargetFramerate(30);
  }

  private void createBroadcastSession() {
    Context ctx = cordova.getActivity().getApplicationContext();
    setVideoSettings();
    broadcastSession = new BroadcastSession(ctx,
      broadcastListener,
      ivsVideoConfig,
      Presets.Devices.BACK_CAMERA(ctx));
  }

  private void sendConnectionEvent(JSONObject eventData, String eventName) {
    if(eventsCallbackContext != null && eventName == "onConnectionChange") {
      PluginResult result = new PluginResult(PluginResult.Status.OK, eventData);
      result.setKeepCallback(true);

      Log.d("TESTJL",  "sendPluginResult onConnectionChange");
      eventsCallbackContext.sendPluginResult(result);
    }  else if(eventsCallbackContext2 != null && eventName == "addConnectiontListenerOffline") {
      PluginResult result = new PluginResult(PluginResult.Status.OK, eventData);
      result.setKeepCallback(true);

      Log.d("TESTJL",  "sendPluginResult addConnectiontListenerOffline");
      eventsCallbackContext2.sendPluginResult(result);
    }

    
  }
}
