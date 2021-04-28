import UIKit
import FPWCSApi2Swift

extension MCUViewController : UITextFieldDelegate {
    // when user select a textfield, this method will be called
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // set the activeTextField to the selected textfield
        self.activeTextField = textField
    }
    
    // when user click 'done' or dismiss the keyboard
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
    }
}

class MCUViewController: UIViewController {
    
    var lightOn = true
    var session:WCSSession?
    var publishStream:WCSStream?
    var playStream:WCSStream?
    
    @IBOutlet weak var serverField: UITextField!
    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var roomField: UITextField!
    @IBOutlet weak var audioSwitch: UISwitch!
    @IBOutlet weak var videoSwitch: UISwitch!
    @IBOutlet weak var transportSwitch: UISwitch!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    
    @IBOutlet weak var localDisplay: WebRTCView!
    @IBOutlet weak var remoteDisplay: WebRTCView!
    
    var activeTextField : UITextField? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        onDisconnected();
        
        serverField.delegate = self
        loginField.delegate = self
        roomField.delegate = self
        
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
        
        serverField.inputAccessoryView = toolbar
        loginField.inputAccessoryView = toolbar
        roomField.inputAccessoryView = toolbar
        
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    @IBAction func fieldChanged(_ sender: Any) {
        checkRequiredFields();
    }
    
    @IBAction func checkRequiredFields() {
        if (loginField.hasText && roomField.hasText) {
            changeViewState(joinButton, true)
            return;
        }
        changeViewState(joinButton, false)
    }
    
    @IBAction func joinPressed(_ sender: Any) {
        self.changeViewState(joinButton, false)
        if (joinButton.title(for: .normal) == "JOIN") {
            if (session == nil) {
                let options = FPWCSApi2SessionOptions()
                options.urlServer = serverField.text
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
                self.publish();
            })
            
            session?.on(.fpwcsSessionStatusDisconnected, { rSession in
                self.onDisconnected()
            })
            
            session?.on(.fpwcsSessionStatusFailed, { rSession in
                let status = rSession?.getStatus()
                self.changeConnectionStatus(status: status!)
                self.onDisconnected()
            })
            self.changeViewState(serverField, false)
            session?.connect()
        } else {
            leave()
        }
        
    }
    
    func leave() {
        session?.disconnect()
        session = nil;
    }
    
    func publish() {
        if (publishStream != nil) {
            self.stopPublish();
        }
        let constraints = FPWCSApi2MediaConstraints()
        if (audioSwitch.isOn) {
            constraints.audio = FPWCSApi2AudioConstraints()
        }
        if (videoSwitch.isOn) {
            constraints.video = FPWCSApi2VideoConstraints()
        }
        let options = FPWCSApi2StreamOptions()
        options.name = loginField.text! + "#" + roomField.text!
        options.transport = transportSwitch.isOn ? kFPWCSTransport.fpwcsTransportTCP : kFPWCSTransport.fpwcsTransportUDP
        options.constraints = constraints
        options.display = localDisplay.videoView
        do {
            publishStream = try session!.createStream(options)
        } catch {
            print(error);
        }
        
        publishStream?.on(.fpwcsStreamStatusPublishing, {rStream in
            self.changeStreamStatus(rStream!)
            self.onPublishing(rStream!)
            self.play()
        });
        
        publishStream?.on(.fpwcsStreamStatusUnpublished, {rStream in
            self.changeStreamStatus(rStream!)
            self.onUnpublished()
            self.leave()
            
        });
        
        publishStream?.on(.fpwcsStreamStatusFailed, {rStream in
            self.changeStreamStatus(rStream!)
            self.onUnpublished()
            self.leave()
        });
        do {
            try publishStream?.publish()
        } catch {
            print(error);
        }
    }
    
    func stopPublish() {
        do {
            try publishStream?.stop()
        } catch {
            print(error);
        }
        publishStream = nil;
    }
    
    func play() {
        if (playStream != nil) {
        }
        let options = FPWCSApi2StreamOptions()
        options.name = roomField.text! + "-" + loginField.text! + roomField.text!
        options.transport = transportSwitch.isOn ? kFPWCSTransport.fpwcsTransportTCP : kFPWCSTransport.fpwcsTransportUDP
        options.display = remoteDisplay.videoView;
        do {
            playStream = try session!.createStream(options)
        } catch {
            print(error)
        }
        playStream?.on(.fpwcsStreamStatusPlaying, {rStream in
            self.changeStreamStatus(rStream!)
            self.onPlaying(rStream!);
        });
        playStream?.on(.fpwcsStreamStatusNotEnoughtBandwidth, {rStream in
            self.changeStreamStatus(rStream!)
        });
        playStream?.on(.fpwcsStreamStatusStopped, {rStream in
            self.changeStreamStatus(rStream!)
            self.onStopped()
        });
        playStream?.on(.fpwcsStreamStatusFailed, {rStream in
            self.changeStreamStatus(rStream!)
            self.onStopped()
        });
        do {
            try playStream?.play()
        } catch {
            print(error);
        }
    }
    
    func stopPlay() {
        do {
            try playStream?.stop();
        } catch {
            print(error);
        }
        playStream = nil;
    }
    
    fileprivate func changeConnectionStatus(status: kFPWCSSessionStatus) {
        statusLabel.text = FPWCSApi2Model.sessionStatus(toString: status);
        switch (status) {
        case .fpwcsSessionStatusFailed:
            statusLabel.textColor = .red
        case .fpwcsSessionStatusEstablished:
            statusLabel.textColor = .green
        default:
            statusLabel.textColor = .darkText
        }
    }
    
    fileprivate func changeStreamStatus(_ stream:FPWCSApi2Stream) {
        statusLabel.text = FPWCSApi2Model.streamStatus(toString: stream.getStatus());
        switch (stream.getStatus()) {
        case .fpwcsStreamStatusFailed:
            statusLabel.textColor = .red;
            switch (stream.getStatusInfo()) {
            case .fpwcsStreamStatusInfoSessionDoesNotExist:
                statusLabel.text = "Actual session does not exist";
            case .fpwcsStreamStatusInfoStoppedByPublisherStop:
                statusLabel.text = "Related publisher stopped its stream or lost connection";
            case .fpwcsStreamStatusInfoSessionNotReady:
                statusLabel.text = "Session is not initialized or terminated on play ordinary stream";
            case .fpwcsStreamStatusInfoRtspStreamNotFound:
                statusLabel.text = "Rtsp stream is not found, agent received '404-Not Found'";
            case .fpwcsStreamStatusInfoFailedToConnectToRtspStream:
                statusLabel.text = "Failed to connect to rtsp stream";
            case .fpwcsStreamStatusInfoFileNotFound:
                statusLabel.text = "File does not exist, check filename";
            case .fpwcsStreamStatusInfoFileHasWrongFormat:
                statusLabel.text = "Failed to play vod stream, this format is not supported";
            case .fpwcsStreamStatusInfoStreamNameAlreadyInUse:
                statusLabel.text = "Server already has a publish stream with the same name, try using different one";
            case .fpwcsStreamStatusInfoTranscodingRequiredButDisabled:
                statusLabel.text = "Transcoding required, but disabled in settings";
            case .fpwcsStreamStatusInfoNoAvailableTranscoders:
                statusLabel.text = "No available transcoders for stream";
            default:
                statusLabel.text = "Unknown Error";
            }
        case .fpwcsStreamStatusPlaying, .fpwcsStreamStatusPublishing:
            statusLabel.textColor = .green;
            break;
        default:
            statusLabel.textColor = .darkText;
            break;
        }
    }
    
    fileprivate func onConnected(_ session:FPWCSApi2Session) {
        onUnpublished();
        onStopped();
    }
    
    
    fileprivate func onDisconnected() {
        self.session = nil
        
        joinButton.setTitle("JOIN", for:.normal)
        checkRequiredFields()
        changeViewState(serverField, true)
        onUnpublished()
        onStopped()
    }
    
    fileprivate func onPublishing(_ stream:FPWCSApi2Stream) {
    }
    
    fileprivate func onUnpublished() {
        self.stopPlay()
    }
    
    fileprivate func onPlaying(_ stream:FPWCSApi2Stream) {
        changeViewState(joinButton, true)
        joinButton.setTitle("LEAVE", for:.normal)
    }
    
    fileprivate func onStopped() {
        self.stopPublish()
    }
    
    fileprivate func changeViewState(_ button:UIView, _ enabled:Bool) {
        button.isUserInteractionEnabled = enabled
        if (enabled) {
            button.alpha = 1.0
        } else {
            button.alpha = 0.5
        }
    }
}

