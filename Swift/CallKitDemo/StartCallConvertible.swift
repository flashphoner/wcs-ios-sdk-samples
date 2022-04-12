
protocol StartCallConvertible {
    var startCallHandle: String? { get }
    var video: Bool? { get }
}

extension StartCallConvertible {

    var video: Bool? {
        return nil
    }

}
