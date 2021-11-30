public class ChallengeResponse: Decodable, Encodable {
	public let instrumentId: String?
	public let reference: String?
	public let token: String?
	public let type: String?

	public static func fromJson(json: String) throws -> ChallengeResponse? {
		try Dto.fromJson(type: ChallengeResponse.self, json: json)
	}
}