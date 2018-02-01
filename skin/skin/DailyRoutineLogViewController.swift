//
//  DailyRoutineLogViewController.swift
//  skin
//
//  Created by Becky on 1/30/18.
//  Copyright © 2018 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

// Button to add routine
// Suggest routine if one is scheduled for day
// Display routine with products and button to add products

enum DailyRoutineLogViewControllerError: Error {
	case invalidDate
}

class DailyRoutineLogViewController: UIViewController {
	
	@IBOutlet weak var routineLogTableView: UITableView!

	var routineLogs: Results<RoutineLog>?

	func getRoutines(for date: Date) {
		if let currentDatePredicate = try? predicate(for: date),
			let logs = realm?.objects(RoutineLog.self).filter(currentDatePredicate).sorted(byKeyPath: "time") {
			routineLogs = logs
			
			routineLogTableView.reloadData()
			
		}
	}
	
	func predicate(for date: Date) throws -> NSPredicate {
		guard let nextDayBegin = Calendar.current.date(bySettingHour: 00, minute: 00, second: 00, of: date),
			let nextDayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)
			else { throw DailyRoutineLogViewControllerError.invalidDate }
		
		return NSPredicate(format: "time >= %@ AND time <= %@", nextDayBegin as CVarArg, nextDayEnd as CVarArg)
	}
}

extension DailyRoutineLogViewController: DateChangeable {
	func didChangeDate(to date: Date) {
		getRoutines(for: date)
	}
}

// MARK: Add Routine
extension DailyRoutineLogViewController {
	@IBAction func addRoutineLog(sender: UIButton) {
		let routineLog = RoutineLog()
		routineLog.id = UUID().uuidString
		routineLog.time = Date()
		routineLog.name = "AM"
		
		try! realm?.write {
			realm?.add(routineLog)
		}
		
		routineLogTableView.reloadData()
	}
}

extension DailyRoutineLogViewController: UITableViewDelegate {
	
}

extension DailyRoutineLogViewController: UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return routineLogs?.count ?? 0
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let routineLog = routineLogs?[section] else {
			return 0
		}
		
		return routineLog.products.count
		
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let reuseIdentifier = "routineLogProductCell"
		
		let cell: UITableViewCell
		if let tableCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) {
			cell = tableCell
		} else {
			cell = UITableViewCell(style: .subtitle,
								   reuseIdentifier: reuseIdentifier)
		}
		
		let sectionIndex = indexPath.section
		let routineLog = routineLogs?[sectionIndex]
		let product = routineLog?.products[indexPath.row]
		cell.textLabel?.text = product?.name ?? ""
		cell.detailTextLabel?.text = product?.brand ?? ""
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let routineLog = routineLogs?[section]
		return routineLog?.name
	}

//	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//		if editingStyle == .delete {
//			try! self.realm?.write {
//				let item = applications![indexPath.row]
//				self.realm?.delete(item)
//			}
//		}
//	}
}
