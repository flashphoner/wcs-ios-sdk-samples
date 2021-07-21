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
    
    @IBOutlet weak var broadcastPickerView: UIView?
    @IBOutlet weak var urlField: UITextField!
    
    @IBOutlet weak var publishVideoName: UITextField!
    @IBOutlet weak var publishVideoButton: UIButton!
    @IBOutlet weak var publishAudioName: UITextField!
    @IBOutlet weak var publishAudioButton: UIButton!
    
    var session:WCSSession?
    var publishStream:WCSStream?
    
    var activeTextField : UIView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        
        urlField.delegate = self
        publishVideoName.delegate = self
        publishAudioName.delegate = self
        
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
        pickerView.showsMicrophoneButton = false

        // Theme the picker view to match the white that we want.
        if let button = pickerView.subviews.first as? UIButton {
            button.imageView?.tintColor = UIColor.white
        }

        view.addSubview(pickerView)
        
        /// picker is an instance of RPSystemBroadcastPickerView
        for subviews in pickerView.subviews {
            if let button = subviews as? UIButton {
                button.addTarget(self, action: #selector(pickerAction), for: .touchUpInside)
            }
        }

        self.broadcastPickerView = pickerView
        publishVideoButton.isEnabled = false
        publishVideoButton.titleEdgeInsets = UIEdgeInsets(top: 34, left: 0, bottom: 0, right: 0)

        let centerX = NSLayoutConstraint(item:pickerView,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: publishVideoButton,
                                         attribute: NSLayoutConstraint.Attribute.centerX,
                                         multiplier: 1,
                                         constant: 0);
        self.view.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: pickerView,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                         toItem: publishVideoButton,
                                         attribute: NSLayoutConstraint.Attribute.centerY,
                                         multiplier: 1,
                                         constant: -10);
        self.view.addConstraint(centerY)
        let width = NSLayoutConstraint(item: pickerView,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       relatedBy: NSLayoutConstraint.Relation.equal,
                                       toItem: self.publishVideoButton,
                                       attribute: NSLayoutConstraint.Attribute.width,
                                       multiplier: 1,
                                       constant: 0);
        self.view.addConstraint(width)
        let height = NSLayoutConstraint(item: pickerView,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        relatedBy: NSLayoutConstraint.Relation.equal,
                                        toItem: self.publishVideoButton,
                                        attribute: NSLayoutConstraint.Attribute.height,
                                        multiplier: 1,
                                        constant: 0);
        self.view.addConstraint(height)
    }
    
    @objc func pickerAction() {
        //#WCS-3207 - Use suite name as group id in entitlements
        let userDefaults = UserDefaults.init(suiteName: "group.com.flashphoner.ScreenCapturerSwift")
        userDefaults?.set(urlField.text, forKey: "wcsUrl")
        userDefaults?.set(publishVideoName.text, forKey: "streamName")
        
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
        publishAudioName.inputAccessoryView = toolbar
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
    
    
    @IBAction func publishAudioPressed(_ sender: Any) {
        if (publishAudioButton.title(for: .normal) == "Publish Audio") {
            let options = FPWCSApi2SessionOptions()
                options.urlServer = self.urlField.text
                options.appKey = "defaultApp"
                do {
                    try session = WCSSession(options)
                } catch {
                    print(error)
                }
        
                session?.on(.fpwcsSessionStatusEstablished, { rSession in
                    do {
                        try self.onConnected(self.session!)
                    } catch {
                        print(error)
                    }
                })
        
                session?.on(.fpwcsSessionStatusDisconnected, { rSession in
                    self.onUnpublished()
                })
        
                session?.on(.fpwcsSessionStatusFailed, { rSession in
                    self.onUnpublished()
                })
                session?.connect()
            changeViewState(publishAudioButton, false)
        } else {
            session?.disconnect()
            session = nil
        }
    }
    
    
    func onConnected(_ session:WCSSession) throws {
            let options = FPWCSApi2StreamOptions()
            options.name = publishAudioName.text
            options.constraints = FPWCSApi2MediaConstraints(audio: true, video: false);
            do {
                publishStream = try session.createStream(options)
            } catch {
                print(error);
            }
            
            publishStream?.on(.fpwcsStreamStatusPublishing, {rStream in
                self.onPublishing(rStream!);
            });
            
            publishStream?.on(.fpwcsStreamStatusUnpublished, {rStream in
                self.onUnpublished()
            });
            
            publishStream?.on(.fpwcsStreamStatusFailed, {rStream in
                self.onUnpublished()
            });
            do {
                try publishStream?.publish()
            } catch {
                print(error);
            }
    }
    
    fileprivate func onPublishing(_ stream:FPWCSApi2Stream) {
        publishAudioButton.setTitle("Unpublish Audio", for:.normal)
        changeViewState(publishAudioButton, true)
    }

    fileprivate func onUnpublished() {
        publishAudioButton.setTitle("Publish Audio", for:.normal);
        changeViewState(publishAudioButton, true)
        changeViewState(publishAudioName, true)
    }
}

