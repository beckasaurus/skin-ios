//
//  RoutineLog.swift
//  skin
//
//  Created by Becky on 9/11/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import RealmSwift
import Foundation

final class RoutineLog: Object {
	dynamic var id = ""
	dynamic var name = ""
	dynamic var notes = ""
	dynamic var time = Date()
	var products = List<Product>()

	override static func primaryKey() -> String? {
		return "id"
	}
}
