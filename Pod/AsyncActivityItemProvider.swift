//
//  AsyncActivityItemProvider.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/16/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import UIKit


typealias ProvideItemHandler = (activityType: String, operation: AsyncActivityItemProviderOperationController) -> ()
typealias CancellationHandler = (operation: AsyncActivityItemProviderOperationController) -> ()


protocol AsyncActivityItemProviderOperationController: NSObjectProtocol {
    func finishWithItem(item: AnyObject?)
    func finish()
    func cancel()
    var progress: Double { get set }
}


final class AsyncActivityItemProvider {

    enum ProgressControllerMode {
        case Enabled
        case Disabled
    }

    let provideItemHandler: ProvideItemHandler
    let cancellationHandler: CancellationHandler?
    let placeholderItem: AnyObject
    let progressControllerMode: ProgressControllerMode

    init(placeholderItem: AnyObject, provideItemHandler: ProvideItemHandler, cancellationHandler: CancellationHandler? = nil, progressControllerMode: ProgressControllerMode = .Enabled) {
        self.placeholderItem = placeholderItem
        self.provideItemHandler = provideItemHandler
        self.cancellationHandler = cancellationHandler
        self.progressControllerMode = progressControllerMode
    }

}


extension UIActivityViewController {

    convenience init(asyncItemProvider: AsyncActivityItemProvider, activityItems: [AnyObject]? = nil, applicationActivities: [AnyObject]? = nil) {
        var allActivityItems = [AsyncUIActivityItemProvider(itemProvider: asyncItemProvider) as AnyObject]
        if let activityItems = activityItems {
            allActivityItems.extend(activityItems)
        }

        self.init(activityItems: allActivityItems, applicationActivities: applicationActivities)
    }

}
