//
//  RoutineTableViewController
//  skin
//
//  Created by Becky Henderson on 8/28/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let routineProductCellIdentifier = "routineProduct"

class RoutineTableViewController: UITableViewController {

	var products: List<Product> {
		return routine!.products
	}
	var routine: Routine?
	
	// MARK: - Realm Properties
	var notificationToken: NotificationToken?
	var realm: Realm! {
		return routine!.realm!
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupUI()
		setupRealm()
	}
	
	func setupUI() {
		title = routine?.name
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: routineProductCellIdentifier)
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	func setupRealm() {
		// Notify us when Realm changes
		self.notificationToken = self.products.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
			DispatchQueue.main.async {
				guard let tableView = self?.tableView else { return }
				
				switch changes {
				case .initial:
					tableView.reloadData()
				case .update(_, let deletions, let insertions, let modifications):
					tableView.beginUpdates()
					tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
					                     with: .none)
					tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
					                     with: .none)
					tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
					                     with: .none)
					tableView.endUpdates()
				case .error(let error):
					// An error occurred while opening the Realm file on the background worker thread
					fatalError("\(error)")
				}
			}
		}
	}
	
	deinit {
		notificationToken?.stop()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: routineProductCellIdentifier, for: indexPath)
		let item = products[indexPath.row]
		cell.textLabel?.text = item.name
        return cell
    }
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		realm.beginWrite()
		products.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
		try! realm.commitWrite(withoutNotifying: [notificationToken!])
	}
	
	// MARK: - Edit function
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if editing {
			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
		} else {
			navigationItem.leftBarButtonItem = nil
		}
	}

	
	// MARK: - Delete function
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! realm.write {
				let item = products[indexPath.row]
				realm.delete(item)
			}
		}
	}
	
	// MARK: - Add function
	
	func add() {
		let alertController = UIAlertController(title: "Add Product To Daily Log", message: "Enter Product Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Product Name"
		}
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let items = self.products
			try! self.realm.write {
				items.insert(Product(value: ["name": text]), at: items.count)
			}
		})
		present(alertController, animated: true, completion: nil)
	}
}
