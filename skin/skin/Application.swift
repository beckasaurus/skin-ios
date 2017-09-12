//
//  Application.swift
//  skin
//
//  Created by Becky on 9/11/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import RealmSwift
import Foundation

final class Application: Object {
	dynamic var notes = ""
	dynamic var time = Date()
	dynamic var routine: Routine?
}
