import UIKit
import WPayFramesSDK

class ViewController: UIViewController, FramesViewCallback {
  @IBOutlet weak var messageView: UILabel!
  @IBOutlet weak var framesView: FramesView!

  @IBAction func onClear(_ sender: Any) {
    ClearFormCommand().post(view: framesView)
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
        authToken: "Bearer jbst7UCKR695D93j8tfAd5fG7k2m",
        apiBase: "https://dev.mobile-api.woolworths.com.au/wow/v1/pay/instore",
        logLevel: LogLevel.DEBUG
      ))
    }
    catch FramesErrors.SDK_INIT_ERROR(let message, _) {
      fatalError(message)
    }
    catch {
      fatalError(error.localizedDescription)
    }
  }

  @IBAction func onSubmit(_ sender: Any) {
    SubmitFormCommand().post(view: framesView)
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
        html: "<html><body><div id='cardElement'></div></body></html>"
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

    let captureOptions = CaptureCard.Payload(
      verify: true,
      save: true,
      env3DS: nil
    )

    do {
      /*
        Step 3.

        Add a single line card group to the page
       */
      BuildFramesCommand(commands:
        try CaptureCard(payload: captureOptions).toCommand(),
        StartActionCommand(),
        CreateActionControlCommand(controlType: ControlType.CARD_GROUP, domId: "cardElement")
      ).post(view: framesView, callback: nil)
    }
    catch {
      onError(error: error as! FramesErrors)
    }
  }

  func onRendered() {
    debug("onRendered()")
  }

  private func debug(_ message: String) {
    print("[Callback] \(message)")
  }
}
