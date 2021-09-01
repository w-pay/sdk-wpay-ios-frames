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
  WKWebView executes JS synchronously, and doesn't wait for asynchronous JS to complete
  before returning to native code.

  Therefore if we want to compose JS async behaviour we have to create a wrapper function
  that can be called as part of a JS composition.

  - See: `BuildFramesCommand`
 */
public class DelayedJavascriptCommand : JavascriptCommand {
	public let functionName: String

	public init(functionName: String, command: String) {
		self.functionName = functionName

		super.init(command: command)
	}
}

/**
  Combines `DelayedJavascriptCommand`s into an command and executes the result.

  Each command is executed first to add the async function to the web view.

  If any error is thrown, it is logged and the Error's `message` is returned to the app.
  Looking for errors in the Console can aid developers debugging why JS code threw
  errors.

  On success the FramesView is notified that content has been rendered in the web view.
 */
public class BuildFramesCommand : JavascriptCommand {
	private let commands: [DelayedJavascriptCommand]

	public init(commands: DelayedJavascriptCommand...) {
		self.commands = commands

		super.init(command:
			"""
			frames.build = async function() {
			    try {
			        \(commands
									.map { it in "await frames.\(it.functionName)();" }
									.joined(separator: "\n")
							)
						    
			        window.webkit.messageHandlers.handleOnRendered.postMessage("")
			    }
			    catch(e) {
			        frames.handleError('build', e)
			    }
			};

			frames.build();

			true
			"""
		)
	}

	public override func post(view: FramesView, callback: EvalCallback?) {
		commands.forEach { it in it.post(view: view) }

		super.post(view: view, callback: callback)
	}
}

public class AddDefaultViewportCommand : JavascriptCommand {
	public init() {
		super.init(command:
			"""
        const head = document.getElementsByTagName("head")[0];
        const metas = Array.prototype.slice.call(head.getElementsByTagName("meta"))
        const viewport = metas.find((el) => el.getAttribute("name") === "viewport")

        if (!viewport) {
          const meta = document.createElement("meta")
          meta.setAttribute("name", "viewport")
          meta.setAttribute("content", "width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no")

          head.appendChild(meta)
        }

        true
      """
		)
	}
}

/**
 Javascript to create a new instance of Frames in the host page
 */
public class InstantiateFramesSDKCommand : JavascriptCommand {
	public init(config: String) {
		super.init(command:
			"""
			const frames = {
			   handleError: function(fnName, err) {
			       console.error('frames.' + fnName + ': ' + err)
			       
			       window.webkit.messageHandlers.handleOnError.postMessage(err.message);
			   }
			};

			frames.sdk = new FRAMES.FramesSDK(\(config));

			true
			"""
		)
	}
}

/**
  Creates an SDK Action in the web view.

  Note that this will overwrite any previous action, so make sure each action is completed.
 */
public class CreateActionCommand : DelayedJavascriptCommand {
	public init(action: String, payload: String? = nil) {
		var args = "FRAMES.ActionTypes.\(action)"
		if let json = payload {
			args += ", \(json)"
		}

		super.init(functionName: "createAction", command:
			"""
			frames.createAction = async function() {
			    frames.action = frames.sdk.createAction(\(args));
			};

			true
			"""
		)
	}
}

public class CreateActionControlCommand : DelayedJavascriptCommand {
	public init(controlType: String, domId: String, payload: String? = nil) {
		var args = "'\(controlType)', '\(domId)'"
		if let json = payload {
			args += ", \(json)"
		}

		let fnName = "createActionControl_\(domId)"

		super.init(functionName: fnName, command:
			"""
			frames.\(fnName) = async function() {
			    frames.action.createFramesControl(\(args));

					const element = document.getElementById('\(domId)');

					element.addEventListener(FRAMES.FramesEventType.OnValidated, () => { 
							window.webkit.messageHandlers.handleOnValidated.postMessage({
								domId: '\(domId)',
								errors: frames.action.errors()
							})
					});

					element.addEventListener(FRAMES.FramesEventType.OnBlur, () => { 
							window.webkit.messageHandlers.handleOnBlur.postMessage('\(domId)') 
					});

					element.addEventListener(FRAMES.FramesEventType.OnFocus, () => { 
							window.webkit.messageHandlers.handleOnFocus.postMessage('\(domId)')
					});
			}

			true
			"""
		)
	}

	public convenience init(controlType: ControlType, domId: String, payload: String? = nil) {
		self.init(controlType: controlType.rawValue, domId: domId, payload: payload)
	}
}

public class StartActionCommand : DelayedJavascriptCommand {
	public init() {
		super.init(functionName: "startAction", command:
			"""
			frames.startAction = async function() {
			    await frames.action.start();
			}

			true
			"""
		)
	}
}

public class ClearFormCommand : JavascriptCommand {
	public init() {
		super.init(command: "frames.action.clear()")
	}
}

public class SubmitFormCommand : JavascriptCommand {
	public init() {
		super.init(command:
			"""
			frames.submit = async function() {
			    try {
			        await this.action.submit()
			        
			        const response = await this.action.complete()
			        window.webkit.messageHandlers.handleOnComplete.postMessage(JSON.stringify(response))
			    }
			    catch(e) {
			        frames.handleError('submit', e)
			    }
			}

			frames.submit();

			true
			"""
		)
	}
}
