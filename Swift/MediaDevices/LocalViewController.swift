import UIKit
import FPWCSApi2Swift

extension LocalViewController : UITextFieldDelegate {
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

class LocalViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var audioSend: UISwitch!
    @IBOutlet weak var microphone: UITextField!
    @IBOutlet weak var audioFEC: UISwitch!
    @IBOutlet weak var audioStereo: UISwitch!
    @IBOutlet weak var audioBitrate: UITextField!
    @IBOutlet weak var muteAudio: UISwitch!
    
    @IBOutlet weak var videoSend: UISwitch!
    @IBOutlet weak var camera: UITextField!
    @IBOutlet weak var videoWidth: UITextField!
    @IBOutlet weak var videoHeight: UITextField!
    @IBOutlet weak var videoFPS: UITextField!
    @IBOutlet weak var videoMinBitrate: UITextField!
    @IBOutlet weak var videoMaxBitrate: UITextField!
    @IBOutlet weak var muteVideo: UISwitch!
    @IBOutlet weak var stripCodecs: UITextField!
    
    var viewController: ViewController?
    var microphonePicker = UIPickerView()
    var cameraPicker = UIPickerView()
    var localDevices: FPWCSApi2MediaDeviceList?
    
    var activeTextField : UITextField? = nil
    
    var mediaConstrains:FPWCSApi2MediaConstraints
    var stripCodecsString:String?
    
    required init?(coder: NSCoder) {
        self.mediaConstrains = FPWCSApi2MediaConstraints(audio: true, video: true)
        super.init(coder: coder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        localDevices = WCSApi2.getMediaDevices()
        if (localDevices?.audio?.count ?? 0 > 0) {
            microphone.text = (localDevices?.audio[0] as AnyObject).label
        }
        if (localDevices?.video?.count ?? 0 > 0) {
            camera.text = (localDevices?.video[0] as AnyObject).label
        }

        setupTextFields()
        
        audioBitrate.delegate = self
        videoWidth.delegate = self
        videoHeight.delegate = self
        videoFPS.delegate = self
        videoMinBitrate.delegate = self
        videoMaxBitrate.delegate = self
        stripCodecs.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        microphonePicker.delegate = self
        microphonePicker.dataSource = self
        microphone.inputView = microphonePicker
        
        cameraPicker.delegate = self
        cameraPicker.dataSource = self
        camera.inputView = cameraPicker
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
        
        audioBitrate.inputAccessoryView = toolbar
        videoWidth.inputAccessoryView = toolbar
        videoHeight.inputAccessoryView = toolbar
        videoFPS.inputAccessoryView = toolbar
        videoMinBitrate.inputAccessoryView = toolbar
        videoMaxBitrate.inputAccessoryView = toolbar
        microphone.inputAccessoryView = toolbar
        camera.inputAccessoryView = toolbar
        stripCodecs.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            self.mediaConstrains = toMediaConstraints();
            self.stripCodecsString = stripCodecs.text;
        }
    }
    
    func toMediaConstraints() -> FPWCSApi2MediaConstraints {
        let ret = FPWCSApi2MediaConstraints()
        if (self.audioSend.isOn) {
            let audio = FPWCSApi2AudioConstraints()
            audio.useFEC = audioFEC.isOn
            audio.useStereo = audioStereo.isOn
            audio.bitrate = Int(audioBitrate.text ?? "0") ?? 0
            ret.audio = audio
        }
        if (self.videoSend.isOn) {
            let video = FPWCSApi2VideoConstraints()
            for device in localDevices!.video {
                if ((device as AnyObject).label == camera.text) {
                    video.deviceID = (device as AnyObject).deviceID;
                }
            }
            video.minWidth = Int(videoWidth.text ?? "0") ?? 0
            video.maxWidth = video.minWidth
            video.minHeight = Int(videoHeight.text ?? "0") ?? 0
            video.maxHeight = video.minHeight
            video.minFrameRate = Int(videoFPS.text ?? "0") ?? 0
            video.maxFrameRate = video.minFrameRate
            video.minBitrate = Int(videoMinBitrate.text ?? "0") ?? 0
            video.maxBitrate = Int(videoMaxBitrate.text ?? "0") ?? 0
            ret.video = video;
        }
        return ret;
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView == microphonePicker) {
            return localDevices?.audio.count ?? 0
        } else if (pickerView == cameraPicker) {
            return localDevices?.video.count ?? 0
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (pickerView == microphonePicker) {
            microphone.text = (localDevices?.audio[row] as AnyObject).label
        } else if (pickerView == cameraPicker) {
            camera.text = (localDevices?.video[row] as AnyObject).label
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView == microphonePicker) {
            return (localDevices?.audio[row] as AnyObject).label
        } else if (pickerView == cameraPicker) {
            return (localDevices?.video[row] as AnyObject).label
        }
        return ""
    }
    
    
    @IBAction func muteAudio(_ sender: UISwitch) {
        if (viewController?.publishStream != nil) {
            viewController?.muteAudio(mute: sender.isOn);
        } else {
            sender.setOn(!sender.isOn, animated: false);
        }
    }
    
    @IBAction func muteVideo(_ sender: UISwitch) {
        if (viewController?.publishStream != nil) {
            viewController?.muteVideo(mute: sender.isOn);
        } else {
            sender.setOn(!sender.isOn, animated: false);
        }
    }
}
