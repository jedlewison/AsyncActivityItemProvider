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

        // Create a closer that provides an item asynchronously,
        // calling finishWithItem on the supplied operation parameter
        // Here we are simply using a dispatch after and then supplying an NSDate description
        let provideItemHandler: ProvideItemHandler = {
            (activityType: String, operation: AsyncActivityItemProviderOperationController) in

            let delayFactor: Double = 12
            let delay = UInt64(delayFactor) * NSEC_PER_SEC
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                [weak operation] in
                operation?.finishWithItem(NSDate().description)
            }

            // Update progress during the operation

            var i = 1 as Double
            while i <= delayFactor {
                operation.progress = i/delayFactor
                i += 1
                sleep(1)
            }

        }

        // Cancellation handler lets you perform custom cancellation.
        // Although you don't need to call finish on the operation inside the handler,
        // You must ensure that finish is called on the operation
        // This implementation mimics the default behavior (simply pass nil)
        let cancellationHandler: CancellationHandler = {
            operation in
            operation.finish()
        }

        // create an item provider with the handlers and a placeholder item
        // Indicate whether the progress controller should be shown

        let asyncActivityItemProvider = AsyncActivityItemProvider(placeholderItem: "Blah", provideItemHandler: provideItemHandler, cancellationHandler: cancellationHandler, progressControllerMode: .Enabled)

        // create the activityViewController with the asyncActivityItemProvider, then present it
        let activityViewController = UIActivityViewController(asyncItemProvider: asyncActivityItemProvider, activityItems: nil, applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        presentViewController(activityViewController, animated: true, completion: nil)

        activityViewController.completionWithItemsHandler = {
            _, completed, _, error in
            if let error = error {
                print(error)
            }
            print(completed)

            activityViewController.completionWithItemsHandler = nil
        }

    }

    
}

