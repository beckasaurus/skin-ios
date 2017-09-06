//
//  DailyLogTableViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/5/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

let routineCellIdentifier = "routine"
let routineSegue = "routineSegue"

final class DailyLog: Object {
	dynamic var date = Date()
	dynamic var id: String?
	var performedRoutines = List<PerformedRoutine>()
	
	override static func primaryKey() -> String? {
		return "id"
	}
}

final class PerformedRoutine: Object {
	dynamic var notes = ""
	dynamic var routine: Routine?
}

final class Routine: Object {
	dynamic var name = ""
	dynamic var id = ""
	var products = List<Product>()
	
	override static func primaryKey() -> String? {
		return "id"
	}
}

final class Product: Object {
	dynamic var name = ""
}

class DailyLogTableViewController: UITableViewController {

	var date = Date()
	
	// MARK: - Realm Properties
	var notificationToken: NotificationToken!
	var realm: Realm? {
		return (UIApplication.shared.delegate! as! AppDelegate).realm
	}
	var performedRoutines = List<PerformedRoutine>()
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
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
		navigationItem.leftBarButtonItem = editButtonItem
	}
	
	func setupRealm() {
		if self.realm!.objects(DailyLog.self).count < 1 {
			try! self.realm!.write {
				let dailyLog = DailyLog()
				dailyLog.date = date
				dailyLog.id = String(date.timeIntervalSince1970)
				self.realm!.add(dailyLog)
			}
		}
		
		// Show initial tasks
		func updatePerformedRoutineList() {
			if self.performedRoutines.realm == nil, let list = self.realm!.objects(DailyLog.self).first {
				self.performedRoutines = list.performedRoutines
			}
			self.tableView.reloadData()
		}
		updatePerformedRoutineList()
		
		// Notify us when Realm changes
		self.notificationToken = self.realm!.addNotificationBlock { _ in
			updatePerformedRoutineList()
		}
		
		setupUI()
	}
	
	deinit {
		notificationToken.stop()
		realmConnectedNotification = nil
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
        return performedRoutines.count
    }

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: routineCellIdentifier, for: indexPath)
		let performedRoutine = performedRoutines[indexPath.row]
		cell.textLabel?.text = performedRoutine.routine!.name
		return cell
    }
	

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		try! performedRoutines.realm?.write {
			performedRoutines.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
		}
	}
	
	// MARK: - Delete function
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! self.realm?.write {
				let item = performedRoutines[indexPath.row]
				self.realm?.delete(item)
			}
		}
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
		if segue.identifier == routineSegue {
			let cell = sender as! UITableViewCell
			let rowIndexPath = tableView.indexPath(for: cell)!
			let performedRoutine = performedRoutines[rowIndexPath.first!]
			let routineViewController = segue.destination as! RoutineTableViewController
			routineViewController.routine = performedRoutine.routine!
		}
    }
	
	func add() {
		let alertController = UIAlertController(title: "Add Routine To Daily Log", message: "Enter Routine Name", preferredStyle: .alert)
		var alertTextField: UITextField!
		alertController.addTextField { textField in
			alertTextField = textField
			textField.placeholder = "Routine Name"
		}
		alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
			guard let text = alertTextField.text , !text.isEmpty else { return }
			
			let performedRoutines = self.performedRoutines
			try! performedRoutines.realm?.write {
				let newRoutine = Routine(value: ["name": text, "id" : NSUUID().uuidString])
				let newPerformedRoutine = PerformedRoutine(value: ["notes": "", "routine": newRoutine])
				performedRoutines.insert(newPerformedRoutine,
				             at: performedRoutines.count)
			}
			
			//segue to new view
		})
		present(alertController, animated: true, completion: nil)
	}

}
