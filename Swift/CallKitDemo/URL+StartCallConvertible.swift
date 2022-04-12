
import Foundation

extension URL: StartCallConvertible {

    private struct Constants {
        static let URLScheme = "speakerbox"
    }

    var startCallHandle: String? {
        guard scheme == Constants.URLScheme else {
            return nil
        }

        return host
    }
    
}
