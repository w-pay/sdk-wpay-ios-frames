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
    }))
  }
}
                                
console.log = logger("log")
console.warn = logger("warn")
console.error = logger("error")
console.debug = logger("debug")
                                
window.addEventListener("error", function(e) {
  console.error(`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`)
})
"""

public class FramesView : WKWebView {
	public func configure() throws {
    let html = """
        <html>
            <head>
                <script>
                    window.onload = function() { console.log(`Frames exists: ${FRAMES !== undefined}`) }
                </script>
            </head>
        </html>
    """

		addJavascriptHandlers()
		try injectUserScripts()

		loadHTMLString(html, baseURL: nil)
	}

	private func addJavascriptHandlers() {
		/*
		  Even though the Apple docs imply that modifying the `userContentController` shouldn't work;
		  it does.

		  See https://stackoverflow.com/a/57536999/586182
		 */

		// add the handler for "log" messages
		configuration.userContentController.add(ConsoleLogHandler(), name: "log")
	}

	private func injectUserScripts() throws {
		// inject the global script
		configuration.userContentController.addUserScript(
			WKUserScript(source: globalScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
		)

		// inject the Frames JS SDK
		configuration.userContentController.addUserScript(
			WKUserScript(source: try loadFramesSDKSource(), injectionTime: .atDocumentStart, forMainFrameOnly: true)
		)
	}

	private func loadFramesSDKSource() throws -> String {
		let frameworkBundle = Bundle(for: FramesView.self)

		guard let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("WPayFramesSDK.bundle") else {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't create resource bundle URL")
		}

		guard let resourceBundle = Bundle(url: bundleURL) else {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't create resource bundle")
		}

		guard let url = resourceBundle.url(forResource: "framesSDK-2.0.2", withExtension: "js") else {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't find Frames JS SDK in framework resource bundle")
		}

		do {
			return try String(contentsOf: url, encoding: .utf8)
		}
		catch {
			throw FramesErrors.SDK_INIT_ERROR(message: "Can't read contents of Frames JS SDK", cause: error)
		}
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
