//
//  Stash.swift
//  skin
//
//  Created by Becky Henderson on 9/19/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import RealmSwift

final class Stash: Object {
	var products = List<Product>()
}
