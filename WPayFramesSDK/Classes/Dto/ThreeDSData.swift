public class ThreeDSData : Decodable {
	public let actionCode: String?
	public let errorDescription: String?
	public let errorNumber: Int?
	public let payment: Payment?
	public let validated: Bool?

	enum PayloadKeys : String, CodingKey {
		case actionCode = "ActionCode"
		case errorDescription = "ErrorDescription"
		case errorNumber = "ErrorNumber"
		case payment = "Payment"
		case validated = "Validated"
	}

	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: PayloadKeys.self)

		actionCode = try? values.decode(String.self, forKey: .actionCode)
		errorDescription = try? values.decode(String.self, forKey: .errorDescription)
		errorNumber = try? values.decode(Int.self, forKey: .errorNumber)
		payment = try? values.decode(Payment.self, forKey: .payment)
		validated = try? values.decode(Bool.self, forKey: .validated)
	}

	public static func fromJson(json: String) throws -> ThreeDSData? {
		try Dto.fromJson(type: ThreeDSData.self, json: json)
	}
}
