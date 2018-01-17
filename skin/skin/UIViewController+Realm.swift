//
//  UIViewController+Realm.swift
//  skin
//
//  Created by Becky Henderson on 1/17/18.
//  Copyright © 2018 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

extension UIViewController {
	var realm: Realm? {
		return (UIApplication.shared.delegate! as! AppDelegate).realm
	}
}
