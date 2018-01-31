//
//  RoutineLogTableView.swift
//  skin
//
//  Created by Becky Henderson on 1/31/18.
//  Copyright © 2018 Becky Henderson. All rights reserved.
//

import UIKit

class RoutineLogTableView: UITableView {
	let routineLog: RoutineLog

	init(routineLog: RoutineLog) {
		super.init()
		self.routineLog = routineLog
	}
}
