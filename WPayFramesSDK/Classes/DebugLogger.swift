public class DebugLogger : FramesViewLogger {
	public init() {

	}

	public func log(tag: String, message: String) {
		print("[\(tag)] \(message)")
	}
}
