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

	func toJson() throws -> String {
		let data: Data = try JSONEncoder().encode(self)

		guard let json = String(data: data, encoding: .utf8) else {
			throw FramesErrors.FATAL_ERROR(message: "Can't convert FramesConfig to JSON")
		}

		return json
	}
}
