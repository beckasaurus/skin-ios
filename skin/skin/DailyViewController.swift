//
//  DailyViewController.swift
//  skin
//
//  Created by Becky on 1/30/18.
//  Copyright © 2018 Becky Henderson. All rights reserved.
//

import UIKit

// TODO:
// Display today's date
// If current day, get UV index forecast
// load next
// load previous

class DailyViewController: UIViewController {

	@IBOutlet weak var nextDay: UIButton!
	@IBOutlet weak var previousDay: UIButton!
	
	@IBOutlet weak var logDate: UILabel!
	@IBOutlet weak var uvIndex: UILabel!
	
	var dateFormatter: DateFormatter?
	
	weak var routineLog: DailyRoutineLogViewController?
	weak var status: DailyStatusViewController?
	
	override func viewDidLoad() {
		setupDateFormatter()
		loadLog(for: Date())
	}
	
	func setupDateFormatter() {
		if dateFormatter == nil {
			dateFormatter = DateFormatter()
			dateFormatter?.dateStyle = .short
			dateFormatter?.timeStyle = .none
		}
	}
	
	func loadLog(for date: Date) {
		
		logDate.text = dateFormatter?.string(from: date)
		
		let isDateToday = Calendar.current.isDateInToday(date)
		if isDateToday {
			loadUVIndex()
		}
	}
	
	func loadUVIndex() {
		//hit api to get uv index using today's date and location
		let forecastedIndex = 7
		uvIndex.text = "UV Index: \(forecastedIndex)"
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "dailyStatusSegue" {
			status = segue.destination as! DailyStatusViewController
		} else if segue.identifier == "dailyRoutineLogSegue" {
			routineLog = segue.destination as! DailyRoutineLogViewController
		}
	}
	
}
