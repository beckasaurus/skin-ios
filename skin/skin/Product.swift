//
//  Product.swift
//  skin
//
//  Created by Becky on 9/11/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import Foundation
import RealmSwift

final class Product: Object {
	dynamic var name = ""
	dynamic var brand = ""
	var price: RealmOptional<Double> = RealmOptional()
	dynamic var expirationDate: Date?
	dynamic var category: String = ProductCategory.active.rawValue
}

