import WebKit

/*
	In order to log messages from the Frames JS SDK, we need to wrap the console methods and
  forward the messages to a logging handler in native code.
 */
let globalScript = """
function logger(level) {
  return function() {
    window.webkit.messageHandlers.log.postMessage(JSON.stringify({
      level,
      message: Array.prototype.slice.call(arguments).join(",")                           
    }));
  }
}
                                
console.log = logger("log");
console.warn = logger("warn");
console.error = logger("error");
console.debug = logger("debug");
                                
window.addEventListener("error", function(e) {
  console.error(`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`);
})
                   
window.onload = function() { 
	window.webkit.messageHandlers.handleFramesSDKLoaded.postMessage(FRAMES !== undefined);
}
"""

let JS_SDK_VERSION = "2.0.2"

public typealias EvalCallback = (Any?, Error?) -> Void

/**
	Configuration about how the Application wants to host the SDK.
 */
public class FramesViewConfig {
	/// The host HTML for the SDK.
	let html: String

	/// Whether assets can still be loaded if SSL validation fails.
	let allowInvalidSsl: Bool

	public init(html: String, allowInvalidSsl: Bool = false) {
		self.html = html
		self.allowInvalidSsl = allowInvalidSsl
	}
}

/**
	Allows an Application to receives messages from the JS SDK/WebView
 */
public protocol FramesViewCallback {
	func onComplete(response: String)

	/**
		Called when an error occurs.
	 */
	func onError(error: FramesErrors)

	/**
		Called as the progress changes loading the web content.
	 */
	func onProgressChanged(progress: Int)

	/**
		Called when the validation status of an element has changed.

		- Parameter domId: The ID of the element in the HTML DOM tree
		- Parameter isValid: Whether the contents of the element is valid or not.
	 */
	func onValidationChange(domId: String, isValid: Bool)

	/**
		Called when the focus has changed on an element

		- Parameter domId: The ID of the element in the HTML DOM tree
		- Parameter isFocussed: Whether the element is focussed or not
	 */
	func onFocusChange(domId: String, isFocussed: Bool)

	/**
		Called when all the web content has been loaded and the Frames JS SDK is ready to
		use.
	 */
	func onPageLoaded()

	/**
		Called when JS SDK Action has added content to the host page.
	 */
	func onRendered()
}

/**
  Allows applications to decide the fate of log messages.
 */
public protocol FramesViewLogger {
	func log(tag: String, message: String)
}

/**
  Hosts the Frames JS SDK inside an WKWebView.

  Allows applications to receive messages from the JS SDK via a [FramesView.Callback], and to send
  the JS SDK commands via posting [JavascriptCommand]s

  Using the Frames JS SDK follows the following steps
  1. The host application configures the view
  2. The host HTML "page" is "loaded" into the web view
  3. Other web resources (ie: the Frames JS) are "loaded" into the host HTML page.

  The FrameView is now considered "loaded" that is all resources are available for use. SDK Actions
  can be posted into the view.

  4. HTML elements are "rendered" on the page. Once rendered, the elements can be interacted with
  by the user and events are emitted.

  5. As the user interacts with the web elements, events are emitted and passed to the the callback
  6. The user can submit the form, or clear the form.
  7. After form submission, the application should complete the action.
 */
public class FramesView : WKWebView, WKScriptMessageHandler {
	private var config: FramesViewConfig?
	private var sdkConfig: FramesConfig?

	private var callback: FramesViewCallback?
	private var logger: FramesViewLogger?

	public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
		super.init(frame: frame, configuration: configuration)

		initialiseWebView()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)

		initialiseWebView()
	}

	public override func observeValue(
		forKeyPath keyPath: String?,
		of object: Any?,
		change: [NSKeyValueChangeKey : Any]?,
		context: UnsafeMutableRawPointer?
	) {
		if (keyPath == "estimatedProgress") {
			callback?.onProgressChanged(progress: Int(estimatedProgress * 100))
		}
	}

	public func userContentController(
		_ userContentController: WKUserContentController,
		didReceive message: WKScriptMessage
	) {
		switch message.name {
			case "handleFramesSDKLoaded": handleFramesSDKLoaded(message: message)
			case "handleOnError": handleOnError(message: message)

			default:
				callback?.onError(error: FramesErrors.FATAL_ERROR(message: "Unrecognised JS handler \(message.name)"))
		}
	}

	/**
	  The starting point for Applications to configure the interaction between native code
	  and the JS SDK. It must be called first.

	  - Parameter config: Configuration about how to host the SDK.
	  - Parameter callback: Optional callback to receive messages from the SDK.
	  - Parameter logger: Optional logger instance.
	 */
	public func configure(
		config: FramesViewConfig,
		callback: FramesViewCallback?,
		logger: FramesViewLogger?
	) {
		self.config = config
		self.callback = callback
		self.logger = logger
	}

	/**
	  Load the SDK into the host page.

	  This will create a new instance of the JS SDK inside the host page.

	  - Parameter config: Configuration for the JS SDK.
	  - Throws: `FramesErrors.SDK_INIT_ERROR` if the JS SDK can't be loaded
	 */
	public func loadFrames(config: FramesConfig) throws {
		sdkConfig = config

		// inject the Frames JS SDK
		configuration.userContentController.addUserScript(
			WKUserScript(source: try loadFramesSDKSource(), injectionTime: .atDocumentStart, forMainFrameOnly: true)
		)

		loadHTMLString(self.config!.html, baseURL: nil)
	}

	/**
	  Evaluates the Javascript command in the WebView

	  Can be used from any thread.

	  - Parameter command: The command to execute
	  - Parameter callback: If the JS returns a result, the callback will receive it.
	 */
	func postCommand(command: JavascriptCommand, callback: EvalCallback? = nil) {
		let js = command.command

		log("JavascriptCommand: \(js)")

		evaluateJavaScript(js, completionHandler: callback)
	}

	private func initialiseWebView() {
		/*
		 * Register an observer so we can get told about the progress of loading the web content.
		 */
		addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)

		addJavascriptHandlers()

		// inject the global script
		configuration.userContentController.addUserScript(
			WKUserScript(source: globalScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
		)
	}

	private func addJavascriptHandlers() {
		/*
		  Even though the Apple docs imply that modifying the `userContentController` shouldn't work;
		  it does.

		  See https://stackoverflow.com/a/57536999/586182
		 */

		// add the handler for "log" messages
		configuration.userContentController.add(ConsoleLogHandler(), name: "log")
		configuration.userContentController.add(self, name: "handleFramesSDKLoaded")
		configuration.userContentController.add(self, name: "handleOnError")
	}

	private func handleFramesSDKLoaded(message: WKScriptMessage) {
		let result = message.body as! Bool

		if (result == true) {
			do {
				InstantiateFramesSDKCommand(config: try sdkConfig!.toJson()).post(view: self)

				callback?.onPageLoaded()
			}
			catch {
				// TODO:
			}
		}
		else {
			callback?.onError(error: FramesErrors.SDK_INIT_ERROR(message: "FRAMES not found in window"))
		}
	}

	private func handleOnError(message: WKScriptMessage) {
		let message = message.body as! String

		log("handleOnError(\(message))")

		callback?.onError(error: FramesErrors.EVAL_ERROR(message: message))
	}

	/**
	  - Throws: `FramesErrors.SDK_INIT_ERROR` if the JS SDK can't be loaded.
	 */
	private func loadFramesSDKSource() throws -> String {
		let frameworkBundle = Bundle(for: FramesView.self)

		guard let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("WPayFramesSDK.bundle") else {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't create resource bundle URL")
		}

		guard let resourceBundle = Bundle(url: bundleURL) else {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't create resource bundle")
		}

		guard let url = resourceBundle.url(forResource: "framesSDK-\(JS_SDK_VERSION)", withExtension: "js") else {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't find Frames JS SDK in framework resource bundle")
		}

		do {
			return try String(contentsOf: url, encoding: .utf8)
		}
		catch {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't read contents of Frames JS SDK", cause: error)
		}
	}

	private func log(_ msg: String) {
		logger?.log(tag: "FramesView", message: msg)
	}
}

class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
	class LogMessage: Decodable {
		let level: String
		let message: String
	}

	private let decoder: JSONDecoder

	override init() {
		decoder = JSONDecoder()

		super.init()
	}

	func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
		do {
			if (message.name == "log") {
				let body = try decodeJson(json: message.body as! String)

				log(level: body.level, message: body.message)
			}
		}
		catch {
			log(level: "error", message: "Error decoding JSON \(error)")
		}
	}

	private func decodeJson(json: String) throws -> LogMessage {
		guard let data = json.data(using: .utf8) else {
			throw FramesErrors.DECODE_JSON_ERROR(message: "Non utf8 string returned", cause: nil, json: json)
		}

		do {
			return try decoder.decode(LogMessage.self, from: data)
		}
		catch {
			throw FramesErrors.DECODE_JSON_ERROR(message: "Unable to decode JSON", cause: error, json: json)
		}
	}

	private func log(level: String, message: String) {
		print("[FramesView.ConsoleLogHandler] \(level.uppercased()): \(message)")
	}
}