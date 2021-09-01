public class FraudResponse: Decodable {
	public let fraudClientId: String?
	public let fraudDecision: String?
	public let fraudReasonCd: String?

	public static func fromJson(json: String) throws -> FraudResponse? {
		try Dto.fromJson(type: FraudResponse.self, json: json)
	}
}