import UIKit
import WPayFramesSDK

class MultiLineCardCapture: FramesHost {
	private static let CARD_NO_DOM_ID = "cardNoElement"
	private static let CARD_EXPIRY_DOM_ID = "cardExpiryElement"
	private static let CARD_CVV_DOM_ID = "cardCvvElement"

	private static let ACTION_NAME = "multiLineCardCapture"

	override func viewDidLoad() {
		title = "MultiLine Card Capture"
		html = """
	       <html>
	          <body>
	            <div id="\(MultiLineCardCapture.CARD_NO_DOM_ID)"></div>
	            <div>
	              <div id="\(MultiLineCardCapture.CARD_EXPIRY_DOM_ID)" style="display: inline-block; width: 50%"></div>
	              <div id="\(MultiLineCardCapture.CARD_CVV_DOM_ID)" style="display: inline-block; width: 40%; float: right;"></div>
	            </div>
	          </body>
	        </html>
	   """

		super.viewDidLoad()
	}

	override func onPageLoaded() {
		super.onPageLoaded()

		let name = MultiLineCardCapture.ACTION_NAME

		do {
			/*
				Step 3.

				Add a multi line card group to the page
			 */
			BuildFramesCommand(commands:
				try CaptureCard(payload: cardCaptureOptions()).toCommand(name: name),
				StartActionCommand(name: name),
				CreateActionControlCommand(
					actionName: name,
					controlType: ControlType.CARD_NUMBER,
					domId: MultiLineCardCapture.CARD_NO_DOM_ID
				),
				CreateActionControlCommand(
					actionName: name,
					controlType: ControlType.CARD_EXPIRY,
					domId: MultiLineCardCapture.CARD_EXPIRY_DOM_ID
				),
				CreateActionControlCommand(
					actionName: name,
					controlType: ControlType.CARD_CVV,
					domId: MultiLineCardCapture.CARD_CVV_DOM_ID
				)
			).post(view: framesView, callback: nil)
		}
		catch {
			onError(error: error as! FramesErrors)
		}
	}

	override func onClear(_ sender: Any) {
		super.onClear(sender)

		ClearFormCommand(name: MultiLineCardCapture.ACTION_NAME).post(view: framesView)
	}

	override func onSubmit(_ sender: Any) {
		super.onSubmit(sender)

		SubmitFormCommand(name: MultiLineCardCapture.ACTION_NAME).post(view: framesView)
	}
}
