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
	@IBOutlet weak var linkTextField: UITextField!
	@IBOutlet weak var categoryTextField: UITextField!
	
	@IBOutlet weak var linkStackView: UIStackView!
	@IBOutlet weak var expirationDateStackView: UIStackView!
	
	public var viewType: ProductViewType = .stashProduct
	
	var dateFormatter: DateFormatter?
	var currencyFormatter: NumberFormatter?
	
	var product: Product?
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		createProductIfNeeded()
		setupUI()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		updateProductFromUI()
	}
}

// MARK: - Load Product from UI
extension ProductViewController {
	func updateProductFromUI() {
		if let product = product {
			do {
				try realm?.write {
					product.brand = brandTextField.text ?? ""
					product.name = nameTextField.text ?? ""
					product.link = linkTextField.text ?? ""

					let price: Double?
					if let currencyFormatter = currencyFormatter,
						let priceText = priceTextField.text,
						let numberFromFormatter = currencyFormatter.number(from: priceText) {
						price = Double(numberFromFormatter)
					} else {
						price = nil
					}

					product.price.value = price

					let date: Date?
					if let expirationDateString = expirationDateTextField.text,
						expirationDateString != "" {
						date = dateFormatter!.date(from: expirationDateString)
					} else {
						date = nil
					}

					product.expirationDate = date

					realm?.add(product, update: true)
				}
			} catch {
				print("error updating product")
			}
		}
	}
}

// MARK: - Load UI from Product
extension ProductViewController {

	func setFieldDataFromProduct() {
		brandTextField.text = product?.brand ?? ""
		nameTextField.text = product?.name ?? ""
		linkTextField.text = product?.link ?? ""
		setPriceText(with: product?.price ?? RealmOptional(0.00))
		setExpirationDateText(with: product?.expirationDate ?? Date())
		categoryTextField.text = product?.category ?? "Active"
	}

	func setPriceText(with price: RealmOptional<Double>) {
		if let priceValue = price.value {
			let number = NSNumber(value: priceValue)
			let priceString = currencyFormatter!.string(from: number)
			
			priceTextField.text = priceString
		}
	}
	
	func setExpirationDateText(with date: Date?) {
		guard case .stashProduct = viewType,
			let date = date
			else { return }
		
		expirationDateTextField.text = dateFormatter!.string(from: date)
	}
}

// MARK: - Setup UI fields and formatters
extension ProductViewController {

	func setupUI() {
		setupPriceField()
		setupCategoryField()
		setupExpirationDateField()
		setupLinkField()
		setFieldDataFromProduct()
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

	func createProductIfNeeded() {
		if product == nil {
			var dateComponents = DateComponents()
			dateComponents.month = 6
			let defaultExpirationDate = Calendar.current.date(byAdding: dateComponents, to: Date())

			product = Product(value: ["name": "",
									  "category" : ProductCategory.active.rawValue,
									  "expirationDate" : defaultExpirationDate!,
									  "price" : Double(0.00)] as Any)
		}
	}
}

// MARK: UI Actions
extension ProductViewController {

	@IBAction func wishListLinkClicked(sender: UIButton) {
		//FIXME: share extension
		guard let url = linkURLFromLinkField() else {
			return
		}
		UIApplication.shared.open(url)
	}

	func linkURLFromLinkField() -> URL? {
		guard let linkString = linkTextField.text else {
			return nil
		}
		return URL(string:linkString)
	}
}

// MARK: Date picker data source
extension ProductViewController: UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return ProductCategory.allCases.count
	}
}

// MARK: Date picker delegate
extension ProductViewController: UIPickerViewDelegate {
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		let productCategory = ProductCategory.allCases[row]
		
		try! realm?.write {
			product?.category = productCategory.rawValue
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		let productCategory = ProductCategory.allCases[row]
		
		return productCategory.rawValue
	}

	func expirationDateChanged(_ sender: UIDatePicker) {
		let datePicker = expirationDateTextField.inputView! as! UIDatePicker
		let expirationDate = datePicker.date
		setExpirationDateText(with: expirationDate)
	}
}

// MARK: Text field delegate
extension ProductViewController: UITextFieldDelegate {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if textField == categoryTextField {
			return false
		}
		
		guard textField == priceTextField else {
			return true
		}

		//FIXME: break into a separate formatter object
		
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
