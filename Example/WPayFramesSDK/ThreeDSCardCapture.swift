import UIKit
import WPayFramesSDK

/*
  When a Frames SDK action completes, we want to handle the result differently based on the command
  that was being executed
 */
typealias FramesActionHandler = (String) -> Void

/*
  In order for 3DS to work the Merchant (API key) has to support it.
  If you get a 400 response when trying to capture a card, then the Merchant
  doesn't support 3DS.
 */
class ThreeDSCardCapture: FramesHost {
	private static let CARD_ID = "cardElement"
	private static let CHALLENGE_ID = "challengeElement"
	private static let CARD_CAPTURE_ACTION_NAME = "singleCardCapture"
	private static let VALIDATE_CARD_ACTION_NAME = "validateCard"

	private var framesHandler: FramesActionHandler?

	override func viewDidLoad() {
		title = "Three DS Card Capture"
		html = """
			<html>
				<body>
					<div id='\(ThreeDSCardCapture.CARD_ID)'></div>
					<!-- we show the challenge content when required -->
					<div id="\(ThreeDSCardCapture.CHALLENGE_ID)" style="display: none"></div>
		     </body>
		   </html>
		"""

		framesHandler = onCardCapture

		super.viewDidLoad()
	}

	override func onComplete(response: String) {
		debug("onComplete(response: \(response)")

		/*
		  Delegate to the correct handler based on what response we expect from the
		  Frames SDK.
		 */
		framesHandler?(response)
	}

	override func onPageLoaded() {
		super.onPageLoaded()

		let name = ThreeDSCardCapture.CARD_CAPTURE_ACTION_NAME

		do {
			/*
				Step 3.

				Add a single line card group to the page
			 */
			BuildFramesCommand(commands:
				try CaptureCard(payload: cardCaptureOptions()).toCommand(name: name),
				StartActionCommand(name: name),
				CreateActionControlCommand(
					actionName: name,
					controlType: ControlType.CARD_GROUP,
					domId: ThreeDSCardCapture.CARD_ID
				)
			).post(view: framesView, callback: nil)
		}
		catch {
			onError(error: error as! FramesErrors)
		}
	}

	override func onRendered(id: String) {
		super.onRendered(id: id)

		switch(id) {
			case ThreeDSCardCapture.VALIDATE_CARD_ACTION_NAME:
				ShowValidationChallenge().post(view: framesView)

			default:
				break
		}
	}

	override func onRemoved(id: String) {
		super.onRemoved(id: id)

		switch(id) {
			case ThreeDSCardCapture.VALIDATE_CARD_ACTION_NAME:
				ShowValidationChallenge().post(view: framesView)

			default:
				break
		}
	}

	override func onClear(_ sender: Any) {
		super.onClear(sender)

		ClearFormCommand(name: ThreeDSCardCapture.CARD_CAPTURE_ACTION_NAME).post(view: framesView)
	}

	override func onSubmit(_ sender: Any) {
		super.onSubmit(sender)

		SubmitFormCommand(name: ThreeDSCardCapture.CARD_CAPTURE_ACTION_NAME).post(view: framesView)
	}

	override func cardCaptureOptions() -> CaptureCard.Payload {
		CaptureCard.Payload(
			verify: true,
			save: true,
			env3DS: ThreeDSEnv.STAGING
		)
	}

	private func cardValidateCommand(sessionId: String) -> JavascriptCommand? {
		do {
			let cardOptions = validateCardOptions(sessionId: sessionId)

			return GroupCommand(name: "validateCard", commands:
				try ValidateCard(payload: cardOptions).toCommand(name: ThreeDSCardCapture.VALIDATE_CARD_ACTION_NAME),
				StartActionCommand(name: ThreeDSCardCapture.VALIDATE_CARD_ACTION_NAME),
				CreateActionControlCommand(
					actionName: ThreeDSCardCapture.VALIDATE_CARD_ACTION_NAME,
					controlType: ControlType.VALIDATE_CARD,
					domId: ThreeDSCardCapture.CHALLENGE_ID
				),
				CompleteActionCommand(name: ThreeDSCardCapture.VALIDATE_CARD_ACTION_NAME)
			)
		}
		catch {
			onError(error: error as! FramesErrors)

			return nil
		}
	}

	private func validateCardOptions(sessionId: String) -> ValidateCard.Payload {
		ValidateCard.Payload(
			sessionId: sessionId,
			env3DS: ThreeDSEnv.STAGING,
			acsWindowSize: AcsWindowSize.ACS_250x400
		)
	}

	private func onCardCapture(data: String) {
		do {
			guard let response = try CardCaptureResponse.fromJson(json: data) else {
				throw FramesErrors.FATAL_ERROR(message: "Missing CardCaptureResponse")
			}

			if (response.threeDSError == ThreeDSError.TOKEN_REQUIRED) {
				validateCard(threeDSToken: response.threeDSToken!)

				return
			}

			if (response.threeDSError == nil) {
				super.onComplete(response: data)

				return
			}

			onError(error: .FATAL_ERROR(message: "3DS error - \(response.threeDSError!.rawValue)"))
		}
		catch {
			onError(error: error as! FramesErrors)
		}
	}

	private func validateCard(threeDSToken: String) {
		framesHandler = onCardValidation

		cardValidateCommand(sessionId: threeDSToken)?.post(view: framesView)
	}

	private func onCardValidation(data: String) {
		do {
			guard let response = try ValidateCardResponse.fromJson(json: data) else {
				throw FramesErrors.FATAL_ERROR(message: "Missing ValidateCardResponse")
			}

			framesHandler = onCardCapture
			let challenges = try challengeToJson(challengeResponse: response.challengeResponse)

			GroupCommand(name: "completeCardCapture",
				commands: CompleteActionCommand(
					name: ThreeDSCardCapture.CARD_CAPTURE_ACTION_NAME,
					challengeResponses: challenges
				)
			).post(view: framesView, callback: nil)
		}
		catch {
			onError(error: error as! FramesErrors)
		}
	}

	private func challengeToJson(challengeResponse: ChallengeResponse?) throws -> [String] {
		if let challenge = challengeResponse {
			let challengeJson = try challenge.toJson()

			return [ challengeJson ]
		}

		return []
	}

	class ShowValidationChallenge : JavascriptCommand {
		init() {
			super.init(command:
			"""
			  frames.showValidationChallenge = function() {
			    const cardCapture = document.getElementById('\(ThreeDSCardCapture.CARD_ID)');
			    cardCapture.style.display = "none";
			    
			    const challenge = document.getElementById('\(ThreeDSCardCapture.CHALLENGE_ID)');
			    challenge.style.display = "block";
			  };
			  
			  frames.showValidationChallenge();

			  true
			"""
			)
		}
	}

	class HideValidationChallenge : JavascriptCommand {
		init() {
			super.init(command:
			"""
			  frames.showValidationChallenge = function() {
			    const cardCapture = document.getElementById('\(ThreeDSCardCapture.CARD_ID)');
			    cardCapture.style.display = "block";
			    
			    const challenge = document.getElementById('\(ThreeDSCardCapture.CHALLENGE_ID)');
			    challenge.style.display = "none";
			  };
			  
			  frames.showValidationChallenge();

			  true
			"""
			)
		}
	}
}
