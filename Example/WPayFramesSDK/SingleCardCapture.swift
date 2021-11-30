import UIKit
import WPayFramesSDK

class SingleCardCapture: FramesHost {
	private static let DOM_ID = "cardElement"
	private static let ACTION_NAME = "singleCardCapture"

	override func viewDidLoad() {
		title = "Single Card Capture"
		html = "<html><body><div id='\(SingleCardCapture.DOM_ID)'></div></body></html>"

		super.viewDidLoad()
	}

	override func onPageLoaded() {
		super.onPageLoaded()

		let name = SingleCardCapture.ACTION_NAME

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
					domId: SingleCardCapture.DOM_ID
				)
			).post(view: framesView, callback: nil)
		}
		catch {
			onError(error: error as! FramesErrors)
		}
	}

	override func onClear(_ sender: Any) {
		super.onClear(sender)

		ClearFormCommand(name: SingleCardCapture.ACTION_NAME).post(view: framesView)
	}

	override func onSubmit(_ sender: Any) {
		super.onSubmit(sender)

		SubmitFormCommand(name: SingleCardCapture.ACTION_NAME).post(view: framesView)
	}
}
