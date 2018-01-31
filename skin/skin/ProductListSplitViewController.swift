//
////
////  ProductListSplitViewController.swift
////  skin
////
////  Created by Becky Henderson on 11/7/17.
////  Copyright © 2017 Becky Henderson. All rights reserved.
////
//
//import UIKit
//
//class ProductListSplitViewController: UISplitViewController {
//	
//	func emptySelectionViewControllerIdentifier() -> String {
//		assert(false, "Need to override empty selection view controller identifier name")
//		return ""
//	}
//	
//	override func viewDidLoad() {
//		super.viewDidLoad()
//		delegate = self
//	}
//	
//	override func viewWillAppear(_ animated: Bool) {
//		super.viewWillAppear(animated)
//		
//		if self.viewControllers.count > 1 { // showing detail
//			let navController = self.viewControllers.last as! UINavigationController
//			let detailController = navController.topViewController!
//			detailController.navigationItem.leftBarButtonItem = displayModeButtonItem
//			detailController.navigationItem.leftItemsSupplementBackButton = true
//		}
//	}
//	
//	func displayEmptySelectionViewInDetailController() {
//		if self.viewControllers.count > 1 { // showing detail
//			let emptySelectionViewController = storyboard!.instantiateViewController(withIdentifier: emptySelectionViewControllerIdentifier())
//			showDetailViewController(emptySelectionViewController, sender: self)
//		}
//	}
//}
//
//extension ProductListSplitViewController: UISplitViewControllerDelegate {
//	///determines which view should show when collapsing down to one
//	func splitViewController(_ splitViewController: UISplitViewController,
//	                         collapseSecondary secondaryViewController: UIViewController,
//	                         onto primaryViewController: UIViewController) -> Bool {
//		guard let navigationController = secondaryViewController as? UINavigationController,
//			let secondaryController = navigationController.topViewController
//			else {return true}
//		
//		if let productController = secondaryController as? ProductViewController,
//			productController.product == nil {
//			return true
//		} else if secondaryController.restorationIdentifier == emptySelectionViewControllerIdentifier() {
//			return true
//		}
//		
//		return false
//	}
//}

