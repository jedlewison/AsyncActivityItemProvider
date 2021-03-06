# AsyncActivityItemProvider
UIActivityItemProvider subclass to handle providing items that must be generated asynchronously, including presenting a progress UI.

Documentation and a proper Podspec coming soon.

Example usage:

```
        // Create a closer that provides an item asynchronously,
        // calling finishWithItem on the supplied operation parameter
        // Here we are simply using a dispatch after and then supplying an NSDate description
        let provideItemHandler: ProvideItemHandler = {
            (activityType: String, operation: AsyncActivityItemProviderOperationController) in

            let delay = Int64(4 * NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, delay)
            dispatch_after(time, dispatch_get_main_queue()) {
                [weak operation] in
                operation?.finishWithItem(NSDate().description)
            }

            // Update progress during the operation
            var i = 1 as Double
            while i <= 4 {
                operation.progress = i/4
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
