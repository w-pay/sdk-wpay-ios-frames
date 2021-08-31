/**
  A "Javascript command" is a piece of Javascript that can be evaluated inside the `FramesView`
 */
public class JavascriptCommand {
	/*
	  The JS code to run.

	  Every piece of JS code should return a result indicating the outcome/failure of the
	  evaluation. If the JS code doesn't return a value, any completionHandler passed to
	  `evaluateJavaScript` may receive an error instead of a successful result making it
	   hard to determine if there was any actual evaluation error.
	*/
	let command: String

	public init(command: String) {
		self.command = command
	}

	/**
	  Allows commands to define how their posted into a `FramesView`

	  This method should be called on commands, instead of `FramesView#postCommand`

	  If there is a JS evaluation error, the callback will still be invoked.
	  Any logging done by JS code will be printed to the console.
	 */
	public func post(view: FramesView, callback: EvalCallback? = nil) {
		view.postCommand(command: self, callback: callback)
	}
}

/**
 Javascript to create a new instance of Frames in the host page
 */
class InstantiateFramesSDKCommand : JavascriptCommand {
	init(config: String) {
		super.init(command:
			"""
			const frames = {
			   handleError: function(fnName, err) {
			       console.error('frames.' + fnName + ': ' + err)
			       
			       window.webkit.messageHandlers.handleError.postMessage.handleOnError(err.message);
			   }
			};

			frames.sdk = new FRAMES.FramesSDK(\(config));

			true
			"""
		)
	}
}