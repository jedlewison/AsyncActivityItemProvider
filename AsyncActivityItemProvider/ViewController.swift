//
//  ViewController.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/12/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func showActivityViewController(sender: UIBarButtonItem) {

        let provideItemHandler: ProvideItemHandler = {
            operation in

            let delay = Int64(4 * NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, delay)
            dispatch_after(time, dispatch_get_main_queue()) {
                [weak operation] in
                operation?.finishWithItem(NSDate().description)
            }
            if let operation = operation as? ProgressUpdating, progressHandler = operation.progressHandler {
                var i = 0 as Double
                while i < 100 {
                    let progress = i/7
                    progressHandler(progress: progress)
                    i += 1
                    sleep(1)
                }
            }

        }

        let cancellationHandler: CancellationHandler = {
            operation in
            operation.finish()
        }

        let asyncActivityItemProvider = AsyncActivityItemProvider(placeholderItem: "Blah", provideItemHandler: provideItemHandler, cancelHandler: cancellationHandler)
        let activityViewController = UIActivityViewController(possiblyAsyncActivityItems: [asyncActivityItemProvider], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

