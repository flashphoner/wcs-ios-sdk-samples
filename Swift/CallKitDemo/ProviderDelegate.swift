/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	CallKit provider delegate class, which conforms to CXProviderDelegate protocol
*/

import Foundation
import UIKit
import CallKit
import FPWCSApi2Swift

final class ProviderDelegate: NSObject, CXProviderDelegate {

    private var viewController: CallKitDemoViewController
    private(set) var session: FPWCSApi2Session? = nil
    private var actionCall: CXAnswerCallAction? = nil
    private var needToAnswer = false
    private let provider: CXProvider
    private var currentCall: FPWCSApi2Call? = nil

    init(_ viewController: CallKitDemoViewController) {
        self.viewController = viewController
        provider = CXProvider(configuration: type(of: self).providerConfiguration)

        super.init()
        
        
        let userDefaults = UserDefaults.standard
        let authToken = userDefaults.string(forKey: "authToken")
        NSLog("CKD - Loaded token " + (authToken ?? ""))
        if (authToken != nil) {
            let options = FPWCSApi2SessionOptions()
            options.urlServer = userDefaults.string(forKey: "wcsUrl")
            options.keepAlive = true
            options.authToken = authToken
            options.appKey = "defaultApp"
            do {
                let s = try FPWCSApi2.createSession(options)
                
                s.connect()
                
                self.setSession(s)
            } catch {
                print(error)
            }
        }

        provider.setDelegate(self, queue: nil)
    }

    /// The app's provider configuration, representing its CallKit capabilities
    static var providerConfiguration: CXProviderConfiguration {
        let localizedName = NSLocalizedString("CallKitDemo", comment: "Call Kit Demo for WCS")
        let providerConfiguration = CXProviderConfiguration(localizedName: localizedName)

        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.maximumCallsPerCallGroup = 1

        providerConfiguration.supportedHandleTypes = [.phoneNumber]

        if let iconMaskImage = UIImage(named: "IconMask") {
            providerConfiguration.iconTemplateImageData = iconMaskImage.pngData()
        }

        providerConfiguration.ringtoneSound = "Ringtone.caf"

        return providerConfiguration
    }
    
    func setSession(_ session: FPWCSApi2Session) {
        self.session = session;
        
        
        session.onIncomingCallCallback({ rCall in
            
            guard let call = rCall else {
                return
            }
                        
            call.on(kFPWCSCallStatus.fpwcsCallStatusFinish, callback: {rCall in
                self.viewController.toNoCallState()

                guard let uuid = rCall?.getUuid() else {
                    return
                }
                self.provider.reportCall(with: uuid, endedAt: Date(), reason: .remoteEnded)
            })
            let id = call.getId()
            
            NSLog("CKD - session.onIncomingCallCallback. wcsCallId: " + (id ?? ""))

            
            call.on(kFPWCSCallStatus.fpwcsCallStatusEstablished, callback: {rCall in
                self.viewController.toHangupState(call.getId())
            })
            
            self.viewController.toAnswerState(call.getId())
            self.currentCall = call
            self.actionCall?.fulfill()
        })
    }
    
    func hangupAll() {
        provider.invalidate()
    }
    
    func hangup(_ callId: String) {
        guard let call = self.session?.getCall(callId) else {
            return
        }
        call.hangup()
        self.provider.reportCall(with: call.getUuid(), endedAt: Date(), reason: .remoteEnded)
    }
    
    func answer(_ callId: String) {
        guard let call = self.session?.getCall(callId) else {
            return
        }
        let callController = CXCallController()
        let answerCallAction = CXAnswerCallAction(call: call.getUuid())
        callController.request(CXTransaction(action: answerCallAction),
                                             completion: { error in
                                                 if let error = error {
                                                     print("Error: \(error)")
                                                 } else {
                                                     print("Success")
                                                 }
                                             })
    }

    // MARK: Incoming Calls
    func reportIncomingCall(uuid: UUID, handle: String, completion: ((NSError?) -> Void)? = nil) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = false
        
        
        //Need for execute didActivate AudioSession on start app
        DispatchQueue.global().sync {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.mixWithOthers)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.none)
                try AVAudioSession.sharedInstance().setMode(AVAudioSession.Mode.voiceChat)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch (let error){
                print("audio session error: \(error)")
            }
        }
        
        
        NSLog("CKD - reportNewIncomingCall " + uuid.uuidString)
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            completion?(error as NSError?)
        }
    }
    
    // MARK: CXProviderDelegate
    func providerDidReset(_ provider: CXProvider) {
        NSLog("CKD - Provider did reset")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("CKD - CXStartCallAction - does not implement")
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NSLog("CKD - CXAnswerCallAction: " + action.callUUID.uuidString)

        guard let call = self.session?.getCallBy(action.callUUID) else {
            if (self.session?.getStatus() == kFPWCSSessionStatus.fpwcsSessionStatusDisconnected || self.session?.getStatus() == kFPWCSSessionStatus.fpwcsSessionStatusFailed) {
                self.session?.connect()
            }
            self.actionCall = action
            return
        }
        self.currentCall = call
        action.fulfill(withDateConnected: NSDate.now)
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("CKD - CXEndCallAction: " + action.callUUID.uuidString)
        guard let call = session?.getCallBy(action.callUUID) else {
            action.fulfill()
            return
        }
        self.hangup(call.getId())
        action.fulfill()
            
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("CKD - CXSetHeldCallAction")
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("CKD - CXAction")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("CKD - didActivate \(#function)")
        currentCall?.answer()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        NSLog("CKD - didDeactivate \(#function)")
    }
}
