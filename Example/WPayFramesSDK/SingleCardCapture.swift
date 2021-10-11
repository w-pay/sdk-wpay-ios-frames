import UIKit
import WPayFramesSDK

class SingleCardCapture: FramesHost {
	private static let DOM_ID = "cardElement"

	override func viewDidLoad() {
		title = "Single Card Capture"
		html = "<html><body><div id='\(SingleCardCapture.DOM_ID)'></div></body></html>"

		super.viewDidLoad()
	}

	override func onPageLoaded() {
		super.onPageLoaded()

		do {
			/*
				Step 3.

				Add a single line card group to the page
			 */
			BuildFramesCommand(commands:
				try CaptureCard(payload: cardCaptureOptions()).toCommand(),
				StartActionCommand(),
				CreateActionControlCommand(controlType: ControlType.CARD_GROUP, domId: SingleCardCapture.DOM_ID)
			).post(view: framesView, callback: nil)
		}
		catch {
			onError(error: error as! FramesErrors)
		}
	}
}
