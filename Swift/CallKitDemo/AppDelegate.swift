

import UIKit
import PushKit
import FPWCSApi2Swift

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {

    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var window: UIWindow?
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    var providerDelegate: ProviderDelegate?

    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NSLog("CKD - Device token: " + token)
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("CKD - Remote notification error :( \(error)")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NSLog("CKD - Finished launching with options: \(launchOptions)")

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in

            // If granted comes true you can enabled features based on authorization.
            guard granted else { return }

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]

        let viewController = self.window?.rootViewController as? CallKitDemoViewController
        providerDelegate = ProviderDelegate(viewController!)

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            NSLog("CKD - Could not determine start call handle from URL: \(url)")
            return false
        }

//        callManager.startCall(handle: handle)
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let handle = userActivity.startCallHandle else {
            NSLog("CKD - Could not determine start call handle from user activity: \(userActivity)")
            return false
        }

        guard let video = userActivity.video else {
            NSLog("CKD - Could not determine video from user activity: \(userActivity)")
            return false
        }

//        callManager.startCall(handle: handle, video: video)
        return true
    }

    // MARK: PKPushRegistryDelegate

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        if (type == .voIP) {
            let token = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
            NSLog("CKD - Voip token: " + token)
            UserDefaults.standard.set(token, forKey: "voipToken")
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        guard type == .voIP else { return }
        if let id = payload.dictionaryPayload["id"] as? String,
           let uuidString = payload.dictionaryPayload["uuid"] as? String,
           let uuid = UUID(uuidString: uuidString),
           let handle = payload.dictionaryPayload["handle"] as? String
        {
            NSLog("CKD - pushRegistry uuidString: " + uuidString + "; id: " + id + "; handle: " + handle)
            providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, completion: nil)
        }
    }
}
