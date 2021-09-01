public class CardStepUpResponse: Decodable {
	public let fraudResponse: FraudResponse?
	public let itemId: Int?
	public let status: Status?
	public let stepUpToken: String?

	public static func fromJson(json: String) throws -> CardStepUpResponse? {
		try Dto.fromJson(type: CardStepUpResponse.self, json: json)
	}
}