//
//  StashViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/19/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let stashProductCellIdentifier = "stashProduct"
let stashProductSegue = "stashProductSegue"

class StashViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	
	var stash: Stash?
	var products: List<Product>? {
		return stash?.products
	}
	
	var realmConnectedNotification: NSObjectProtocol?
	var notificationToken: NotificationToken!
	var realm: Realm? {
		return (UIApplication.shared.delegate! as! AppDelegate).realm
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		
		if realm == nil {
			realmConnectedNotification = NotificationCenter.default.addObserver(forName: realmConnected, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
				self?.setupRealm()
			}
		} else {
			setupRealm()
		}
	}
	
	func setupUI() {
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProduct))
	}
	
	func updateStashList() {
		self.tableView.reloadData()
	}
	
	func createStash() {
		try! self.realm!.write {
			let stash = Stash()
			self.realm!.add(stash)
			self.stash = stash
		}
	}
	
	func setupRealm() {
		if let stash = self.realm!.objects(Stash.self).first {
			self.stash = stash
		} else {
			createStash()
		}
		
		updateStashList()
		
		// Notify us when Realm changes
		self.notificationToken = self.stash!.realm!.addNotificationBlock { [weak self] notification, realm in
			self?.updateStashList()
		}
	}
	
	deinit {
		notificationToken.stop()
		realmConnectedNotification = nil
	}
	
	// MARK: - Add function
	
	func addProduct() {
		let alertController = UIAlertController(title: "Add Product To Stash", message: "Enter Product Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Product Name"
		}
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
		
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
			guard let strongSelf = self else { return }
			
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let stash = strongSelf.stash!
			try! stash.realm?.write {
				let newProduct = Product(value: ["name": text])
				stash.products.insert(newProduct,
				                      at: strongSelf.products!.count)
				
				DispatchQueue.main.async {
					let newTableCell = strongSelf.tableView.cellForRow(at: IndexPath(row: stash.products.count - 1, section: 0))
					strongSelf.performSegue(withIdentifier: stashProductSegue, sender: newTableCell)
				}
			}
		})
		present(alertController, animated: true, completion: nil)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if segue.identifier == stashProductSegue {
			let cell = sender as! UITableViewCell
			let rowIndexPath = tableView.indexPath(for: cell)!
			let product = products![rowIndexPath.row]
			let navController = segue.destination as! UINavigationController
			let productViewController = navController.topViewController as! ProductViewController
			productViewController.product = product
			
			productViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
			productViewController.navigationItem.leftItemsSupplementBackButton = true
		}
	}
}

extension StashViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return products?.count ?? 0
	}
	
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: stashProductCellIdentifier, for: indexPath)
		let product = products![indexPath.row]
		cell.textLabel?.text = product.name
		cell.detailTextLabel?.text = product.brand
		return cell
	}
	
	// MARK: - Delete function
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! self.realm?.write {
				let item = products![indexPath.row]
				self.realm?.delete(item)
			}
		}
	}
}
