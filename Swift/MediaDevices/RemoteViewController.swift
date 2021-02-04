import UIKit
import FPWCSApi2Swift

extension RemoteViewController : UITextFieldDelegate {
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

extension RemoteViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        (viewController as? ViewController)?.remoteMediaConstrains = self.toMediaConstraints();
    }
}

class RemoteViewController: UIViewController {
    
    var activeTextField : UITextField? = nil
    
    @IBOutlet weak var playVideo: UISwitch!
    @IBOutlet weak var videoWidth: UITextField!
    @IBOutlet weak var videoHeight: UITextField!
    @IBOutlet weak var videoBitrate: UITextField!
    @IBOutlet weak var videoQuality: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.delegate = self

        setupTextFields()
        
        videoWidth.delegate = self
        videoHeight.delegate = self
        videoBitrate.delegate = self
        videoQuality.delegate = self

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
        
        videoWidth.inputAccessoryView = toolbar
        videoHeight.inputAccessoryView = toolbar
        videoBitrate.inputAccessoryView = toolbar
        videoQuality.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    func toMediaConstraints() -> FPWCSApi2MediaConstraints {
        let ret = FPWCSApi2MediaConstraints();
        ret.audio = FPWCSApi2AudioConstraints();
        if (playVideo.isOn) {
            let video = FPWCSApi2VideoConstraints();
            video.minWidth = Int(videoWidth.text ?? "0") ?? 0
            video.maxWidth = video.minWidth
            video.minHeight = Int(videoHeight.text ?? "0") ?? 0
            video.maxHeight = video.minWidth
            video.bitrate = Int(videoBitrate.text ?? "0") ?? 0
            video.quality = Int(videoQuality.text ?? "0") ?? 0
            ret.video = video;
        }
        return ret;
    }
}
