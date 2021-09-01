public class CardUpdateResponse: Decodable {
	public let fraudResponse: FraudResponse?
	public let itemId: Int?
	public let status: Status?
	public let stepUpToken: String?

	public static func fromJson(json: String) throws -> CardUpdateResponse? {
		try Dto.fromJson(type: CardUpdateResponse.self, json: json)
	}
}