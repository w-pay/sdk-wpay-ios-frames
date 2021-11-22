public class CardCaptureResponse: Decodable {
  public let fraudResponse: FraudResponse?
  public let paymentInstrument: PaymentInstrument?
  public let itemId: String?
  public let status: Status?
  public let stepUpToken: String?
  public let threeDSError: ThreeDSError?
  public let message: String?
  public let threeDSToken: String?

  public static func fromJson(json: String) throws -> CardCaptureResponse? {
    try Dto.fromJson(type: CardCaptureResponse.self, json: json)
  }
}





