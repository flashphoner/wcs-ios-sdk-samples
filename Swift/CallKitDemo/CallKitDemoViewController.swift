import UIKit
import FPWCSApi2Swift
import Foundation
import ReplayKit

extension CallKitDemoViewController : UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    self.activeTextField = textField
    return true
  }
    
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    self.activeTextField = nil
    return true
  }
}

extension CallKitDemoViewController : UITextViewDelegate {
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    self.activeTextField = textView
    return true
  }
    
  func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    self.activeTextField = nil
    return true
  }
}

class CallKitDemoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var wcsUrl: UITextField!
    
    @IBOutlet weak var sipLogin: UITextField!
    @IBOutlet weak var sipAuthName: UITextField!
    @IBOutlet weak var sipPassword: UITextField!
    @IBOutlet weak var sipDomain: UITextField!
    @IBOutlet weak var sipOutboundProxy: UITextField!
    @IBOutlet weak var sipPort: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    var activeTextField : UIView? = nil
   
    var callId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        
        wcsUrl.delegate = self
        sipLogin.delegate = self
        sipAuthName.delegate = self
        sipPassword.delegate = self
        sipDomain.delegate = self
        sipOutboundProxy.delegate = self
        sipPort.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        loadFields()

        let session = appDelegate.providerDelegate?.session
        if (session?.getStatus() == kFPWCSSessionStatus.fpwcsSessionStatusRegistered) {
            toLogoutState()
        } else if (session != nil) {
            processSession(session!)
            toLoadingState()
        } else {
            toLoginState()
        }
    }
    
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        if (loginButton.title(for: .normal) == "Login") {
            let options = FPWCSApi2SessionOptions()
            options.urlServer = wcsUrl.text
            
            options.keepAlive = true
            
            options.sipRegisterRequired = true
            options.sipLogin = sipLogin.text
            options.sipAuthenticationName = sipAuthName.text
            options.sipPassword = sipPassword.text
            options.sipDomain = sipDomain.text
            options.sipOutboundProxy = sipOutboundProxy.text
            options.sipPort = Int(sipPort.text ?? "5060") as NSNumber?
            
            let userDefaults = UserDefaults.standard
            options.noticationToken = userDefaults.string(forKey: "voipToken")
            options.appId = "com.flashphoner.ios.CallKitDemoSwift"

            options.appKey = "defaultApp"

            do {
                let session = try FPWCSApi2.createSession(options)

                processSession(session)

                appDelegate.providerDelegate?.setSession(session)
                session.connect()
            } catch {
                print(error)
            }
            
            toLoadingState()
        } else {
            appDelegate.providerDelegate?.session?.disconnect()
        }
    }
    
    private func processSession(_ session: FPWCSApi2Session) {
        session.on(kFPWCSSessionStatus.fpwcsSessionStatusEstablished, callback: { rSession in
            NSLog("Session established")
            self.saveFields(rSession?.getAuthToken())
            self.toLogoutState()
        })
        
        session.on(kFPWCSSessionStatus.fpwcsSessionStatusRegistered, callback: { rSession in
            NSLog("Session registered")
            self.toLogoutState()
        })
    
        session.on(kFPWCSSessionStatus.fpwcsSessionStatusDisconnected, callback: { rSession in
            NSLog("Session disconnected")
            self.toLoginState()
            self.appDelegate.providerDelegate?.hangupAll()
        })

        session.on(kFPWCSSessionStatus.fpwcsSessionStatusFailed, callback: { rSession in
            self.toLoginState()
        })
    }
    
    
    @IBAction func callAction(_ sender: Any) {
        guard let id = callId else {
            return
        }
        let providerDelegate = self.appDelegate.providerDelegate
        if (callButton.title(for: .normal) == "Hangup") {
            providerDelegate?.hangup(id)
        } else if (callButton.title(for: .normal) == "Answer") {
            providerDelegate?.answer(id)
        }
    }
    
    @IBAction func fieldChanged(_ sender: Any) {
        if (canLogin()) {
            changeViewState(loginButton, true)
        }
    }
    
    func toLogoutState() {
        changeViewState(wcsUrl, false)
        changeViewState(sipLogin, false)
        changeViewState(sipAuthName, false)
        changeViewState(sipPassword, false)
        changeViewState(sipDomain, false)
        changeViewState(sipOutboundProxy, false)
        changeViewState(sipPort, false)

        changeViewState(loginButton, true)
        loginButton.setTitle("Disconnect", for: .normal)
        
        toNoCallState()
    }
    
    func toLoadingState() {
        changeViewState(wcsUrl, false)
        changeViewState(sipLogin, false)
        changeViewState(sipAuthName, false)
        changeViewState(sipPassword, false)
        changeViewState(sipDomain, false)
        changeViewState(sipOutboundProxy, false)
        changeViewState(sipPort, false)

        changeViewState(loginButton, false)
        loginButton.setTitle("Loading...", for: .normal)
    }
    
    func toLoginState() {
        changeViewState(wcsUrl, true)
        changeViewState(sipLogin, true)
        changeViewState(sipAuthName, true)
        changeViewState(sipPassword, true)
        changeViewState(sipDomain, true)
        changeViewState(sipOutboundProxy, true)
        changeViewState(sipPort, true)
        
        changeViewState(loginButton, canLogin())
        loginButton.setTitle("Login", for: .normal)
        
        toNoCallState()
    }
    
    func canLogin() -> Bool {
        return wcsUrl.text != nil &&
            sipLogin.text != nil &&
        sipAuthName.text != nil &&
        sipPassword.text != nil &&
        sipDomain.text != nil &&
        sipOutboundProxy.text != nil &&
        sipPort.text != nil
    }
    
    func loadFields() {
        let userDefaults = UserDefaults.standard
        sipLogin.text = userDefaults.string(forKey: "sipLogin")
        sipAuthName.text = userDefaults.string(forKey: "sipAuthName")
        sipPassword.text = userDefaults.string(forKey: "sipPassword")
        sipDomain.text = userDefaults.string(forKey: "sipDomain")
        sipOutboundProxy.text = userDefaults.string(forKey: "sipOutboundProxy")
        sipPort.text = userDefaults.string(forKey: "sipPort")
    }
    
    func saveFields(_ authToken: String?) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(wcsUrl.text, forKey: "wcsUrl")
        userDefaults.set(sipLogin.text, forKey: "sipLogin")
        userDefaults.set(sipAuthName.text, forKey: "sipAuthName")
        userDefaults.set(sipPassword.text, forKey: "sipPassword")
        userDefaults.set(sipDomain.text, forKey: "sipDomain")
        userDefaults.set(sipOutboundProxy.text, forKey: "sipOutboundProxy")
        userDefaults.set(sipPort.text, forKey: "sipPort")
        if (authToken != nil) {
            userDefaults.set(authToken, forKey: "authToken")
            print("Save token " + authToken!)
        }
        userDefaults.synchronize()
    }
    
    func toHangupState(_ callId: String) {
        self.callId = callId
        changeViewState(callButton, true)
        callButton.setTitle("Hangup", for: .normal)
    }
    
    func toAnswerState(_ callId: String) {
        self.callId = callId
        
        changeViewState(callButton, true)
        callButton.setTitle("Answer", for: .normal)
    }
    
    func toNoCallState() {
        self.callId = nil
        changeViewState(callButton, false)
        callButton.setTitle("No Calls", for: .normal)
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
        
        wcsUrl.inputAccessoryView = toolbar
        sipLogin.inputAccessoryView = toolbar
        sipAuthName.inputAccessoryView = toolbar
        sipPassword.inputAccessoryView = toolbar
        sipDomain.inputAccessoryView = toolbar
        sipOutboundProxy.inputAccessoryView = toolbar
        sipPort.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    fileprivate func changeViewState(_ view:UIView, _ enabled:Bool) {
        view.isUserInteractionEnabled = enabled;
        if (enabled) {
            view.alpha = 1.0;
        } else {
            view.alpha = 0.2;
        }
    }
}

