public class PaymentInstrument : Decodable {
	public let bin: String?
	public let created: Int64?
	public let expiryMonth: String?
	public let expiryYear: String?
	public let itemId: String?
	public let nickname: String?
	public let paymentToken: String?
	public let scheme: String?
	public let status: String?
	public let suffix: String?

	public static func fromJson(json: String) throws -> PaymentInstrument? {
		try Dto.fromJson(type: PaymentInstrument.self, json: json)
	}
}