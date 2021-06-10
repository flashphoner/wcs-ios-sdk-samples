import UIKit
import WebKit
import Foundation

extension WebViewController : UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    self.activeTextField = textField
    return true
  }
    
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    self.activeTextField = nil
    return true
  }
}

extension WebViewController : UITextViewDelegate {
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    self.activeTextField = textView
    return true
  }
    
  func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    self.activeTextField = nil
    return true
  }
}

class WebViewController: UIViewController, WKUIDelegate {

    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var openButton: UIButton!
    lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.applicationNameForUserAgent = "Safari" //Fix for old version of WebSDK
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    var activeTextField : UIView? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields();
        urlField.delegate = self
        
        setupWebView()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    

    func setupWebView() {
        self.webView.layer.borderWidth = 1
        self.view.backgroundColor = .white
        self.view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor
                .constraint(equalTo: self.openButton.safeAreaLayoutGuide.bottomAnchor, constant: 10),
            webView.leftAnchor
                .constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            webView.bottomAnchor
                    .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 10),
            webView.rightAnchor
                    .constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -10)
        ])
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
    }
    
    @objc func doneButtonTapped() {
        view.endEditing(true)
    }
    
    @IBAction func openPressed(_ sender: Any) {
        guard let urlText = urlField.text else {
            return;
        }
        if let url = URL(string: urlText) {
            webView.load(URLRequest(url: url));
        }
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

