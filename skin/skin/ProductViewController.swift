//
//  ProductViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/19/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

public enum ProductViewType {
	case stashProduct
	case wishListProduct
}

class ProductViewController: UIViewController {
	
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var brandTextField: UITextField!
	@IBOutlet weak var priceTextField: UITextField!
	@IBOutlet weak var expirationDateTextField: UITextField!
	@IBOutlet weak var categoryTextField: UITextField!
	
	@IBOutlet weak var linkStackView: UIStackView!
	@IBOutlet weak var expirationDateStackView: UIStackView!
	
	public var viewType: ProductViewType = .stashProduct
	
	var dateFormatter: DateFormatter?
	var currencyFormatter: NumberFormatter?
	
	var product: Product?
	
	var notificationToken: NotificationToken?
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupUI()
		setupRealm()
	}
	
	func setPriceText(with price: Double) {
		let number = NSNumber(value: price)
		let priceString = currencyFormatter!.string(from: number)
		
		priceTextField.text = priceString
	}
	
	func setExpirationDateText(with date: Date?) {
		guard case .stashProduct = viewType,
			let date = date
			else { return }
		
		expirationDateTextField.text = dateFormatter!.string(from: date)
	}
	
	func setupCurrencyFormatter() {
		currencyFormatter = NumberFormatter()
		currencyFormatter?.numberStyle = .currency
		currencyFormatter?.locale = Locale.current
		currencyFormatter?.maximumFractionDigits = 2
		currencyFormatter?.minimumFractionDigits = 2
	}
	
	func setupPriceField() {
		setupCurrencyFormatter()
		
		priceTextField.keyboardType = .numberPad
	}
	
	func setupDateFormatter() {
		dateFormatter = DateFormatter()
		dateFormatter!.dateStyle = .short
		dateFormatter!.timeStyle = .none
	}
	
	func setupExpirationDateField() {
		
		guard case .stashProduct = viewType else {
			expirationDateStackView.isHidden = true
			return
		}
		
		setupDateFormatter()
		
		let datePicker = UIDatePicker()
		datePicker.datePickerMode = .date
		datePicker.addTarget(self, action: #selector(expirationDateChanged(_:)), for: .valueChanged)
		if let expirationDate = product?.expirationDate {
			datePicker.setDate(expirationDate, animated: false)
		}
		expirationDateTextField.inputView = datePicker
	}
	
	func setupLinkField() {
		guard case .wishListProduct = viewType else {
			linkStackView.isHidden = true
			return
		}
	}
	
	func setupCategoryField() {
		let categoryPicker = UIPickerView()
		categoryPicker.delegate = self
		categoryPicker.dataSource = self
		if let rowNumForCategory = ProductCategory.allCases.index(of: ProductCategory(rawValue: (product?.category)!)!) {
			categoryPicker.selectRow(rowNumForCategory, inComponent: 0, animated: true)
		}
		categoryTextField.inputView = categoryPicker
	}

	func setTextFieldDataFromProduct() {
		brandTextField.text = product!.brand
		nameTextField.text = product!.name
		setPriceText(with: product!.price)
		setExpirationDateText(with: product!.expirationDate)
		categoryTextField.text = product!.category
	}
	
	func setupUI() {
		setupPriceField()
		setupCategoryField()
		setupExpirationDateField()
		setupLinkField()
		setTextFieldDataFromProduct()
	}
	
	func setupRealm() {
		notificationToken = product?.observe({ [weak self] (change) in
			switch change {
			case .change(let propertyChanges):
				for propertyChange in propertyChanges {
					if propertyChange.name == "name" {
						self?.nameTextField.text = (propertyChange.newValue as! String)
					} else if propertyChange.name == "brand" {
						self?.brandTextField.text = (propertyChange.newValue as! String)
					} else if propertyChange.name == "expirationDate" {
						let newDate: Date?
						if let changedDate = propertyChange.newValue as? Date {
							newDate = changedDate
						} else {
							newDate = nil
						}
						self?.setExpirationDateText(with: newDate)
					} else if propertyChange.name == "price" {
						
					} else if propertyChange.name == "category" {
						guard let newCategory = ProductCategory(rawValue: propertyChange.newValue as! String)
							else { return }
						
						self?.categoryTextField.text = newCategory.rawValue
					}
				}
			default:
				return
			}
		})
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		notificationToken?.invalidate()
	}
}

extension ProductViewController {
	func expirationDateChanged(_ sender: UIDatePicker) {
		let datePicker = expirationDateTextField.inputView! as! UIDatePicker
		let expirationDate = datePicker.date
		setExpirationDateText(with: expirationDate)
	}
}

extension ProductViewController: UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return ProductCategory.allCases.count
	}
}

extension ProductViewController: UIPickerViewDelegate {
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		let productCategory = ProductCategory.allCases[row]
		
		try! product!.realm?.write {
			product!.category = productCategory.rawValue
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		let productCategory = ProductCategory.allCases[row]
		
		return productCategory.rawValue
	}
}

extension ProductViewController: UITextFieldDelegate {
	func textFieldDidEndEditing(_ textField: UITextField) {
		if textField == nameTextField {
			try! product!.realm?.write {
				product!.name = nameTextField.text!
			}
		} else if textField == brandTextField {
			try! product!.realm?.write {
				product!.brand = brandTextField.text!
			}
		} else if textField == expirationDateTextField {
			let date: Date?
			if let expDateString = expirationDateTextField.text,
				expDateString != "" {
				date = dateFormatter!.date(from: expDateString)
			} else {
				date = nil
			}
			
			try! product!.realm?.write {
				product!.expirationDate = date
			}
			
		} else if textField == priceTextField {
			var price: Double = 0.00
			if let currencyFormatter = currencyFormatter,
				let priceText = priceTextField.text,
				let numberFromFormatter = currencyFormatter.number(from: priceText) {
				price = Double(numberFromFormatter)
			}
			
			try! product!.realm?.write {
				product!.price = price
			}
		}
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if textField == categoryTextField {
			return false
		}
		
		guard textField == priceTextField else {
			return true
		}		
		
		guard let currencyFormatter = currencyFormatter,
		let selectedRange = priceTextField.selectedTextRange,
		let originalText = priceTextField.text,
		let swiftRange = originalText.range(from: range) else {
			return false
		}
		
		var replacementString = string
		
		if replacementString.count > 1 {
			replacementString = replacementString.replacingOccurrences(of: currencyFormatter.currencySymbol, with: "")
			replacementString = replacementString.replacingOccurrences(of: currencyFormatter.groupingSeparator, with: "")
			guard let stringFromFormatter = currencyFormatter.string(from: NSDecimalNumber(string: replacementString)) else {
				return false
			}
			
			replacementString = stringFromFormatter
		}
		
		let start = priceTextField.beginningOfDocument
		let cursorOffset = priceTextField.offset(from: start, to: selectedRange.start)
		let originalTextLength = originalText.count
		
		var newText = originalText
		newText = newText.replacingCharacters(in: swiftRange, with: replacementString)
		newText = newText.replacingOccurrences(of: currencyFormatter.currencySymbol, with: "")
		newText = newText.replacingOccurrences(of: currencyFormatter.groupingSeparator, with: "")
		newText = newText.replacingOccurrences(of: currencyFormatter.decimalSeparator, with: "")
		
		let maxDigits = 11
		if newText.count <= maxDigits {
			let numberFromTextField = NSDecimalNumber(string: newText)
			let divideBy = NSDecimalNumber(value: 10).raising(toPower: currencyFormatter.maximumFractionDigits)
			let newNumber = numberFromTextField.dividing(by: divideBy)
			guard let newText = currencyFormatter.string(from: newNumber) else {
				return false
			}
			
			priceTextField.text = newText
			
			if cursorOffset != originalTextLength {
				let lengthDelta = newText.count - originalTextLength
				let newCursorOffset = max(0, min(newText.count, cursorOffset + lengthDelta))
				let newPosition = priceTextField.position(from: priceTextField.beginningOfDocument, offset: newCursorOffset)!
				let newRange = priceTextField.textRange(from: newPosition, to: newPosition)
				priceTextField.selectedTextRange = newRange
			}
		}
		
		return false
	}
}

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
