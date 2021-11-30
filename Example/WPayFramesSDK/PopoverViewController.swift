import UIKit

protocol PopoverNavigationDelegate {
	func navigateTo(vc: UIViewController)
}

class PopoverViewController : UITableViewController {
	private let examples = [
		"Single Card Capture",
		"Multi Line Card Capture",
		"ThreeDS Card Capture"
	]

	public var delegate: PopoverNavigationDelegate?

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		"Examples"
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		examples.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.textLabel?.text = examples[indexPath.row]

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		delegate?.navigateTo(vc: createViewControllerForPos(pos: indexPath.row))

		dismiss(animated: true, completion: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let selectedIndexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: selectedIndexPath, animated: animated)
		}
	}

	private func createViewControllerForPos(pos: Int) -> FramesHost {
		switch (pos) {
			case 0:
				return SingleCardCapture()

			case 1:
				return MultiLineCardCapture()

			default:
				return ThreeDSCardCapture()
		}
	}
}
