////
////  ApplicationTableViewController
////  skin
////
////  Created by Becky Henderson on 8/28/17.
////  Copyright © 2017 Becky Henderson. All rights reserved.
////
//
//import UIKit
//import RealmSwift
//
//let applicationProductCellIdentifier = "applicationProduct"
////FIXME: not used?
//let noApplicationSelectedSegue = "noApplicationSelectedSegue"
//let addProductToApplicationSegue = "addProductToApplicationSegue"
//let applicationUnwindSegue = "applicationUnwindSegue"
//
//protocol ApplicationDelegate: class {
//	func didAdd(application: Application)
//}
//
////TODO: change name?
//class ApplicationViewController: UIViewController {
//
//	weak var delegate: ApplicationDelegate?
//
//	@IBOutlet weak var nameTextField: UITextField!
//	@IBOutlet weak var timeTextField: UITextField!
//	@IBOutlet weak var notesTextView: UITextView!
//	@IBOutlet weak var tableView: UITableView!
//	@IBOutlet weak var editDoneButton: UIButton!
//	
//	var dateFormatter: DateFormatter?
//	
//	var application: Application?
//
//	override func viewWillAppear(_ animated: Bool) {
//		super.viewWillAppear(animated)
//		setupNavigationButtons()
//		setupFields()
//		createApplicationIfNeeded()
//	}
//
//	override func viewWillDisappear(_ animated: Bool) {
//		super.viewWillDisappear(animated)
//		//FIXME: this will be called twice if we're clicking done (once when we segue, once when our view goes away)
//		updateApplicationFromUI()
//	}
//}
//
//// MARK: set up UI
//extension ApplicationViewController {
//	/// This adds Add/Cancel buttons to the navigation bar if the user is adding a new application, or a Back button if the application already exists.
//	/// This must be called before setting up a new application model.
//	func setupNavigationButtons() {
//		//new application
//		if (application == nil) {
//			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
//			navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
//		}
//	}
//
//	func setupFields() {
//		title = application?.name
//		tableView.register(UITableViewCell.self, forCellReuseIdentifier: applicationProductCellIdentifier)
//
//		setupTimeField()
//
//		loadUIFromApplication()
//	}
//
//	func setupDatePicker() {
//		let datePicker = UIDatePicker()
//		datePicker.datePickerMode = .time
//		datePicker.minuteInterval = 5
//		datePicker.addTarget(self, action: #selector(timeChanged(_:)), for: .valueChanged)
//		timeTextField.inputView = datePicker
//	}
//
//	func setupDateFormatter() {
//		dateFormatter = DateFormatter()
//		dateFormatter!.dateStyle = .none
//		dateFormatter!.timeStyle = .short
//	}
//
//	func setupTimeField() {
//		setupDateFormatter()
//		setupDatePicker()
//	}
//}
//
//// MARK: Create new application
//extension ApplicationViewController {
//	func createApplicationIfNeeded() {
//		if application == nil {
//			try! realm?.write {
//				//FIXME: option to choose from existing routine before creating a new application
//				let newApplication = Application(value: ["id" :	NSUUID().uuidString,
//														 "name" : "",
//														 "notes" : "",
//														 "time" : dateFormatter!.date(from: timeTextField.text ?? "") ?? Date()])
//				realm?.add(newApplication)
//				application = newApplication
//			}
//		}
//	}
//}
//
//// MARK: Load fields from Application
//extension ApplicationViewController {
//	func loadUIFromApplication() {
//		loadName()
//		loadNotes()
//		loadTime()
//	}
//
//	func loadName() {
//		nameTextField?.text = application?.name ?? ""
//	}
//
//	func loadNotes() {
//		notesTextView?.text = application?.notes ?? ""
//	}
//
//	func loadTime() {
//		if let applicationTime = application?.time {
//			timeTextField.text = dateFormatter!.string(from: applicationTime)
//			(timeTextField.inputView as? UIDatePicker)?.setDate(applicationTime, animated: false)
//		}
//	}
//}
//
//// MARK: Load Application from fields
//extension ApplicationViewController {
//	/// Note: This product list is saved as it's changed/edited so it does not need to be handled here
//	func updateApplicationFromUI() {
//		try! realm?.write {
//			application?.name = nameTextField.text ?? ""
//			application?.notes = notesTextView.text ?? ""
//
//			if let time = timeTextField.text,
//				let applicationDate = dateFormatter!.date(from: time) {
//				application?.time = applicationDate
//			}
//		}
//	}
//}
//
//// MARK: User actions
//extension ApplicationViewController {
//	@IBAction func editDoneButtonToggled(_ sender: UIButton) {
//		if tableView.isEditing {
//			tableView.setEditing(false, animated: true)
//			editDoneButton.setTitle("Edit", for: .normal)
//		} else {
//			tableView.setEditing(true, animated: true)
//			editDoneButton.setTitle("Done", for: .normal)
//		}
//	}
//
//	func deleteProduct(at indexPath: IndexPath) {
//		try! realm?.write {
//			let item = application!.products[indexPath.row]
//			realm?.delete(item)
//		}
//	}
//
//	func timeChanged(_ sender: Any) {
//		let datePicker = timeTextField.inputView! as! UIDatePicker
//		let date = datePicker.date
//		timeTextField.text = dateFormatter!.string(from: date)
//	}
//
//	func done(sender: UIBarButtonItem) {
//		updateApplicationFromUI()
//		delegate?.didAdd(application: application!)
//		performSegue(withIdentifier: applicationUnwindSegue, sender: self)
//	}
//
//	func cancel(sender: UIBarButtonItem) {
//		application = nil
//		performSegue(withIdentifier: applicationUnwindSegue, sender: self)
//	}
//}
//
//// MARK: UITableViewDataSource
//extension ApplicationViewController: UITableViewDataSource {
//	func numberOfSections(in tableView: UITableView) -> Int {
//		return 1
//	}
//	
//	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		return application?.products.count ?? 0
//	}
//	
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//		let cell = tableView.dequeueReusableCell(withIdentifier: applicationProductCellIdentifier, for: indexPath)
//		let item = application!.products[indexPath.row]
//		cell.textLabel?.text = item.name
//		return cell
//	}
//	
//	func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//		return true
//	}
//	
//	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//		realm?.beginWrite()
//		application!.products.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
//		try! realm?.commitWrite()
//	}
//	
//	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//		if editingStyle == .delete {
//			deleteProduct(at: indexPath)
//		}
//	}
//	
//	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		if segue.identifier == addProductToApplicationSegue {
//			let applicationProductSelectionViewController = segue.destination as! ApplicationProductSelectionViewController
//			applicationProductSelectionViewController.applicationProductsList = application!.products
//		}
//	}
//}

