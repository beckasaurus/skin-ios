//
//  LogSplitViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/18/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit

let emptyApplicationSelectionViewControllerIdentifier = "emptyApplicationSelectionVC"

class LogSplitViewController: UISplitViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		delegate = self
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(displayEmptySelectionViewInDetailController),
		                                       name: changedLogDateNotificationName,
		                                       object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if self.viewControllers.count > 1 { // showing detail
			let navController = self.viewControllers.last as! UINavigationController
			let detailController = navController.topViewController!
			detailController.navigationItem.leftBarButtonItem = displayModeButtonItem
			detailController.navigationItem.leftItemsSupplementBackButton = true
		}
	}
	
	func displayEmptySelectionViewInDetailController() {
		if self.viewControllers.count > 1 { // showing detail
			let emptySelectionViewController = storyboard!.instantiateViewController(withIdentifier: emptyApplicationSelectionViewControllerIdentifier)
			showDetailViewController(emptySelectionViewController, sender: self)
		}
	}
}

extension LogSplitViewController: UISplitViewControllerDelegate {
	///determines which view should show when collapsing down to one
	func splitViewController(_ splitViewController: UISplitViewController,
	                         collapseSecondary secondaryViewController: UIViewController,
	                         onto primaryViewController: UIViewController) -> Bool {
		guard let navigationController = secondaryViewController as? UINavigationController,
			let secondaryController = navigationController.topViewController
			else {return true}
		
		if let applicationController = secondaryController as? ApplicationViewController,
			applicationController.application == nil {
			return true
		} else if secondaryController.restorationIdentifier == emptyApplicationSelectionViewControllerIdentifier {
			return true
		}
		
		return false
	}
}
