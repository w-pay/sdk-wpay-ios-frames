import UIKit
import WPayFramesSDK

class FramesHost: UIViewController, FramesViewCallback, PopoverNavigationDelegate {
	@IBOutlet weak var messageView: UILabel!
	@IBOutlet weak var framesView: FramesView!

	internal var html: String?

	@IBAction func displayPopover(_ sender: UIBarButtonItem) {
		let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

		let vc: PopoverViewController =
			storyboard.instantiateViewController(withIdentifier: "PopoverViewController") as! PopoverViewController
		vc.modalPresentationStyle = .popover
		vc.delegate = self

		let popover: UIPopoverPresentationController = vc.popoverPresentationController!
		popover.barButtonItem = sender

		present(vc, animated: true, completion: nil)
	}

	@IBAction func onClear(_ sender: Any) {
		messageView.text = ""
	}

	@IBAction func onLoad(_ sender: Any) {
		/*
			Step 2.

			Load the Frames SDK into the HTML page.
		 */
		do {
			try framesView.loadFrames(config: FramesConfig(
				apiKey: "95udD3oX82JScUQ1qyACSOMysyAl93Gb",
				authToken: "Bearer WbSRULNyePzpyvR1n2ePHMNVunXp",
				apiBase: "https://dev.mobile-api.woolworths.com.au/wow/v1/pay/instore",
				logLevel: LogLevel.DEBUG
			))
		} catch FramesErrors.SDK_INIT_ERROR(let message, _) {
			fatalError(message)
		} catch {
			fatalError(error.localizedDescription)
		}
	}

	@IBAction func onSubmit(_ sender: Any) {
		// by default do nothing
	}

	override func loadView() {
		// so the view is loaded from the XIB file
		Bundle.main.loadNibNamed("FramesHost", owner: self, options: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		/*
			Step 1.

			We need to configure the SDK to provide the "bridge" between the native and web worlds.
		 */
		framesView.configure(
			config: FramesViewConfig(
				/*
					Note: The SDK will inject the JS SDK into the host page. Applications can however
					add other web content to the page to aid in styling.

					Note: The SDK will inject a default <meta> tag setting the viewport if no <meta> tag
					for the viewport is provided in the host HTML. This is required to have the WKWebView
					render the content at the correct "zoom level".
				 */
				html: html!
			),
			callback: self,
			logger: DebugLogger()
		)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func onComplete(response: String) {
		debug("onComplete(response: \(response))")

		do {
			guard let data = try CardCaptureResponse.fromJson(json: response) else {
				throw FramesErrors.FATAL_ERROR(message: "Missing CardCaptureResponse")
			}

			var id: String?

			if (data.paymentInstrument?.itemId != nil) {
				id = data.paymentInstrument?.itemId
			}
			else {
				id = data.itemId
			}

			let message = "\(data.status?.responseText ?? "") - \(id!)"

			messageView.text = message
		} catch {
			onError(error: error as! FramesErrors)
		}
	}

	func onError(error: FramesErrors) {
		debug("onError(error: \(error))")

		switch error {
		case .FATAL_ERROR(let message): messageView.text = message
		case .NETWORK_ERROR(let message): messageView.text = message
		case .TIMEOUT_ERROR(let message): messageView.text = message
		case .FORM_ERROR(let message): messageView.text = message
		case .EVAL_ERROR(let message): messageView.text = message
		case .DECODE_JSON_ERROR(let message, _, _): messageView.text = message
		case .ENCODE_JSON_ERROR(let message, _, _): messageView.text = message
		case .SDK_INIT_ERROR(let message, _): messageView.text = message
		}
	}

	func onProgressChanged(progress: Int) {
		debug("onProgressChanged(progress: \(progress))")
	}

	func onValidationChange(domId: String, isValid: Bool) {
		debug("onValidationChange(\(domId), isValid: \(isValid))")
	}

	func onFocusChange(domId: String, isFocussed: Bool) {
		debug("onFocusChange(\(domId), isFocussed: \(isFocussed))")
	}

	func onPageLoaded() {
		debug("onPageLoaded()")

		/*
		 * Step 3.
		 *
		 * Override this to add card controls to action
		 */
	}

	func onRendered() {
		debug("onRendered()")
	}

	func navigateTo(vc: UIViewController) {
		navigationController?.pushViewController(vc, animated: false)
	}

	func cardCaptureOptions() -> CaptureCard.Payload {
		CaptureCard.Payload(
			verify: true,
			save: true,
			env3DS: nil
		)
	}

	private func debug(_ message: String) {
		print("[Callback] \(message)")
	}
}
