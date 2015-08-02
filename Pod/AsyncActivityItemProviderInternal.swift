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

    var itemProviderOperation: ActivityItemProviderOperation?

    convenience init(itemProvider: AsyncActivityItemProvider) {
        let itemProviderOperation = ActivityItemProviderOperation(itemProvider: itemProvider)
        self.init(itemProviderOperation: itemProviderOperation)
    }

    required init(itemProviderOperation: ActivityItemProviderOperation) {
        self.itemProviderOperation = itemProviderOperation
        super.init(placeholderItem: itemProviderOperation.placeholderItem)
        if itemProviderOperation.progressControllerMode == .Disabled {
            progressController = nil
        }
    }


    private var selfCancelled = false {
        didSet {
            if selfCancelled {
                operationQueue?.cancelAllOperations()
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

            let startBackgroundOperation = StartBackgroundOperation()
            itemProviderOperation.addDependency(startBackgroundOperation)
            let endBackgroundOperation = EndBackgroundOperation()
            endBackgroundOperation.addDependency(itemProviderOperation)
            let guaranteeAppIsInForegroundOperation = GuaranteeAppIsInForegroundOperation()
            guaranteeAppIsInForegroundOperation.addDependency(endBackgroundOperation)
            var operations = [startBackgroundOperation, itemProviderOperation, endBackgroundOperation, guaranteeAppIsInForegroundOperation]

            if let progressController = progressController {
                let presentViewControllerOperation = PresentViewControllerOperation(presentationContext: avc, presentedViewController: progressController)
                let dismissViewControllerOperation = DismissViewControllerOperation(presentedViewController: progressController)
                itemProviderOperation.addDependency(presentViewControllerOperation)
                dismissViewControllerOperation.addDependency(itemProviderOperation)
                operations.extend([presentViewControllerOperation, dismissViewControllerOperation])
            }

            operationQueue?.addOperations(operations, waitUntilFinished: true)

            if selfCancelled {
                self.cancel()
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

public class ActivityItemProviderOperation: AsyncOperation, ProgressUpdating, AsyncActivityItemProviderOperationController {

    public let progressControllerMode: ProgressControllerMode
    public let placeholderItem: AnyObject
    public var item: AnyObject?
    public private(set) var activityType: String?
    var provideItemHandler: ProvideItemHandler?
    public var cancelHandler: CancellationHandler?
    var progressHandler: ProgressHandler?
    public var progress: Double = 0 {
        didSet {
            progressHandler?(progress: progress)
        }
    }
    
    public init(placeholderItem: AnyObject, progressControllerMode: ProgressControllerMode = .Enabled, provideItemHandler: ProvideItemHandler? = nil, cancellationHandler: CancellationHandler? = nil) {
        self.placeholderItem = placeholderItem
        self.progressControllerMode = progressControllerMode
        self.provideItemHandler = provideItemHandler
        self.cancelHandler = cancellationHandler
        super.init()
        qualityOfService = .UserInitiated

    }

    convenience init(itemProvider: AsyncActivityItemProvider) {
        self.init(placeholderItem: itemProvider.placeholderItem, progressControllerMode: itemProvider.progressControllerMode, provideItemHandler: itemProvider.provideItemHandler, cancellationHandler: itemProvider.cancellationHandler)
    }

    override public func main() {
        if cancelled {
            finish()
        }
        provideItemHandler?(activityType: activityType ?? "", operation: self)
    }

    public func finishWithItem(item: AnyObject?) {

        if !cancelled {
        self.item = item
        }
        finish()
    }

    override public final func cancel() {
        super.cancel()
        if let cancelHandler = cancelHandler {
            cancelHandler(operation: self)
        } else {
            finish()
        }
    }

}