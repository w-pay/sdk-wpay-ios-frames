/*
  Helper to create an instance of `CreateActionCommand` with some type safety.
 */
public class ActionType {
	private let type: String
	private let payload: Encodable?

	public init(type: String, payload: Encodable? = nil) {
		self.type = type
		self.payload = payload
	}

	/**
	 - Returns: A `CreateActionCommand`
	 - Throws: `FramesErrors.ENCODE_JSON_ERROR` if there is an error encoding the payload to a String.
	 */
	public func toCommand(name: String) throws -> CreateActionCommand {
		CreateActionCommand(name: name, action: type, payload: try payload?.toJson())
	}
}

public class CaptureCard : ActionType {
	private class ThreeDSPayload : Encodable {
		let env3DS: ThreeDSEnv

		enum ThreeDSKeys: String, CodingKey {
			case env3DS
			case requires3DS
		}

		init(env3DS: ThreeDSEnv) {
			self.env3DS = env3DS
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: ThreeDSKeys.self)
			try container.encode(true, forKey: .requires3DS)
			try container.encode(env3DS.rawValue, forKey: .env3DS)
		}
	}

	public class Payload : Encodable {
		public let verify: Bool
		public let save: Bool
		public let useEverydayPay: Bool
		public let env3DS: ThreeDSEnv?

		enum PayloadKeys: String, CodingKey {
			case verify
			case save
			case threeDS
			case useEverydayPay
		}

		public init(
			verify: Bool,
			save: Bool,
			useEverydayPay: Bool = false,
			env3DS: ThreeDSEnv? = nil
		) {
			self.verify = verify
			self.save = save
			self.useEverydayPay = useEverydayPay
			self.env3DS = env3DS
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: PayloadKeys.self)
			try container.encode(verify, forKey: .verify)
			try container.encode(save, forKey: .save)
			try container.encode(useEverydayPay, forKey: .useEverydayPay)

			if let env = env3DS {
				try container.encode(ThreeDSPayload(env3DS: env), forKey: .threeDS)
			}
		}
	}

	public init(payload: Payload?) {
		super.init(type: "CaptureCard", payload: payload)
	}
}

public class StepUp : ActionType {
	public class Payload : Encodable {
		public let paymentInstrumentId: String
		public let scheme: String

		public init(paymentInstrumentId: String, scheme: String) {
			self.paymentInstrumentId = paymentInstrumentId
			self.scheme = scheme
		}
	}

	public init(payload: Payload?) {
		super.init(type: "StepUp", payload: payload)
	}
}

public class UpdateCard : ActionType {
	public class Payload : Encodable {
		public let paymentInstrumentId: String
		public let scheme: String

		public init(paymentInstrumentId: String, scheme: String) {
			self.paymentInstrumentId = paymentInstrumentId
			self.scheme = scheme
		}
	}

	public init(payload: Payload?) {
		super.init(type: "UpdateCard", payload: payload)
	}
}

public class ValidateCard : ActionType {
	public class Payload : Encodable {
		public let sessionId: String
		public let env3DS: ThreeDSEnv
		public let acsWindowSize: AcsWindowSize

		enum PayloadKeys: String, CodingKey {
			case sessionId
			case threeDS
		}

		public init(sessionId: String, env3DS: ThreeDSEnv, acsWindowSize: AcsWindowSize = AcsWindowSize.ACS_250x400) {
			self.sessionId = sessionId
			self.env3DS = env3DS
			self.acsWindowSize = acsWindowSize
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: PayloadKeys.self)

			try container.encode(sessionId, forKey: .sessionId)
			try container.encode(
				ThreeDSPayload(threeDSEnv: env3DS, windowSize: acsWindowSize),
				forKey: .threeDS
			)
		}
	}

	private class ThreeDSPayload : Encodable {
		private let threeDSEnv: ThreeDSEnv
		private let windowSize: AcsWindowSize

		enum PayloadKeys: String, CodingKey {
			case env
			case consumerAuthenticationInformation
		}

		init(threeDSEnv: ThreeDSEnv, windowSize: AcsWindowSize) {
			self.threeDSEnv = threeDSEnv
			self.windowSize = windowSize
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: PayloadKeys.self)

			try container.encode(threeDSEnv.rawValue, forKey: .env)
			try container.encode(
				ConsumerAuthenticationInformationPayload(windowSize: windowSize),
				forKey: .consumerAuthenticationInformation
			)
		}
	}

	private class ConsumerAuthenticationInformationPayload : Encodable {
		private let windowSize: AcsWindowSize

		enum PayloadKeys: String, CodingKey {
			case acsWindowSize
		}

		init(windowSize: AcsWindowSize) {
			self.windowSize = windowSize
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: PayloadKeys.self)

			try container.encode(windowSize.rawValue, forKey: .acsWindowSize)
		}
	}

	public init(payload: Payload?) {
		super.init(type: "ValidateCard", payload: payload)
	}
}

public class ValidatePayment : ActionType {
	public init() {
		super.init(type: "ValidatePayment")
	}
}

public enum AcsWindowSize : String {
	case ACS_250x400 = "01"
	case ACS_390x400 = "02"
	case ACS_500x600 = "03"
	case ACS_600x400 = "04"
	case ACS_FULL_PAGE = "05"
}