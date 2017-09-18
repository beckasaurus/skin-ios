//
//  LogSplitViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/18/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit

let emptySelectionViewControllerIdentifier = "emptySelectionVC"

class LogSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		delegate = self
		
		//this doesn't actually work? being overridden by detail view?
		navigationItem.leftBarButtonItem = displayModeButtonItem
		navigationItem.leftItemsSupplementBackButton = true
	}
	
	///determines which view should show when collapsing down to one
	func splitViewController(_ splitViewController: UISplitViewController,
	                         collapseSecondary secondaryViewController: UIViewController,
	                         onto primaryViewController: UIViewController) -> Bool {
		guard let navigationController = secondaryViewController as? UINavigationController,
			let secondaryController = navigationController.topViewController
			else {return true}
		
		if let applicationController = secondaryController as? ApplicationViewController,
			applicationController.routine == nil {
			return true
		} else if secondaryController.restorationIdentifier == emptySelectionViewControllerIdentifier {
			return true
		}
		
		return false
	}
	
	///determines what view to show for detail when moving from one view to two
	func splitViewController(_ splitViewController: UISplitViewController,
	                         separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
		//we had no selection
		if let navigationController = primaryViewController as? UINavigationController,
			let controller = navigationController.topViewController,
			let logController = controller as? DailyLogViewController,
		    logController.tableView.indexPathForSelectedRow == nil
		{
			return storyboard?.instantiateViewController(withIdentifier: emptySelectionViewControllerIdentifier)
		}
		
		return nil
	}
}
