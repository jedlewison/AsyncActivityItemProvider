//
//  UIActivityViewControllerExtension.swift
//  AsyncActivityItemProvider
//
//  Created by Jed Lewison on 7/12/15.
//  Copyright (c) 2015 Magic App Factory. All rights reserved.
//

import UIKit
//TODO: Turn this into a parameter object style initializer
public extension UIActivityViewController {
    
    convenience init(possiblyAsyncActivityItems: [AnyObject], applicationActivities: [AnyObject]?) {
        self.init(activityItems: possiblyAsyncActivityItems, applicationActivities: nil)
    }
    
}