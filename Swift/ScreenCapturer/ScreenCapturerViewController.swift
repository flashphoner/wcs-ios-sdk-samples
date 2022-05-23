import UIKit
import FPWCSApi2Swift
import Foundation
import ReplayKit

extension ScreenCapturerViewController : UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    self.activeTextField = textField
    return true
  }
    
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    self.activeTextField = nil
    return true
  }
}

extension ScreenCapturerViewController : UITextViewDelegate {
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    self.activeTextField = textView
    return true
  }
    
  func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    self.activeTextField = nil
    return true
  }
}

class ScreenCapturerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    static let kStartBroadcastButtonTitle = "Start Broadcast"
    static let kInProgressBroadcastButtonTitle = "Broadcasting"
    static let kStopBroadcastButtonTitle = "Stop Broadcast"
    
    static let kBroadcastExtensionBundleId = "com.flashphoner.ios.ScreenCapturer.ScreenCapturerExtension"
    
    @IBOutlet weak var broadcastPickerView: RPSystemBroadcastPickerView?
    @IBOutlet weak var urlField: UITextField!
    
    @IBOutlet weak var publishVideoName: UITextField!
    @IBOutlet weak var publishVideoButton: UIButton!
    @IBOutlet weak var systemOrMicSwitch: UISwitch!
    
    var session:WCSSession?
    var publishStream:WCSStream?
    
    var activeTextField : UIView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        
        urlField.delegate = self
        publishVideoName.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: UIScreen.main, queue: OperationQueue.main) { (notification) in
            if self.broadcastPickerView != nil  {
                let isCaptured = UIScreen.main.isCaptured
                let title = isCaptured ? ScreenCapturerViewController.kInProgressBroadcastButtonTitle : ScreenCapturerViewController.kStartBroadcastButtonTitle
                self.publishVideoButton.setTitle(title, for: .normal)
            }
        }
        
        setupPickerView()
    }
    
    func setupPickerView() {
        let pickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0,
                                                                   y: 0,
                                                                   width: view.bounds.width,
                                                                   height: 80))
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.preferredExtension = ScreenCapturerViewController.kBroadcastExtensionBundleId
        pickerView.showsMicrophoneButton = systemOrMicSwitch.isOn

        // Theme the picker view to match the white that we want.
        if let button = pickerView.subviews.first as? UIButton {
            button.imageView?.tintColor = UIColor.white
        }

        view.addSubview(pickerView)

        self.broadcastPickerView = pickerView
    }
    
    @IBAction func broadcastBtnPressed(_ sender: Any) {
        guard let pickerView = self.broadcastPickerView else {
            return
        }
            
        pickerView.showsMicrophoneButton = systemOrMicSwitch.isOn

        let userDefaults = UserDefaults.init(suiteName: "group.com.flashphoner.ScreenCapturerSwift")
        userDefaults?.set(urlField.text, forKey: "wcsUrl")
        userDefaults?.set(publishVideoName.text, forKey: "streamName")
        userDefaults?.set(systemOrMicSwitch.isOn, forKey: "useMic")
        
        for view in pickerView.subviews {
            if let button = view as? UIButton {
                button.sendActions(for: .touchUpInside)
            }
        }
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
        publishVideoName.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
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

