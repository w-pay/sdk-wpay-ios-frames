public class CardCaptureResponse: Decodable {
  public let fraudResponse: FraudResponse?
  public let paymentInstrument: PaymentInstrument?
  public let itemId: String?
  public let status: Status?
  public let stepUpToken: String?
  public let threeDSError: ThreeDSError?
  public let message: String?
  public let threeDSToken: String?

  enum PayloadKeys: String, CodingKey {
    case fraudResponse
    case paymentInstrument
    case itemId
    case status
    case stepUpToken
    case errorCode
    case message
    case token
  }

  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CardCaptureResponse.PayloadKeys.self)

    fraudResponse = try? values.decode(FraudResponse.self, forKey: .fraudResponse)
    paymentInstrument = try? values.decode(PaymentInstrument.self, forKey: .paymentInstrument)
    itemId = try? values.decode(String.self, forKey: .itemId)
    status = try? values.decode(Status.self, forKey: .status)
    stepUpToken = try? values.decode(String.self, forKey: .stepUpToken)
    threeDSError = try? values.decode(ThreeDSError.self, forKey: .errorCode)
    message = try? values.decode(String.self, forKey: .message)
    threeDSToken = try? values.decode(String.self, forKey: .token)
  }

  public static func fromJson(json: String) throws -> CardCaptureResponse? {
    try Dto.fromJson(type: CardCaptureResponse.self, json: json)
  }
}





