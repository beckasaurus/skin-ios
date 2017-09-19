//
//  ProductCategory.swift
//  skin
//
//  Created by Becky Henderson on 9/19/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

enum ProductCategory: String {
	case cleanser
	case active
	case hydrator
	case occlusive
	case sunscreen
	case treatment
	
	static let allCases: [ProductCategory] = [.cleanser, .active, .hydrator, .occlusive, .sunscreen, .treatment]
}
