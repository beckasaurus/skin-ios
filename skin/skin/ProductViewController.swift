//
//  ProductViewController.swift
//  skin
//
//  Created by Becky Henderson on 9/19/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

class ProductViewController: UIViewController {
	
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var brandTextField: UITextField!
	@IBOutlet weak var priceTextField: UITextField!
	@IBOutlet weak var expirationDateTextField: UITextField!
	@IBOutlet weak var categoryTextField: UITextField!
	
	var dateFormatter: DateFormatter?
	var currencyFormatter: NumberFormatter?
	
	var product: Product?
	
	var notificationToken: NotificationToken?
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupUI()
		setupRealm()
	}
	
	func setPriceText(with price: RealmOptional<Double>) {
		guard let price = price.value
			else {return}
		
		let number = NSNumber(value: price)
		let priceString = currencyFormatter!.string(from: number)
		
		priceTextField.text = priceString
	}
	
	func setExpirationDateText(with date: Date?) {
		guard let date = date
			else { return }
		
		expirationDateTextField.text = dateFormatter!.string(from: date)
	}

	func setupUI() {
		currencyFormatter = NumberFormatter()
		currencyFormatter!.numberStyle = .currency
		
		dateFormatter = DateFormatter()
		dateFormatter!.dateStyle = .short
		dateFormatter!.timeStyle = .none
		
		let datePicker = UIDatePicker()
		datePicker.datePickerMode = .date
		datePicker.addTarget(self, action: #selector(expirationDateChanged(_:)), for: .valueChanged)
		if let expirationDate = product?.expirationDate {
			datePicker.setDate(expirationDate, animated: false)
		}
		expirationDateTextField.inputView = datePicker
		
		let categoryPicker = UIPickerView()
		categoryPicker.delegate = self
		categoryPicker.dataSource = self
		if let rowNumForCategory = ProductCategory.allCases.index(of: ProductCategory(rawValue: (product?.category)!)!) {
			categoryPicker.selectRow(rowNumForCategory, inComponent: 0, animated: true)
		}
		categoryTextField.inputView = categoryPicker
		
		brandTextField.text = product!.brand
		nameTextField.text = product!.name
		setPriceText(with: product!.price)
		setExpirationDateText(with: product!.expirationDate)
		categoryTextField.text = product!.category
	}
	
	func setupRealm() {
		notificationToken = product?.addNotificationBlock({ [weak self] (change) in
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
		
		notificationToken?.stop()
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
			var price: Double? = nil
			if  let priceString = priceTextField.text,
				priceString != "" {
				price = Double(currencyFormatter!.number(from: priceString)!)
			}
			
			let realmPrice = RealmOptional(price)
			
			try! product!.realm?.write {
				product!.price = realmPrice
			}
		}
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if textField == categoryTextField {
			return false
		}
		
		return true
	}
}
