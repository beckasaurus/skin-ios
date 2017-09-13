//
//  ApplicationTableViewController
//  skin
//
//  Created by Becky Henderson on 8/28/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let applicationProductCellIdentifier = "applicationProduct"

//TODO: change name?

class ApplicationTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

	@IBOutlet weak var datePicker: UIDatePicker!
	@IBOutlet weak var notesTextView: UITextView!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var editDoneButton: UIButton!
	
	var application: Application?
	var routine: Routine? {
		return application?.routine
	}
	var products: List<Product> {
		return routine!.products
	}
	
	// MARK: - Realm Properties
	var productListNotificationToken: NotificationToken?
	var timeAndNotesNotificationToken: NotificationToken?
	var realm: Realm! {
		return routine!.realm!
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupUI()
		setupRealm()
	}
	
	func setupUI() {
		title = routine?.name
		
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: applicationProductCellIdentifier)
		
		datePicker.date = application!.time
		notesTextView.text = application!.notes
	}
	
	func setupRealm() {
		// Notify us when Realm changes
		productListNotificationToken = products.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
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
		
		timeAndNotesNotificationToken = application?.addNotificationBlock({ [weak self] (change) in
			switch change {
			case .change(let propertyChanges):
				for propertyChange in propertyChanges {
					if propertyChange.name == "time" {
						self?.datePicker.date = propertyChange.newValue as! Date
					} else if propertyChange.name == "notes" {
						self?.notesTextView.text = propertyChange.newValue as! String
					}
				}
			default:
				print("other")
			}
		})
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		productListNotificationToken?.stop()
		timeAndNotesNotificationToken?.stop()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: applicationProductCellIdentifier, for: indexPath)
		let item = products[indexPath.row]
		cell.textLabel?.text = item.name
        return cell
    }
	
	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		realm.beginWrite()
		products.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
		try! realm.commitWrite(withoutNotifying: [productListNotificationToken!])
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			delete(at: indexPath)
		}
	}
	
	// MARK: - Edit function
	
	@IBAction func editDoneButtonToggled(_ sender: UIButton) {
		if tableView.isEditing {
			tableView.setEditing(false, animated: true)
			editDoneButton.setTitle("Edit", for: .normal)
		} else {
			tableView.setEditing(true, animated: true)
			editDoneButton.setTitle("Done", for: .normal)
		}
	}
	
	// MARK: - Delete function
	
	func delete(at indexPath: IndexPath) {
		try! realm.write {
			let item = products[indexPath.row]
			realm.delete(item)
		}
	}
	
	// MARK: - Add function
	
	@IBAction func add(_ sender: Any) {
		let alertController = UIAlertController(title: "Add Product To Application Log", message: "Enter Product Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Product Name"
		}
		
		alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
		
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let items = self.products
			try! self.realm.write {
				items.insert(Product(value: ["name": text]), at: items.count)
			}
		})
		
		present(alertController, animated: true, completion: nil)
	}
	
	//MARK: - Notes 
	
	func textViewDidEndEditing(_ textView: UITextView) {
		try! realm.write {
			application!.notes = textView.text
		}
	}
	
	//MARK: - Time
	
	@IBAction func timeChanged(_ sender: Any) {
		realm.beginWrite()
		application!.time = datePicker.date
		try! realm.commitWrite(withoutNotifying: timeAndNotesNotificationToken != nil ? [timeAndNotesNotificationToken!] : [])
	}
}
