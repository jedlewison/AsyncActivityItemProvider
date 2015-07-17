//
//  AsyncActivityItemProviderOperations.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/13/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import AsyncOpKit


final class PresentViewControllerOperation: AsyncOperation {

    weak var presentationContext: UIViewController?
    let presentedViewController: UIViewController

    required init(presentationContext: UIViewController?, presentedViewController: UIViewController) {
        self.presentationContext = presentationContext
        self.presentedViewController = presentedViewController
        super.init()
    }

    override func main() {
        dispatch_async(dispatch_get_main_queue()) {
            if let presentationContext = self.presentationContext {
                presentationContext.presentViewController(self.presentedViewController, animated: true) {
                    self.finish()
                }
            } else {
                self.finish()
            }
        }
    }
}



final class DismissViewControllerOperation: AsyncOperation {

    weak var presentedViewController: UIViewController?

    required init(presentedViewController: UIViewController?) {
        self.presentedViewController = presentedViewController
        super.init()
    }

    override func main() {
        dispatch_async(dispatch_get_main_queue()) {
            if let presentedViewController = self.presentedViewController {
                presentedViewController.dismissViewControllerAnimated(true) {
                    self.finish()
                }
            } else {
                self.finish()
            }
        }
    }
}