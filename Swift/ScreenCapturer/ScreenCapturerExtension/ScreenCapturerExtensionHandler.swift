import ReplayKit
import os.log
import WebRTC
import FPWCSApi2Swift

fileprivate class ScreenRTCVideoCapturer: RTCVideoCapturer {
    let kNanosecondsPerSecond = 1000000000

    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
                !CMSampleBufferDataIsReady(sampleBuffer)) {
              return;
            }

            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            if (pixelBuffer == nil) {
                return;
            }

            let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer!)
            let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
                Float64(self.kNanosecondsPerSecond)
            
            let videoFrame = RTCVideoFrame(buffer: rtcPixelBuffer,
                                           rotation: ._0,
                                           timeStampNs: Int64(timeStampNs))
            self.delegate?.capturer(self, didCapture: videoFrame)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}

class ScreenCapturerExtensionHandler: RPBroadcastSampleHandler {
    var streamName = "streamName"
    var wcsUrl = "wss://demo.flashphoner.com:8443/"

    var session:WCSSession?
    var publishStream:WCSStream?
    
    fileprivate var capturer: ScreenRTCVideoCapturer = ScreenRTCVideoCapturer()
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        //#WCS-3207 - Use suite name as group id in entitlements
        let userDefaults = UserDefaults.init(suiteName: "group.com.flashphoner.ScreenCapturerSwift")
        let wcsUrl = userDefaults?.string(forKey: "wcsUrl")
        if  wcsUrl != self.wcsUrl || session?.getStatus() != .fpwcsSessionStatusEstablished {
            session?.disconnect()
            session = nil
        }
        self.wcsUrl = wcsUrl ?? self.wcsUrl
        
        let streamName = userDefaults?.string(forKey: "streamName")
        self.streamName = streamName ?? self.streamName
        
        if (session == nil) {
            let options = FPWCSApi2SessionOptions()
            options.urlServer = self.wcsUrl
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
                self.onDisconnected()
            })
    
            session?.on(.fpwcsSessionStatusFailed, { rSession in
                self.onDisconnected()
            })
            session?.connect()
        }
    }

    func onConnected(_ session:WCSSession) throws {
        let options = FPWCSApi2StreamOptions()
        options.name = streamName
        options.constraints = FPWCSApi2MediaConstraints(audio: false, videoCapturer: capturer);

        try publishStream = session.createStream(options)
        
        publishStream?.on(.fpwcsStreamStatusPublishing, {rStream in
        });
        
        publishStream?.on(.fpwcsStreamStatusUnpublished, {rStream in
            self.session?.disconnect()
        });
        
        publishStream?.on(.fpwcsStreamStatusFailed, {rStream in
            self.session?.disconnect()
        });
        try publishStream?.publish()
    }

    func onDisconnected() {
        self.session = nil
    }
    
    override func broadcastPaused() {
        publishStream?.muteAudio()
        publishStream?.muteVideo()
    }
    
    override func broadcastResumed() {
        publishStream?.unmuteAudio()
        publishStream?.unmuteVideo()
        
    }
    
    override func broadcastFinished() {
        
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        capturer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
    }
}
