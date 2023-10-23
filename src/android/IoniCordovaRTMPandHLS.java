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
    private RtmpConnection connection;
    private RtmpStream stream;
    private HkGLSurfaceView cameraView;
    private CameraSource cameraSource;

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

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getActivity() != null) {
            int permissionCheck = ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.CAMERA);
            if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.CAMERA}, 1);
            }
            if (ContextCompat.checkSelfPermission(getActivity(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(getActivity(), new String[]{Manifest.permission.RECORD_AUDIO}, 1);
            }
        }
        connection = new RtmpConnection();
        stream = new RtmpStream(connection);
        stream.attachAudio(new AudioRecordSource());
        cameraSource = new CameraSource(requireContext());
        cameraSource.open(CameraCharacteristics.LENS_FACING_BACK);
        stream.attachVideo(cameraSource);
        connection.addEventListener(Event.RTMP_STATUS, this);
    }
    
    @RequiresPermission(allOf = {Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO})
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_camera, container, false);
        Button button = v.findViewById(R.id.button);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (button.getText().equals("Publish")) {
                    connection.connect(Preference.shared.rtmpURL);
                    button.setText("Stop");
                } else {
                    connection.close();
                    button.setText("Publish");
                }
            }
        });
        Button switchButton = v.findViewById(R.id.switch_button);
        switchButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                cameraSource.switchCamera();
            }
        });
        cameraView = v.findViewById(R.id.camera);
        cameraView.attachStream(stream);
        return v;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

     @Override
    public void handleEvent(Event event) {
        Log.i(TAG + "#handleEvent", event.toString());
        Map<String, Object> data = EventUtils.toMap(event);
        String code = data.get("code").toString();
        if (code.equals(RtmpConnection.Code.CONNECT_SUCCESS.rawValue)) {
            stream.publish(Preference.shared.streamName);
        }
    }

    public static CameraTabFragment newInstance() {
        return new CameraTabFragment();
    }

    private static final String TAG = CameraTabFragment.class.getSimpleName();

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
