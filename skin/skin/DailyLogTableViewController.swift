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

enum LogError: Error {
	case invalidDate
}

//TODO: sort applications by time when displaying, writing and inserting

class DailyLogTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet weak var tableView: UITableView!
	var log: Log? {
		didSet {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			title = formatter.string(from: log!.date)
		}
	}
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
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addPerformedRoutine))
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
			self.log = dailyLog
		}
	}
	
	func setupRealm() {
		let currentDatePredicate = try! predicate(date: Date()) //default to current date
		if let log = self.realm!.objects(Log.self).filter(currentDatePredicate).first {
			self.log = log
		} else {
			createNewLog(date: Date())
		}
		
		updatePerformedRoutineList()
		
		// Notify us when Realm changes
		self.notificationToken = self.log?.realm!.addNotificationBlock { [weak self] notification, realm in
			self?.updatePerformedRoutineList()
		}
	}
	
	deinit {
		notificationToken.stop()
		realmConnectedNotification = nil
	}

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return applications?.count ?? 0
    }

	
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: applicationCellIdentifier, for: indexPath)
		let application = applications![indexPath.row]
		cell.textLabel?.text = application.routine!.name
		
		let timeFormatter = DateFormatter()
		timeFormatter.timeStyle = .short
		timeFormatter.dateStyle = .none
		cell.detailTextLabel?.text = timeFormatter.string(from:  application.time)
		return cell
    }
	
	// MARK: - Delete function
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
				let nowTimeWithDate = Calendar.current.date(byAdding: timeComponents, to: strongSelf.log!.date)!
				
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
	
	func predicate(date: Date) throws -> NSPredicate {
		guard let nextDayBegin = Calendar.current.date(bySettingHour: 00, minute: 00, second: 00, of: date),
			let nextDayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)
			else { throw LogError.invalidDate }
		
		return NSPredicate(format: "date >= %@ AND date <= %@", nextDayBegin as CVarArg, nextDayEnd as CVarArg)
	}
	
	func changeDay(by days: Int) {
		var dayComponent = DateComponents()
		dayComponent.day = days
		guard let nextDay = Calendar.current.date(byAdding: dayComponent, to: log!.date)
			else { return }
		
		do {
			let datePredicate = try predicate(date: nextDay)
			if let nextLog = realm!.objects(Log.self).filter(datePredicate).first {
				log = nextLog
			} else {
				createNewLog(date: nextDay)
			}
			
			updatePerformedRoutineList()
		} catch {
			return
		}
	}
	
	@IBAction func swipeRight(_ sender: UIButton) {
		changeDay(by: 1)
	}
	
	@IBAction func swipeLeft(_ sender: UIButton) {
		changeDay(by: -1)
	}

}
