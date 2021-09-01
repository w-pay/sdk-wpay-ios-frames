public class Status: Decodable {
	public let auditID: String?
	public let error: StatusError?
	public let esResponse: EsResponse?
	public let responseCode: String?
	public let responseText: String?
	public let txnTime: Int64?

	enum PayloadKeys: String, CodingKey {
		case auditID
		case error
		case esResponse
		case responseCode
		case responseText
		case txnTime
	}

	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: Status.PayloadKeys.self)

		auditID = try? values.decode(String.self, forKey: .auditID)
		error = try? values.decode(StatusError.self, forKey: .error)
		esResponse = try? values.decode(EsResponse.self, forKey: .esResponse)
		responseCode = try? values.decode(String.self, forKey: .responseCode)
		responseText = try? values.decode(String.self, forKey: .responseText)
		txnTime = try? values.decode(Int64.self, forKey: .txnTime)
	}

	public static func fromJson(json: String) throws -> Status? {
		try Dto.fromJson(type: Status.self, json: json)
	}
}