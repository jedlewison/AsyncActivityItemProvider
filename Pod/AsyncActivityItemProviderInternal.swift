//
//  AsyncActivityItemProvider.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/12/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import UIKit
import AsyncOpKit

protocol ProgressUpdateable: class {
    func updateProgress(progress: Double?)
}

typealias ProgressHandler = (progress: Double) -> ()

protocol ProgressUpdating: class {
    var progressHandler: ProgressHandler? { set get }
}


extension UIAlertController {

    func updateProgress(progress: Double?) {
        dispatch_async(dispatch_get_main_queue()) {
            let progressPercent = Int(round((progress ?? 0) * 100))
            self.message = "\(progressPercent)%"
        }
    }

}


final class AsyncUIActivityItemProvider: UIActivityItemProvider {

    private(set) weak var avc: UIActivityViewController?
    private(set) var operationQueue: NSOperationQueue?
    var progress: Double? = 0 {
        didSet {
            progressController?.updateProgress(progress)
        }
    }

    private var itemProviderOperation: ActivityItemProviderOperation?

    required init(itemProvider: AsyncActivityItemProvider) {
        itemProviderOperation = ActivityItemProviderOperation(provideItemHandler: itemProvider.provideItemHandler, cancelHandler: itemProvider.cancellationHandler)
        super.init(placeholderItem: itemProvider.placeholderItem)
        if itemProvider.progressControllerMode == .Disabled {
            progressController = nil
        }
    }

    private var selfCancelled = false {
        didSet {
            if selfCancelled {
                cancel()
            }
        }
    }

    lazy var progressController: UIAlertController? = {
        [unowned self] in
        let alertController = UIAlertController(title: "Preparing...", message: " ", preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "Cancel", style: .Cancel) {
            (action) -> Void in
            self.selfCancelled = true
        }
        alertController.addAction(alertAction)
        return alertController
        }()

    override func item() -> AnyObject! {

        if let itemProviderOperation = itemProviderOperation {
            itemProviderOperation.activityType = activityType
            itemProviderOperation.progressHandler = {
                progress in
                self.progress = progress
            }
            self.itemProviderOperation = nil
            operationQueue = NSOperationQueue()
            operationQueue?.name = "AsyncActivityItemProviderOpQ"
            itemProviderOperation.activityType = activityType

            let operations: [AnyObject]

            if let progressController = progressController {
                let presentViewControllerOperation = PresentViewControllerOperation(presentationContext: avc, presentedViewController: progressController)
                let dismissViewControllerOperation = DismissViewControllerOperation(presentedViewController: progressController)
                itemProviderOperation.addDependency(presentViewControllerOperation)
                dismissViewControllerOperation.addDependency(itemProviderOperation)
                operations = [presentViewControllerOperation, itemProviderOperation, dismissViewControllerOperation]
            } else {
                operations = [itemProviderOperation]
            }

            operationQueue?.addOperations(operations, waitUntilFinished: true)

            if selfCancelled {
                let dismissActivityViewControllerOperation = DismissViewControllerOperation(presentedViewController: avc)
                operationQueue?.addOperations([dismissActivityViewControllerOperation], waitUntilFinished: true)
                return nil
            } else {
                let item: AnyObject? = itemProviderOperation.item
                return item
            }
        } else {
            return nil
        }
    }

    override func cancel() {
        operationQueue?.cancelAllOperations()
        super.cancel()
    }

    override func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        avc = activityViewController
        return super.activityViewControllerPlaceholderItem(activityViewController)
    }

}

private class ActivityItemProviderOperation: AsyncOperation, ProgressUpdating, AsyncActivityItemProviderOperationController {

    var item: AnyObject?
    var activityType: String?
    var provideItemHandler: ProvideItemHandler
    var cancelHandler: CancellationHandler?
    var progressHandler: ProgressHandler?
    var progress: Double = 0 {
        didSet {
            progressHandler?(progress: progress)
        }
    }

    init(provideItemHandler: ProvideItemHandler, cancelHandler: CancellationHandler? = nil) {
        self.provideItemHandler = provideItemHandler
        self.cancelHandler = cancelHandler
        super.init()
        qualityOfService = .UserInitiated
    }

    override func main() {
        if cancelled {
            finish()
        }
        provideItemHandler(activityType: activityType ?? "", operation: self)
    }

    func finishWithItem(item: AnyObject?) {
        self.item = item
        finish()
    }

    override func cancel() {
        super.cancel()
        if let cancelHandler = cancelHandler {
            cancelHandler(operation: self)
        } else {
            finish()
        }
    }

}