//
//  DailyLogTableViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/5/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let applicationCellIdentifier = "application"
let applicationSegue = "applicationSegue"

class DailyLogTableViewController: UITableViewController {

	var date = Date()
	var log: Log?
	var applications: List<Application>? {
		return log?.applications
	}
	
	// MARK: - Realm Properties
	var notificationToken: NotificationToken!
	var realm: Realm? {
		return (UIApplication.shared.delegate! as! AppDelegate).realm
	}
	var realmConnectedNotification: NSObjectProtocol?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
		
		realmConnectedNotification = NotificationCenter.default.addObserver(forName: realmConnected, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
			self?.setupRealm()
		}
    }
	
	func setupUI() {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		title = formatter.string(from: date)
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPerformedRoutine))
		navigationItem.leftBarButtonItem = editButtonItem
	}
	
	func updatePerformedRoutineList() {
		self.tableView.reloadData()
	}
	
	func createNewLog(date: Date) {
		try! self.realm!.write {
			let dailyLog = Log()
			dailyLog.date = date
			dailyLog.id = String(date.timeIntervalSince1970)
			self.realm!.add(dailyLog)
		}
	}
	
	func setupRealm() {
		if self.realm!.objects(Log.self).count < 1 {
			createNewLog(date: Date())
		}
		
		let predicate = NSPredicate(format: "date <= %@", date as CVarArg)
		log = self.realm!.objects(Log.self).filter(predicate).last
		
		updatePerformedRoutineList()
		
		// Notify us when Realm changes
		self.notificationToken = self.realm!.addNotificationBlock { [weak self] _ in
			self?.updatePerformedRoutineList()
		}
	}
	
	deinit {
		notificationToken.stop()
		realmConnectedNotification = nil
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applications?.count ?? 0
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: applicationCellIdentifier, for: indexPath)
		let application = applications![indexPath.row]
		cell.textLabel?.text = application.routine!.name
		return cell
    }

	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		try! applications!.realm?.write {
			applications!.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
		}
	}
	
	// MARK: - Delete function
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! self.realm?.write {
				let item = applications![indexPath.row]
				self.realm?.delete(item)
			}
		}
	}

	// MARK: - Add function
	
	func addPerformedRoutine() {
		let alertController = UIAlertController(title: "Add Routine To Daily Log", message: "Enter Routine Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Routine Name"
		}
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
			guard let strongSelf = self else { return }
			
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let log = strongSelf.log!
			try! log.realm?.write {
				let newRoutine = Routine(value: ["name": text, "id" : NSUUID().uuidString])
				
				let now = Date()
				let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: now)
				let nowTimeWithDate = Calendar.current.date(byAdding: timeComponents, to: strongSelf.date)!
				
				let newApplication = Application(value: ["notes": "",
				                                         "routine": newRoutine,
				                                         "time" : nowTimeWithDate])
				log.applications.insert(newApplication,
				             at: strongSelf.applications!.count)
				
				DispatchQueue.main.async {
					let newTableCell = strongSelf.tableView.cellForRow(at: IndexPath(row: log.applications.count - 1, section: 0))
					strongSelf.performSegue(withIdentifier: applicationSegue, sender: newTableCell)
				}
			}
		})
		present(alertController, animated: true, completion: nil)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if segue.identifier == applicationSegue {
			let cell = sender as! UITableViewCell
			let rowIndexPath = tableView.indexPath(for: cell)!
			let application = applications![rowIndexPath.row]
			let routineViewController = segue.destination as! ApplicationTableViewController
			routineViewController.application = application
		}
	}
	
	@IBAction func swipeRight(_ sender: UISwipeGestureRecognizer) {
		
		var dayComponent = DateComponents()
		dayComponent.day = 1
		
		guard let nextDate = Calendar.current.date(byAdding: dayComponent, to: date)
			else { return }
		
		let predicate = NSPredicate(format: "date <= %@", nextDate as CVarArg)
		if let nextLog = realm!.objects(Log.self).filter(predicate).last {
			log = nextLog
		} else {
			createNewLog(date: nextDate)
		}
		
		updatePerformedRoutineList()
	}
	
	@IBAction func swipeLeft(_ sender: UISwipeGestureRecognizer) {
		
	}

}
