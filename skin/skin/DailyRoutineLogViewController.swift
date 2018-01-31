//
//  DailyRoutineLogViewController.swift
//  skin
//
//  Created by Becky on 1/30/18.
//  Copyright © 2018 Becky Henderson. All rights reserved.
//

import UIKit

// Button to add routine
// Suggest routine if one is scheduled for day
// Display routine with products and button to add products

class DailyRoutineLogViewController: UIViewController, DateChangeable {

	@IBOutlet weak var routineStackView: UIStackView!

	var routineLogs: List<RoutineLog>?

	func predicate(for date: Date) throws -> NSPredicate {
		guard let nextDayBegin = Calendar.current.date(bySettingHour: 00, minute: 00, second: 00, of: date),
			let nextDayEnd = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: date)
			else { throw LogError.invalidDate }

		return NSPredicate(format: "time >= %@ AND time <= %@", nextDayBegin as CVarArg, nextDayEnd as CVarArg)
	}

	func loadRoutines(for date: Date) {
		let currentDatePredicate = try? predicate(for: date)
		if let logs = realm.objects(RoutineLog.self).filter(currentDatePredicate).sorted(byKeyPath: "time") {
			routineLogs = logs
		}
	}

	func setupRoutineLogUI() {
		for routineLog in routineLogs {
			addTable(routineLog: routineLog)
		}
	}

	func addTable(routineLog: RoutineLog) {
		let table = RoutineLogTableView(routineLog: routineLog)
		table.delegate = self
		table.dataSource = self
		routineStackView.insertArrangedSubview(table, at: routineStackView.subviews.count - 1)
	}

	@IBAction func addRoutineLog(sender: UIButton) {
		let routineLog = RoutineLog()
		routineLog.time = Date()
		routineLog.name = "AM"

		realm.add(routineLog)

		routineLogs.a
	}

	func didChangeDate(to date: Date) {
		loadRoutines(for: date)
	}

}

extension DailyRoutineLogViewController: UITableViewDelegate {
	
}

extension DailyRoutineLogViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tableView.routineLog.products.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: applicationCellIdentifier, for: indexPath)
		let product = tableView.routineLog.products[indexPath.row]
		cell.textLabel?.text = product.name
		cell.detailTextLabel?.text = product.brand ?? ""
		return cell
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
