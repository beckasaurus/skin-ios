////
////  ApplicationProductSelectionViewController.swift
////  skin
////
////  Created by Becky Henderson on 11/15/17.
////  Copyright © 2017 Becky Henderson. All rights reserved.
////
//
//import UIKit
//import RealmSwift
//
//let applicationProductSelectionSegue = "applicationProductSelectionSegueIdentifier"
//
//class ApplicationProductSelectionViewController: StashViewController {
//	
//	public var applicationProductsList: List<Product>?
//
//	override func tableSelectionSegueIdentifier() -> String {
//		return applicationProductSelectionSegue
//	}
//	
//	func addProductToApplicationProductList(product: Product) {
//		guard let applicationProductsList = applicationProductsList else {
//			return
//		}
//		try? applicationProductsList.realm?.write {
//			applicationProductsList.insert(product, at: applicationProductsList.count)
//		}
//	}
//	
//	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//		let productToAdd = productForIndexPath(indexPath: indexPath)
//		addProductToApplicationProductList(product: productToAdd)
//		self.navigationController?.popViewController(animated: true)
//	}
//	
////	override func didAddProductToList(product: Product) {
////		addProductToApplicationProductList(product: product)
////		self.navigationController?.popViewController(animated: true)
////	}
//}

