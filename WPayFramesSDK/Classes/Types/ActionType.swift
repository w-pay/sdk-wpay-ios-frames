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
	public func toCommand() throws -> CreateActionCommand {
		CreateActionCommand(action: type, payload: try payload?.toJson())
	}
}

public class CaptureCard : ActionType {
	public class Payload : Encodable {
		let verify: Bool
		let save: Bool
		let env3DS: ThreeDSEnv?

		enum PayloadKeys: String, CodingKey {
			case verify
			case save
			case env3DS
		}

		public init(verify: Bool, save: Bool, env3DS: ThreeDSEnv?) {
			self.verify = verify
			self.save = save
			self.env3DS = env3DS
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: PayloadKeys.self)
			try container.encode(verify, forKey: .verify)
			try container.encode(save, forKey: .save)

			if let env = env3DS {
				try container.encode(env.rawValue, forKey: .env3DS)
			}
		}
	}

	public init(payload: Payload?) {
		super.init(type: "CaptureCard", payload: payload)
	}
}

public class StepUp : ActionType {
	public class Payload : Encodable {
		let paymentInstrumentId: String
		let scheme: String

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
		let paymentInstrumentId: String
		let scheme: String

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
		let sessionId: String
		let env3DS: ThreeDSEnv
		let acsWindowSize: AcsWindowSize

		enum PayloadKeys: String, CodingKey {
			case sessionId
			case env3DS
			case acsWindowSize
		}

		public init(sessionId: String, env3DS: ThreeDSEnv, acsWindowSize: AcsWindowSize = AcsWindowSize.ACS_250x400) {
			self.sessionId = sessionId
			self.env3DS = env3DS
			self.acsWindowSize = acsWindowSize
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: PayloadKeys.self)

			try container.encode(sessionId, forKey: .sessionId)
			try container.encode(env3DS.rawValue, forKey: .env3DS)
			try container.encode(acsWindowSize.rawValue, forKey: .acsWindowSize)
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