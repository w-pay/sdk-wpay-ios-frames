public class ValidateCardResponse: Decodable {
	public let challengeResponse: ChallengeResponse?

	init(challengeResponse: ChallengeResponse?) {
		self.challengeResponse = challengeResponse
	}

	public static func fromJson(json: String) throws -> ValidateCardResponse? {
		try Dto.fromJson(type: ValidateCardResponse.self, json: json)
	}
}
