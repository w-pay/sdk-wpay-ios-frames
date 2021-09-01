public class EsResponse : Decodable {
	public let code: String?
	public let text: String?

	public static func fromJson(json: String) throws -> EsResponse? {
		try Dto.fromJson(type: EsResponse.self, json: json)
	}
}