class Dto {
	public static func fromJson<T: Decodable>(type: T.Type, json: String) throws -> T {
		guard let data = json.data(using: .utf8) else {
			throw FramesErrors.DECODE_JSON_ERROR(message: "Non utf8 string returned", cause: nil, json: json)
		}

		do {
			return try JSONDecoder().decode(type, from: data)
		}
		catch {
			throw FramesErrors.DECODE_JSON_ERROR(message: "Unable to decode JSON", cause: error, json: json)
		}
	}
}
