/**
  A "Javascript command" is a piece of Javascript that can be evaluated inside the `FramesView`
 */
open class JavascriptCommand {
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
  Combines `DelayedJavascriptCommand`s into an command and executes the result. Each command is
  executed first to add the async function to the web view.

  If any error is thrown, it is logged and the Error's `message` is returned to the app.
  Looking for errors in the Console can aid developers debugging why JS code threw
  errors.
 */
public class GroupCommand: JavascriptCommand {
	public let name: String
	private let commands: [DelayedJavascriptCommand]

	public init(name: String, commands: [DelayedJavascriptCommand], callback: String = "") {
		self.name = name
		self.commands = commands

		super.init(command:
			"""
			frames.\(name) = async function() {
			    try {
			        \(commands
									.map { it in "await frames.\(it.functionName)();" }
									.joined(separator: "\n")
							)
			        
			        \(callback)
			    }
			    catch(e) {
			        frames.handleError('\(name)', e)
			    }
			};

			frames.\(name)();

			true
			"""
		)
	}

	public convenience init(name: String, commands: DelayedJavascriptCommand...) {
		self.init(name: name, commands: commands)
	}

	public override func post(view: FramesView, callback: EvalCallback?) {
		commands.forEach { command in command.post(view: view) }

		super.post(view: view, callback: callback)
	}
}

/**
  Builds the view that is shown to the user.

  On success the FramesView is notified that content has been rendered in the web view.
 */
public class BuildFramesCommand : GroupCommand {
	public init(commands: DelayedJavascriptCommand...) {
		super.init(name: "build", commands: commands, callback: "window.webkit.messageHandlers.handleOnRendered.postMessage('build')")
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
			   },
			     
			   actions: {}
			};

			frames.sdk = new FRAMES.FramesSDK(\(config));

			true
			"""
		)
	}
}

/**
  Creates an SDK Action in the web view.
 */
public class CreateActionCommand : DelayedJavascriptCommand {
	public init(
		name: String,
		action: String,
		payload: String? = nil
	) {
		var args = "FRAMES.ActionTypes.\(action)"
		if let json = payload {
			args += ", \(json)"
		}

		super.init(functionName: "createAction_\(name)", command:
			"""
			frames.createAction_\(name) = async function() {
			    frames.actions.\(name) = frames.sdk.createAction(\(args));
			};

			true
			"""
		)
	}
}

/**
 Creates a control for an existing SDK Action.
 */
public class CreateActionControlCommand : DelayedJavascriptCommand {
	public init(
		actionName: String,
		controlType: String,
		domId: String,
		payload: String? = nil
	) {
		var args = "'\(controlType)', '\(domId)'"
		if let json = payload {
			args += ", \(json)"
		}

		let fnName = "createActionControl_\(domId)"

		super.init(functionName: fnName, command:
			"""
			frames.\(fnName) = async function() {
			    frames.actions.\(actionName).createFramesControl(\(args));

					const element = document.getElementById('\(domId)');

					element.addEventListener(FRAMES.FramesEventType.OnValidated, () => { 
							window.webkit.messageHandlers.handleOnValidated.postMessage({
								domId: '\(domId)',
								errors: frames.actions.\(actionName).errors()
							})
					});

					element.addEventListener(FRAMES.FramesEventType.OnBlur, () => { 
							window.webkit.messageHandlers.handleOnBlur.postMessage('\(domId)') 
					});

					element.addEventListener(FRAMES.FramesEventType.OnFocus, () => { 
							window.webkit.messageHandlers.handleOnFocus.postMessage('\(domId)')
					});

					// this will only be fired once per form.
					element.addEventListener(FRAMES.FramesEventType.FormValid, () => { 
							window.webkit.messageHandlers.handleFormValid.postMessage(true)
					});

					element.addEventListener(FRAMES.FramesEventType.FormInvalid, () => { 
							window.webkit.messageHandlers.handleFormValid.postMessage(false) 
					});

					// this needed in case the element is for a 3DS challenge
			    element.addEventListener(FRAMES.FramesCardinalEventType.OnRender, () => { 
							window.webkit.messageHandlers.handleOnRendered.postMessage('\(actionName)');
					});

			    element.addEventListener(FRAMES.FramesCardinalEventType.OnClose, () => {
							window.webkit.messageHandlers.handleOnRemoved.postMessage('\(actionName)');
					});
			}

			true
			"""
		)
	}

	public convenience init(
		actionName: String,
		controlType: ControlType,
		domId: String,
		payload: String? = nil
	) {
		self.init(
			actionName: actionName,
			controlType: controlType.rawValue,
			domId: domId,
			payload: payload
		)
	}
}

public class StartActionCommand : DelayedJavascriptCommand {
	public init(name: String) {
		super.init(functionName: "startAction_\(name)", command:
			"""
			frames.startAction_\(name) = async function() {
			    await frames.actions.\(name).start();
			}

			true
			"""
		)
	}
}

public class ClearFormCommand : JavascriptCommand {
	public init(name: String) {
		super.init(command: "frames.actions.\(name).clear()")
	}
}

public class SubmitFormCommand : JavascriptCommand {
	public init(name: String) {
		super.init(command:
			"""
			frames.submit = async function() {
			    try {
			        await this.actions.\(name).submit()
			        
			        const response = await this.actions.\(name).complete()
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

/**
 Command to complete an action without requiring user input/action. For example validating
 a card with 3DS.
 */
public class CompleteActionCommand: DelayedJavascriptCommand {
	public init(name: String, save: Bool = true, challengeResponses: [String] = []) {
		super.init(functionName: "completeAction_\(name)", command:
			"""
			frames.completeAction_\(name) = async function() {
			    const response = await this.actions.\(name).complete(\(save), [ \(challengeResponses.joined(separator: ",")) ])
			    window.webkit.messageHandlers.handleOnComplete.postMessage(JSON.stringify(response))
			}

			true
			"""
		)
	}

	public convenience init(name: String, challengeResponses: [ChallengeResponse]) throws {
		self.init(name: name, challengeResponses: try challengeResponses.map({ it in try it.toJson() }))
	}
}
