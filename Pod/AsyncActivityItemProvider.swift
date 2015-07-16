//
//  AsyncActivityItemProvider.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/12/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import UIKit
import AsyncOpKit

typealias ProvideItemHandler = (operation: ActivityItemProviderOperationController) -> ()
typealias CancellationHandler = (operation: ActivityItemProviderOperationController) -> ()
typealias ProgressHandler = (progress: Double) -> ()

protocol ActivityItemProviderOperation: NSOperationProtocol {
    var item: AnyObject? { get }
    var activityType: String? { set get }
}

protocol ActivityItemProviderOperationController: ActivityItemProviderOperation {
    func finishWithItem(item: AnyObject?)
    func cancel()
    func finish()
}

protocol ProgressUpdating: class {
    var progressHandler: ProgressHandler? { set get }
}

protocol ProgressUpdateable: class {
    func updateProgress(progress: Double?)
}

extension UIAlertController: ProgressUpdateable {

    func updateProgress(progress: Double?) {
        dispatch_async(dispatch_get_main_queue()) {
            let progressPercent = Int(round((progress ?? 0) * 100))
            self.message = "\(progressPercent)%"
        }
    }

}

class AsyncActivityItemProvider: UIActivityItemProvider {

    private(set) weak var avc: UIActivityViewController?
    private(set) var operationQueue: NSOperationQueue?
    var progress: Double? = 0 {
        didSet {
            (progressController as? ProgressUpdateable)?.updateProgress(progress)
        }
    }

    private var itemProviderOperation: ActivityItemProviderOperation?

    required init(placeholderItem: AnyObject, itemProviderOperation: ActivityItemProviderOperation) {
        self.itemProviderOperation = itemProviderOperation
        super.init(placeholderItem: placeholderItem)
    }

    required init(placeholderItem: AnyObject, provideItemHandler: ProvideItemHandler, cancelHandler: CancellationHandler? = nil) {
        itemProviderOperation = AsyncActivityItemProviderOperation(provideItemHandler: provideItemHandler, cancelHandler: cancelHandler)
        super.init(placeholderItem: placeholderItem)
    }

    private var selfCancelled = false {
        didSet {
            if selfCancelled {
                cancel()
            }
        }
    }

    lazy var progressController: UIViewController? = {
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

            (itemProviderOperation as? ProgressUpdating)?.progressHandler = {
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
                dismissViewControllerOperation.addDependency(itemProviderOperation as! NSOperation)
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

private class AsyncActivityItemProviderOperation: AsyncOperation, ActivityItemProviderOperationController, ProgressUpdating {

    var item: AnyObject?
    var activityType: String?
    var provideItemHandler: ProvideItemHandler
    var cancelHandler: CancellationHandler?
    var progressHandler: ProgressHandler?

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
        provideItemHandler(operation: self)
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


protocol NSOperationProtocol: NSObjectProtocol {
    func start()
    func main()

    var cancelled: Bool { get }
    func cancel()

    var executing: Bool { get }
    var finished: Bool { get }
    var concurrent: Bool { get } // To be deprecated; use and override 'asynchronous' below
    @availability(iOS, introduced=7.0)
    var asynchronous: Bool { get }
    var ready: Bool { get }

    func addDependency(op: NSOperation)
    func removeDependency(op: NSOperation)

    var dependencies: [AnyObject] { get }

    var queuePriority: NSOperationQueuePriority { get set }

    @availability(iOS, introduced=4.0)
    var completionBlock: (() -> Void)?  { get set }

    @availability(iOS, introduced=4.0)
    func waitUntilFinished()

    @availability(iOS, introduced=4.0, deprecated=8.0)
    var threadPriority: Double  { get set }
    
    @availability(iOS, introduced=8.0)
    var qualityOfService: NSQualityOfService  { get set }
    
    @availability(iOS, introduced=8.0)
    var name: String?  { get set }
}