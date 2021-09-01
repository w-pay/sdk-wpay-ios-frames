public class ExtendedData : Decodable {
	public let amount: String?
	public let cAVV: String?
	public let currencyCode: String?
	public let eCIFlag: String?
	public let pAResStatus: String?
	public let signatureVerification: String?
	public let threeDSVersion: String?

	enum PayloadKeys : String, CodingKey {
		case amount = "Amount"
		case cAVV = "CAVV"
		case currencyCode = "CurrencyCode"
		case eCIFlag = "ECIFlag"
		case pAResStatus = "PAResStatus"
		case signatureVerification = "SignatureVerification"
		case threeDSVersion = "ThreeDSVersion"
	}

	public required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: PayloadKeys.self)

		amount = try? values.decode(String.self, forKey: .amount)
		cAVV = try? values.decode(String.self, forKey: .cAVV)
		currencyCode = try? values.decode(String.self, forKey: .currencyCode)
		eCIFlag = try? values.decode(String.self, forKey: .eCIFlag)
		pAResStatus = try? values.decode(String.self, forKey: .pAResStatus)
		signatureVerification = try? values.decode(String.self, forKey: .signatureVerification)
		threeDSVersion = try? values.decode(String.self, forKey: .threeDSVersion)
	}

	public static func fromJson(json: String) throws -> ExtendedData? {
		try Dto.fromJson(type: ExtendedData.self, json: json)
	}
}