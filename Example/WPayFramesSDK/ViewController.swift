//
//  ViewController.swift
//  WPayFramesSDK
//
//  Created by kierans on 08/23/2021.
//  Copyright (c) 2021 kierans. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    @IBOutlet weak var messageView: UILabel!
    @IBOutlet weak var framesView: WKWebView!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var Clear: UIButton!
    @IBOutlet weak var load: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

