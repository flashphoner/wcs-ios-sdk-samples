import UIKit
import FPWCSApi2Swift
import Foundation

extension MultiPlayerController : UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.activeTextField = textField
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.activeTextField = nil
        return true
    }
}

extension MultiPlayerController : UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.activeTextField = textView
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.activeTextField = nil
        return true
    }
}

class MultiPlayerController: UIViewController {
    
    var lightOn = true
    var session:WCSSession?
    var publishStream:WCSStream?
    var playStreamLT:WCSStream?
    var playStreamRT:WCSStream?
    var playStreamLB:WCSStream?
    var playStreamRB:WCSStream?
    
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var streamName: UITextField!
    @IBOutlet weak var widthField: UITextField!
    @IBOutlet weak var heightField: UITextField!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!

    @IBOutlet weak var localDisplay: WebRTCView!
    @IBOutlet weak var remoteDisplayLT: WebRTCView!
    @IBOutlet weak var remoteDisplayRT: WebRTCView!
    @IBOutlet weak var remoteDisplayLB: WebRTCView!
    @IBOutlet weak var remoteDisplayRB: WebRTCView!
    
    var activeTextField : UIView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        onDisconnected();
        
        urlField.delegate = self
        streamName.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            var shouldMoveViewUp = false
            
            // if active text field is not nil
            if (activeTextField != nil) {
                
                let bottomOfTextField = activeTextField!.convert(activeTextField!.bounds, to: self.view).maxY;
                
                let topOfKeyboard = self.view.frame.height - keyboardSize.height
                
                // if the bottom of Textfield is below the top of keyboard, move up
                if bottomOfTextField > topOfKeyboard {
                    shouldMoveViewUp = true
                }
            }
            
            if(shouldMoveViewUp && self.view.frame.origin.y == 0) {
                self.view.frame.origin.y = 0 - keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func setupTextFields() {
        let toolbar = UIToolbar()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done,
                                         target: self, action: #selector(doneButtonTapped))
        
        toolbar.setItems([flexSpace, doneButton], animated: true)
        toolbar.sizeToFit()
        
        urlField.inputAccessoryView = toolbar
        streamName.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    @IBAction func startPressed(_ sender: Any) {
        changeViewState(startButton, false)
        changeViewState(urlField, false)
        changeViewState(streamName, false)

        if (startButton.title(for: .normal) == "PUBLISH AND PLAY") {
            if (session == nil) {
                let options = FPWCSApi2SessionOptions()
                options.urlServer = urlField.text
                options.appKey = "defaultApp"
                do {
                    try session = WCSSession(options)
                } catch {
                    print(error)
                }
            }
            session?.on(.fpwcsSessionStatusEstablished, { rSession in
                let status = rSession?.getStatus()
                self.changeConnectionStatus(status: status!)
                self.onConnected(rSession!)
            })
            
            session?.on(.fpwcsSessionStatusDisconnected, { rSession in
                let status = rSession?.getStatus()
                self.changeConnectionStatus(status: status!)
                self.onDisconnected()
                self.session = nil
            })
            
            session?.on(.fpwcsSessionStatusFailed, { rSession in
                let status = rSession?.getStatus()
                self.changeConnectionStatus(status: status!)
                self.onDisconnected()
                self.session = nil
            })
            changeViewState(urlField, false)
            session?.connect()
        } else {
            session?.disconnect()
        }
        
    }
    
    @IBAction func switchCameraPressed(_ sender: Any) {
        publishStream?.switchCamera()
    }
    
    func publish() {
        let options = FPWCSApi2StreamOptions()
        options.name = streamName.text
        options.display = localDisplay.videoView
        
        let ret = FPWCSApi2MediaConstraints()
        
        let video = FPWCSApi2VideoConstraints()
        video.minWidth = Int(widthField.text ?? "0") ?? 0
        video.maxWidth = video.minWidth
        video.minHeight = Int(heightField.text ?? "0") ?? 0
        video.maxHeight = video.minHeight
        ret.video = video
        
        options.constraints = ret
        do {
            publishStream = try session!.createStream(options)
        } catch {
            print(error);
        }
        
        publishStream?.on(.fpwcsStreamStatusPublishing, {rStream in
            self.changeStreamStatus(rStream!)
            self.onPublishing(rStream!);
        });
        
        publishStream?.on(.fpwcsStreamStatusUnpublished, {rStream in
            self.changeStreamStatus(rStream!)
            self.onUnpublished()
        });
        
        publishStream?.on(.fpwcsStreamStatusFailed, {rStream in
            self.changeStreamStatus(rStream!)
            self.onUnpublished()
        });
        do {
            try publishStream?.publish()
        } catch {
            print(error);
        }
    }
    
    
    func play(display: WebRTCView) -> WCSStream? {
        let options = FPWCSApi2StreamOptions()
        options.name = streamName.text;
        options.display = display.videoView;
        do {
            let playStream = try session!.createStream(options)
            
            playStream.on(.fpwcsStreamStatusPlaying, {rStream in
                self.changeStreamStatus(rStream!)
                self.onPlaying(rStream!);
            });
            playStream.on(.fpwcsStreamStatusNotEnoughtBandwidth, {rStream in
                self.changeStreamStatus(rStream!)
            });
            playStream.on(.fpwcsStreamStatusStopped, {rStream in
                self.changeStreamStatus(rStream!)
                self.onStopped()
            });
            playStream.on(.fpwcsStreamStatusFailed, {rStream in
                self.changeStreamStatus(rStream!)
                self.onStopped()
            });
            try playStream.play()
            return playStream;
        } catch {
            print(error);
        }
        return nil;
    }
    
    
    fileprivate func changeConnectionStatus(status: kFPWCSSessionStatus) {
        self.status.text = FPWCSApi2Model.sessionStatus(toString: status);
        switch (status) {
        case .fpwcsSessionStatusFailed:
            self.status.textColor = .red
        case .fpwcsSessionStatusEstablished:
            self.status.textColor = .green
        default:
            self.status.textColor = .darkText
        }
    }
    
    fileprivate func changeStreamStatus(_ stream: FPWCSApi2Stream) {
        
        status.text = FPWCSApi2Model.streamStatus(toString: stream.getStatus());
        switch (stream.getStatus()) {
        case .fpwcsStreamStatusFailed:
            status.textColor = .red;
            switch (stream.getStatusInfo()) {
            case .fpwcsStreamStatusInfoSessionDoesNotExist:
                status.text = "Actual session does not exist";
            case .fpwcsStreamStatusInfoStoppedByPublisherStop:
                status.text = "Related publisher stopped its stream or lost connection";
            case .fpwcsStreamStatusInfoSessionNotReady:
                status.text = "Session is not initialized or terminated on play ordinary stream";
            case .fpwcsStreamStatusInfoRtspStreamNotFound:
                status.text = "Rtsp stream is not found, agent received '404-Not Found'";
            case .fpwcsStreamStatusInfoFailedToConnectToRtspStream:
                status.text = "Failed to connect to rtsp stream";
            case .fpwcsStreamStatusInfoFileNotFound:
                status.text = "File does not exist, check filename";
            case .fpwcsStreamStatusInfoFileHasWrongFormat:
                status.text = "Failed to play vod stream, this format is not supported";
            case .fpwcsStreamStatusInfoStreamNameAlreadyInUse:
                status.text = "Server already has a publish stream with the same name, try using different one";
            case .fpwcsStreamStatusInfoTranscodingRequiredButDisabled:
                status.text = "Transcoding required, but disabled in settings";
            case .fpwcsStreamStatusInfoNoAvailableTranscoders:
                status.text = "No available transcoders for stream";
            default:
                status.text = "Unknown Error";
            }
        case .fpwcsStreamStatusPlaying, .fpwcsStreamStatusPublishing:
            status.textColor = .green;
            break;
        default:
            status.textColor = .darkText;
            break;
        }
    }
    
    fileprivate func onConnected(_ session:FPWCSApi2Session) {
        self.publish();
    }
    
    
    fileprivate func onDisconnected() {
        startButton.setTitle("PUBLISH AND PLAY", for:.normal);
        changeViewState(startButton, true);
        changeViewState(urlField, true);
        changeViewState(streamName, true);
        changeViewState(switchCameraButton, false);
        onUnpublished();
        onStopped();
    }
    
    fileprivate func onPublishing(_ stream:FPWCSApi2Stream) {
        playStreamLT = self.play(display: remoteDisplayLT);
        playStreamRT = self.play(display: remoteDisplayRT);
        playStreamLB = self.play(display: remoteDisplayLB);
        playStreamRB = self.play(display: remoteDisplayRB);
        
        startButton.setTitle("STOP", for:.normal)
        changeViewState(startButton, true);
        changeViewState(switchCameraButton, true);
    }
    
    fileprivate func onUnpublished() {
        do {
            try playStreamLT?.stop();
        } catch {
            print(error);
        }
        do {
            try playStreamRT?.stop();
        } catch {
            print(error);
        }
        do {
            try playStreamLB?.stop();
        } catch {
            print(error);
        }
        do {
            try playStreamRB?.stop();
        } catch {
            print(error);
        }
    }
    
    fileprivate func onPlaying(_ stream:FPWCSApi2Stream) {
    }
    
    fileprivate func onStopped() {
    }
    
    fileprivate func changeViewState(_ button:UIView, _ enabled:Bool) {
        button.isUserInteractionEnabled = enabled;
        if (enabled) {
            button.alpha = 1.0;
        } else {
            button.alpha = 0.5;
        }
    }
}

