//
//  Log.swift
//  skin
//
//  Created by Becky on 9/11/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import RealmSwift
import Foundation

final class Log: Object {
	dynamic var date = Date()
	dynamic var id: String?
	var applications = List<Application>()
	
	override static func primaryKey() -> String? {
		return "id"
	}
}
