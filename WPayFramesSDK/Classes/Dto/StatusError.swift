public class StatusError: Decodable {
	public let context: String?
	public let correction: String?
	public let description: String?

	public static func fromJson(json: String) throws -> StatusError? {
		try Dto.fromJson(type: StatusError.self, json: json)
	}
}