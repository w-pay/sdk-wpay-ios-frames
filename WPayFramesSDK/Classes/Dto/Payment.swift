public class Payment: Decodable {
	public let extendedData: ExtendedData?
	public let processorTransactionId: String?
	public let type: String?

	enum Payload: String, CodingKey {
    case extendedData = "ExtendedData"
    case processorTransactionId = "ProcessorTransactionId"
    case type = "Type"
	}

	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: Payload.self)

		extendedData = try? values.decode(ExtendedData.self, forKey: .extendedData)
		processorTransactionId = try? values.decode(String.self, forKey: .processorTransactionId)
		type = try? values.decode(String.self, forKey: .type)
	}

	public static func fromJson(json: String) throws -> Payment? {
		try Dto.fromJson(type: Payment.self, json: json)
	}
}
