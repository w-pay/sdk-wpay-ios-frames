extension Encodable {
	/**
		Converts a SDK data type to a JSON string to be used in a `JavascriptCommand`

		- Throws: `FramesErrors.ENCODE_JSON_ERROR` if there is an error encoding the data to a String.
	 */
	func toJson() throws -> String {
		var data: Data

		do {
			data = try JSONEncoder().encode(self)
		}
		catch {
			throw FramesErrors.ENCODE_JSON_ERROR(message: "Can't convert type to JSON", cause: error, data: self)
		}

		guard let json = String(data: data, encoding: .utf8) else {
			throw FramesErrors.ENCODE_JSON_ERROR(message: "Can't convert JSON data to String", cause: nil, data: self)
		}

		return json
	}
}
