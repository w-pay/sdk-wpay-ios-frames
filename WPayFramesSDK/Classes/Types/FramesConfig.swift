public class FramesConfig: Encodable {
	private let apiKey: String
	private let authToken: String
	private let apiBase: String
	private let logLevel: Int

	public init(apiKey: String, authToken: String, apiBase: String, logLevel: LogLevel = LogLevel.ERROR) {
		self.apiKey = apiKey
		self.authToken = authToken
		self.apiBase = apiBase
		self.logLevel = logLevel.rawValue
	}
}
