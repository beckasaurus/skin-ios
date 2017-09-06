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
	var realm: Realm!
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	func setupUI() {
		title = routine?.name
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: routineProductCellIdentifier)
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
		navigationItem.leftBarButtonItem = editButtonItem
	}
	
	func setupRealm() {
		// Notify us when Realm changes
		self.notificationToken = self.products.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
			guard let tableView = self?.tableView else { return }
			
			switch changes {
			case .initial:
				tableView.reloadData()
			case .update(_, let deletions, let insertions, let modifications):
				tableView.beginUpdates()
				tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
				                     with: .automatic)
				tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
				                     with: .automatic)
				tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
				                     with: .automatic)
				tableView.endUpdates()
			case .error(let error):
				// An error occurred while opening the Realm file on the background worker thread
				fatalError("\(error)")
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
		return (routine != nil) ? products.count : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: routineProductCellIdentifier, for: indexPath)
		let item = products[indexPath.row]
		cell.textLabel?.text = item.name
        return cell
    }
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		try! products.realm?.write {
			products.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
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
			try! items.realm?.write {
				items.insert(Product(value: ["name": text]), at: items.count)
			}
		})
		present(alertController, animated: true, completion: nil)
	}
	
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
