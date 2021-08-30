import UIKit
import WPayFramesSDK

class ViewController: UIViewController {
    @IBOutlet weak var messageView: UILabel!
    @IBOutlet weak var framesView: FramesView!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var Clear: UIButton!
    @IBOutlet weak var load: UIButton!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        do {
            try framesView.configure()
        }
        catch {
            fatalError("something went wrong")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

