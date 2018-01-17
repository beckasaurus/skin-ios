//
//  DailyLogViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/5/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let applicationCellIdentifier = "application"
let applicationSegue = "applicationSegue"
let changedLogDateNotificationName = Notification.Name("changedLogDate")

enum LogError: Error {
	case invalidDate
}

//TODO: sort applications by time when displaying, writing and inserting

class DailyLogViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var dateLabel: UILabel!
	
	var log: Log? {
		didSet {
			let formatter = DateFormatter()
			formatter.dateStyle = .medium
			dateLabel.text = formatter.string(from: log!.date)
		}
	}
	
	var applications: List<Application>? {
		return log?.applications
	}
	
	var realmConnectedNotification: NSObjectProtocol?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		realmConnectedNotification = NotificationCenter.default.addObserver(forName: realmConnected, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
			self?.setupRealm()
		}
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
		let currentDatePredicate = try! predicate(for: Date()) //default to current date
		if let log = self.realm!.objects(Log.self).filter(currentDatePredicate).first {
			self.log = log
		} else {
			createNewLog(date: Date())
		}
		
		updatePerformedRoutineList()
	}
	
	deinit {
		realmConnectedNotification = nil
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == applicationSegue {
			let cell = sender as! UITableViewCell
			let rowIndexPath = tableView.indexPath(for: cell)!
			let application = applications![rowIndexPath.row]
			let navController = segue.destination as! UINavigationController
			let applicationViewController = navController.topViewController as! ApplicationViewController
			applicationViewController.application = application
			
			applicationViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
			applicationViewController.navigationItem.leftItemsSupplementBackButton = true
		}
	}
	
	// MARK: - Changing dates
	
	func predicate(for date: Date) throws -> NSPredicate {
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
			let datePredicate = try predicate(for: nextDay)
			if let nextLog = realm!.objects(Log.self).filter(datePredicate).first {
				log = nextLog
			} else {
				createNewLog(date: nextDay)
			}
			
			updatePerformedRoutineList()
			
			NotificationCenter.default.post(name: changedLogDateNotificationName, object: self)
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

extension DailyLogViewController: UITableViewDataSource {
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
}
