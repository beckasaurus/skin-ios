//
//  String+RangeFromNSRange.swift
//  skin
//
//  Created by Becky on 11/8/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import Foundation

extension String {
	func range(from nsRange: NSRange) -> Range<String.Index>? {
		guard
			let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
			let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
			let from = String.Index(from16, within: self),
			let to = String.Index(to16, within: self)
			else { return nil }
		return from ..< to
	}
}
