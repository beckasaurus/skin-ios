//
//  LogTableViewController.swift
//  skin
//
//  Created by Becky Henderson on 8/28/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

final class ProductList: Object {
	dynamic var text = ""
	dynamic var id = ""
	let items = List<Product>()
	
	override static func primaryKey() -> String? {
		return "id"
	}
}

final class Product: Object {
	dynamic var name = ""
}

let logProductCellIdentifier = "logProduct"

class LogTableViewController: UITableViewController {

	var items = List<Product>()
	
	// MARK - Realm Properties
	var notificationToken: NotificationToken!
	var realm: Realm!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
		setupRealm()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
	func setupUI() {
		title = "Daily Log"
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: logProductCellIdentifier)
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
		navigationItem.leftBarButtonItem = editButtonItem
	}
	
	func setupRealm() {
		guard let jsonURL = Bundle.main.url(forResource: "credentials", withExtension: "json")
			else {fatalError("Bundle must include credentials.json file contain Realm credentials")}
		
		do {
			let jsonData = try Data(contentsOf: jsonURL)
			
			let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments)
			
			if let jsonDict = jsonObject as? [String:String] {
				let username = jsonDict["username"]!
				let password = jsonDict["password"]!
				
				loginToRealm(username: username, password: password)
			}
		} catch let error  {
			fatalError(error.localizedDescription)
		}
	}
	
	func loginToRealm(username: String, password: String) {
		guard let serverURL = URL(string: "http://127.0.0.1:9080")
			else { return }
		
		let credentials = SyncCredentials.usernamePassword(username: username, password: password, register: false)
		
		SyncUser.logIn(with: credentials, server: serverURL) { user, error in
			guard let user = user else {
				fatalError(String(describing: error))
			}
			
			DispatchQueue.main.async {
				// Open Realm
				let configuration = Realm.Configuration(
					syncConfiguration: SyncConfiguration(user: user, realmURL: URL(string: "realm://127.0.0.1:9080/~/skin")!)
				)
				self.realm = try! Realm(configuration: configuration)
				
				if self.realm.isEmpty {
					try! self.realm.write {
						let productList = ProductList()
						productList.id = ""
						productList.text = "Daily Log"
						self.realm.add(productList)
					}
				}
				
				// Show initial tasks
				func updateList() {
					if self.items.realm == nil, let list = self.realm.objects(ProductList.self).first {
						self.items = list.items
					}
					self.tableView.reloadData()
				}
				updateList()
				
				// Notify us when Realm changes
				self.notificationToken = self.realm.addNotificationBlock { _ in
					updateList()
				}
			}
		}
	}
	
	deinit {
		notificationToken.stop()
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
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: logProductCellIdentifier, for: indexPath)
		let item = items[indexPath.row]
		cell.textLabel?.text = item.name
        return cell
    }
	
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		try! items.realm?.write {
			items.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
		}
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! realm.write {
				let item = items[indexPath.row]
				realm.delete(item)
			}
		}
	}
	
	// MARK: - Add functions
	
	func add() {
		let alertController = UIAlertController(title: "Add Product To Daily Log", message: "Enter Product Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Product Name"
		}
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let items = self.items
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
