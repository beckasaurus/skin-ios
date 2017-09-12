//
//  Routine.swift
//  skin
//
//  Created by Becky on 9/11/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import RealmSwift
import Foundation

final class Routine: Object {
	dynamic var name = ""
	dynamic var id = ""
	var products = List<Product>()
	
	override static func primaryKey() -> String? {
		return "id"
	}
}
