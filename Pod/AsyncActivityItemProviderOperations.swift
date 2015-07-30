//
//  AsyncActivityItemProviderOperations.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/13/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import AsyncOpKit

final class StartBackgroundOperation: AsyncOperation {
    var backgroundTaskID: UIBackgroundTaskIdentifier?
    override func main() {
        dispatch_async(dispatch_get_main_queue()) {
            self.backgroundTaskID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
                if let backgroundTaskID = self.backgroundTaskID {
                    self.backgroundTaskID = nil
                    UIApplication.sharedApplication().endBackgroundTask(backgroundTaskID)
                }
            }
            self.finish()
        }
    }
}

final class EndBackgroundOperation: AsyncOperation {
    override func main() {
        dispatch_async(dispatch_get_main_queue()) {
            for dependency in self.dependencies {
                if let dependency = dependency as? StartBackgroundOperation, backgroundTaskID = dependency.backgroundTaskID {
                    UIApplication.sharedApplication().endBackgroundTask(backgroundTaskID)
                }
            }
            self.finish()
        }
    }
}

final class GuaranteeAppIsInForegroundOperation: AsyncOperation {
    override func main() {
        if cancelled || UIApplication.sharedApplication().applicationState == .Active {
            finish()
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("applicationDidBecomeActive"), name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
        }
    }

    func applicationDidBecomeActive() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        finish()
    }

    override func cancel() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.cancel()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}


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