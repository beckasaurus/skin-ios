//
//  WishList.swift
//  skin
//
//  Created by Becky Henderson on 11/7/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import RealmSwift

final class WishList: Object {
	var products = List<Product>()
}
