//
//  ProductListViewController.swift
//  skin
//
//  Created by Becky Henderson on 11/7/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

// TODO: Change table selection behavior based on context
// TODO: Wish list vs stash -- toggle between two

let productListViewIdentifier = "productListVC"
let productCellIdentifier = "productCell"
let selectProductSegue = "selectProductSegue"
let addProductSegue = "addProductSegue"

enum ProductListTableSection: Int {
	case cleansers
	case actives
	case hydrators
	case occlusives
	case treatments
	
	static let tableSectionTitles = ["Cleansers", "Actives", "Hydrators", "Occlusives", "Treatments"]
}

enum ProductType: Int {
	case stash
	case wishList
}

enum ProductListContext {
	case management
	case selection
}

class ProductListViewController: UITableViewController {
	
	@IBOutlet weak var productTypeSegmentedControl: UISegmentedControl!
	
	var products: List<Product>?
	var filteredProducts: [Product]? {
		didSet {
			updateCategoryProductLists()
		}
	}
	
	var context: ProductListContext = .management {
		didSet {
			switch context {
			case .management:
				shouldShowCancel = false
				shouldShowProductTypeSegmentedControl = true
			case .selection:
				shouldShowCancel = true
				shouldShowProductTypeSegmentedControl = false
			}
		}
	}
	
	var searchController: UISearchController?
	
	let productCategories = ProductCategory.allCases
	var cleansers: [Product]?
	var actives: [Product]?
	var hydrators: [Product]?
	var occlusives: [Product]?
	var treatments: [Product]?
	
	var shouldShowCancel: Bool = false {
		didSet {
			if shouldShowCancel {
				navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
			} else {
				navigationItem.leftBarButtonItem = nil
			}
		}
	}
	
	var shouldShowProductTypeSegmentedControl = true {
		didSet {
			if shouldShowProductTypeSegmentedControl {
				productTypeSegmentedControl.isHidden = false
			} else {
				productTypeSegmentedControl.selectedSegmentIndex = ProductType.stash.rawValue
				productTypeSegmentedControl.isHidden = true
			}
		}
	}
	
	var realmConnectedNotification: NSObjectProtocol?
	var notificationToken: NotificationToken?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		
		if realm == nil {
			realmConnectedNotification = NotificationCenter.default.addObserver(forName: realmConnected, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
				self?.setupRealm()
			}
		} else {
			setupRealm()
		}
	}
	
	deinit {
		notificationToken?.invalidate()
		realmConnectedNotification = nil
	}
	
	func productType() -> ProductType {
		return ProductType(rawValue: productTypeSegmentedControl.selectedSegmentIndex) ?? .stash
	}
	
	func setupUI() {
		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.delegate = self
		searchController?.dimsBackgroundDuringPresentation = false
		searchController?.searchBar.sizeToFit()
		definesPresentationContext = true
		
		tableView.tableHeaderView = searchController?.searchBar
	}
	
	func updateList() {
		self.tableView.reloadData()
	}
}

// MARK: Navigation
extension ProductListViewController {
	@IBAction func productViewUnwind(segue: UIStoryboardSegue) {
		//unwind segue for done/cancel in product view
		//we register as the product view's delegate so we'll receive a notification when a new product is added and handle adding to our list there
		//nothing really needs to be done here, we just need the segue to be present so we can manually unwind
	}
	
	func productView(from destination: UIViewController) -> ProductViewable {
		let navController = destination as! UINavigationController
		return navController.topViewController as! ProductViewable
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == selectProductSegue {
			let productToView: Product
			if let cell = sender as? UITableViewCell {
				let indexPath = tableView.indexPath(for: cell)!
				productToView = productForIndexPath(indexPath: indexPath)
			} else {
				productToView = sender as! Product
			}
			
			var productViewable = productView(from: segue.destination)
			productViewable.show(product: productToView, as: productType())
			productViewable.delegate = self
		} else if segue.identifier == addProductSegue {
			var productViewable = productView(from: segue.destination)
			productViewable.show(product: nil, as: productType())
			productViewable.delegate = self
		}
	}
	
	func cancel(sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
}

// MARK: Realm setup
extension ProductListViewController {
	func setupRealm() {
		setProductListFromContainer()
		updateCategoryProductLists()
		
		// Notify us when Realm changes
		self.notificationToken = self.realm!.observe { [weak self] notification, realm in
			self?.updateCategoryProductLists()
		}
	}
}

// MARK: Load products
extension ProductListViewController {
	func createStashAndSetProductList() {
		guard let realm = realm else {
			return
		}
		
		try! realm.write {
			let stash = Stash()
			self.realm!.add(stash)
			self.products = stash.products
		}
	}
	
	func setProductListFromStash() {
		guard let realm = realm else {
			return
		}
		
		if let stash = realm.objects(Stash.self).first {
			products = stash.products
		} else {
			createStashAndSetProductList()
		}
	}
	
	func setProductListFromWishList() {
		
	}
	
	func setProductListFromContainer() {
		let productType = self.productType()
		
		switch productType {
		case .stash:
			return setProductListFromStash()
		case .wishList:
			return setProductListFromWishList()
		}
	}
}

// MARK: Product categories
extension ProductListViewController {
	func filterProducts(by category: ProductCategory) -> [Product] {
		let productsToSearch = filteredProducts ?? Array(products!)
		return productsToSearch.filter({ (product) -> Bool in
			let productCategory = ProductCategory(rawValue: product.category)!
			return productCategory == category
		})
	}
	
	func updateCategoryProductLists() {
		cleansers = filterProducts(by: .cleanser)
		actives = filterProducts(by: .active)
		hydrators = filterProducts(by: .hydrator)
		occlusives = filterProducts(by: .occlusive)
		treatments = filterProducts(by: .treatment)
		
		updateList()
	}
}

extension ProductListViewController: ProductDelegate {
	func didAdd(product: Product) {
		try! realm?.write {
			products?.insert(product,
							 at: products!.count)
		}
	}
}


// MARK: Table view data source
extension ProductListViewController {
	
	func productForIndexPath(indexPath: IndexPath) -> Product {
		let tableSection = ProductListTableSection(rawValue: indexPath.section)!
		
		let product: Product
		switch tableSection {
		case .cleansers:
			product = cleansers![indexPath.row]
		case .actives:
			product = actives![indexPath.row]
		case .hydrators:
			product = hydrators![indexPath.row]
		case .occlusives:
			product = occlusives![indexPath.row]
		case .treatments:
			product = treatments![indexPath.row]
		}
		
		return product
	}
	
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return productCategories.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		let tableSection = ProductListTableSection(rawValue: section)!
		switch tableSection {
		case .cleansers:
			return cleansers?.count ?? 0
		case .actives:
			return actives?.count ?? 0
		case .hydrators:
			return hydrators?.count ?? 0
		case .occlusives:
			return occlusives?.count ?? 0
		case .treatments:
			return treatments?.count ?? 0
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: productCellIdentifier, for: indexPath)
		let product = productForIndexPath(indexPath: indexPath)
		cell.textLabel?.text = product.name
		cell.detailTextLabel?.text = product.brand
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return ProductListTableSection.tableSectionTitles[section]
	}
	
	// MARK: - Delete function
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			try! self.realm?.write {
				let item: Product
				
				let tableSection = ProductListTableSection(rawValue:indexPath.section)!
				switch tableSection {
				case .actives:
					item = actives![indexPath.row]
				case .cleansers:
					item = cleansers![indexPath.row]
				case .hydrators:
					item = hydrators![indexPath.row]
				case .occlusives:
					item = occlusives![indexPath.row]
				case .treatments:
					item = treatments![indexPath.row]
				}
				
				self.realm?.delete(item)
				
				updateCategoryProductLists()
			}
		}
	}
}

// MARK: Search results updating protocol
extension ProductListViewController: UISearchResultsUpdating {
	
	func filterContentForSearchText(_ searchText: String) {
		guard let products = products else {
			return
		}
		
		if searchText == "" {
			filteredProducts = nil
		} else {
			filteredProducts = products.filter({( product : Product) -> Bool in
				return product.name.lowercased().contains(searchText.lowercased())
			})
		}
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		filterContentForSearchText(searchController.searchBar.text!)
	}
}

// MARK: Search bar delegate
extension ProductListViewController: UISearchBarDelegate {
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		filteredProducts = nil
	}
}

