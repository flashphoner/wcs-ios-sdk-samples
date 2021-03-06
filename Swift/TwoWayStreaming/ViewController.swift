import UIKit
import FPWCSApi2Swift

extension ViewController : UITextFieldDelegate {
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

class ViewController: UIViewController {

    var lightOn = true
    var session:WCSSession?
    var publishStream:WCSStream?
    var playStream:WCSStream?
    
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var connectStatus: UILabel!
    @IBOutlet weak var connectButton: UIButton!

    @IBOutlet weak var publishName: UITextField!
    @IBOutlet weak var publishStatus: UILabel!
    @IBOutlet weak var publishButton: UIButton!

    @IBOutlet weak var playName: UITextField!
    @IBOutlet weak var playStatus: UILabel!
    @IBOutlet weak var playButton: UIButton!

    @IBOutlet weak var localDisplay: WebRTCView!
    @IBOutlet weak var remoteDisplay: WebRTCView!
    
    var activeTextField : UITextField? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        onDisconnected();
        
        urlField.delegate = self
        publishName.delegate = self
        playName.delegate = self
        
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
        publishName.inputAccessoryView = toolbar
        playName.inputAccessoryView = toolbar
        
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    @IBAction func connectPressed(_ sender: Any) {
        changeViewState(connectButton, false)
        if (connectButton.title(for: .normal) == "CONNECT") {
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
    
    @IBAction func publishPressed(_ sender: Any) {
        changeViewState(publishButton,false)
        if (publishButton.title(for: .normal) == "PUBLISH") {
            let options = FPWCSApi2StreamOptions()
            options.name = publishName.text
            options.display = localDisplay.videoView
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
        } else {
            do {
                try publishStream?.stop();
            } catch {
                print(error);
            }
            
        }
        
    }
    
    @IBAction func playPressed(_ sender: Any) {
        changeViewState(playButton,false)
        if (playButton.title(for: .normal) == "PLAY") {
            let options = FPWCSApi2StreamOptions()
            options.name = playName.text;
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
        } else{
            do {
                try playStream?.stop();
            } catch {
                print(error);
            }
        }
    }
    
    fileprivate func changeConnectionStatus(status: kFPWCSSessionStatus) {
        connectStatus.text = FPWCSApi2Model.sessionStatus(toString: status);
        switch (status) {
            case .fpwcsSessionStatusFailed:
                connectStatus.textColor = .red
            case .fpwcsSessionStatusEstablished:
                connectStatus.textColor = .green
            default:
                connectStatus.textColor = .darkText
        }
    }
    
    fileprivate func changeStreamStatus(_ stream:FPWCSApi2Stream) {
        var view:UILabel;
        if (stream.isPublished()) {
            view = publishStatus;
        } else {
            view = playStatus;
        }
        view.text = FPWCSApi2Model.streamStatus(toString: stream.getStatus());
        switch (stream.getStatus()) {
            case .fpwcsStreamStatusFailed:
                view.textColor = .red;
                switch (stream.getStatusInfo()) {
                    case .fpwcsStreamStatusInfoSessionDoesNotExist:
                        view.text = "Actual session does not exist";
                    case .fpwcsStreamStatusInfoStoppedByPublisherStop:
                        view.text = "Related publisher stopped its stream or lost connection";
                    case .fpwcsStreamStatusInfoSessionNotReady:
                        view.text = "Session is not initialized or terminated on play ordinary stream";
                    case .fpwcsStreamStatusInfoRtspStreamNotFound:
                        view.text = "Rtsp stream is not found, agent received '404-Not Found'";
                    case .fpwcsStreamStatusInfoFailedToConnectToRtspStream:
                        view.text = "Failed to connect to rtsp stream";
                    case .fpwcsStreamStatusInfoFileNotFound:
                        view.text = "File does not exist, check filename";
                    case .fpwcsStreamStatusInfoFileHasWrongFormat:
                        view.text = "Failed to play vod stream, this format is not supported";
                    case .fpwcsStreamStatusInfoStreamNameAlreadyInUse:
                        view.text = "Server already has a publish stream with the same name, try using different one";
                    case .fpwcsStreamStatusInfoTranscodingRequiredButDisabled:
                        view.text = "Transcoding required, but disabled in settings";
                    case .fpwcsStreamStatusInfoNoAvailableTranscoders:
                        view.text = "No available transcoders for stream";
                    default:
                        view.text = "Unknown Error";
                }
            case .fpwcsStreamStatusPlaying, .fpwcsStreamStatusPublishing:
                view.textColor = .green;
                break;
            default:
                view.textColor = .darkText;
                break;
        }
    }
    
    fileprivate func onConnected(_ session:FPWCSApi2Session) {
        connectButton.setTitle("DISCONNECT", for:.normal)
        changeViewState(connectButton, true);
        onUnpublished();
        onStopped();
    }

    
    fileprivate func onDisconnected() {
        connectButton.setTitle("CONNECT", for:.normal);
        changeViewState(connectButton, true);
        changeViewState(urlField, true);
        onUnpublished();
        onStopped();
    }
    
    fileprivate func onPublishing(_ stream:FPWCSApi2Stream) {
        publishButton.setTitle("STOP", for:.normal);
        changeViewState(publishButton, true);
    }

    fileprivate func onUnpublished() {
        publishButton.setTitle("PUBLISH", for:.normal);
        if (session?.getStatus() == kFPWCSSessionStatus.fpwcsSessionStatusEstablished) {
            changeViewState(publishButton, true)
            changeViewState(publishName, true)
        } else {
            changeViewState(publishButton, false)
            changeViewState(publishName, false)
        }
//        [FPWCSApi2 releaseLocalMedia:_localDisplay]
//        [_localDisplay renderFrame:nil]
    }

    fileprivate func onPlaying(_ stream:FPWCSApi2Stream) {
        playButton.setTitle("STOP", for:.normal)
        changeViewState(playButton, true)
    }

    fileprivate func onStopped() {
        playButton.setTitle("PLAY", for:.normal)
        if (session?.getStatus() == kFPWCSSessionStatus.fpwcsSessionStatusEstablished) {
            changeViewState(playButton, true)
            changeViewState(playName, true)
        } else {
            changeViewState(playButton, false)
            changeViewState(playName, false)
        }
//        [_remoteDisplay renderFrame:nil];
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

