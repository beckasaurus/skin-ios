//
//  SearchableProductListViewController.swift
//  skin
//
//  Created by Becky Henderson on 11/7/17.
//  Copyright © 2017 Becky Henderson. All rights reserved.
//

import UIKit
import RealmSwift

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

class SearchableProductListViewController: UIViewController {
	
	//MARK: Mandatory overrides
	
	func containerName() -> String {
		assert(false, "containerName must be overridden")
	}
	
	func getProductListFromContainer(realm: Realm) -> List<Product> {
		assert(false, "getProductContainerFrom must be overridden")
	}
	
	func productViewType() -> ProductViewType {
		assert(false, "productViewType must be overridden")
	}
	
	func tableSelectionSegueIdentifier() -> String {
		return selectProductSegue
	}

	func addProductSegueIdentifier() -> String {
		return addProductSegue
	}
	
	//MARK: Reusable code
	
	@IBOutlet weak var tableView: UITableView!
	var searchController: UISearchController?
	
	let productCategories = ProductCategory.allCases
	
	var products: List<Product>?
	
	var filteredProducts: [Product]? {
		didSet {
			updateCategoryProductLists()
		}
	}
	
	var cleansers: [Product]?
	var actives: [Product]?
	var hydrators: [Product]?
	var occlusives: [Product]?
	var treatments: [Product]?
	
	var realmConnectedNotification: NSObjectProtocol?
	
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
	
	func setupUI() {
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProduct))
		
		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.delegate = self
		searchController?.dimsBackgroundDuringPresentation = false
		searchController?.searchBar.sizeToFit()
		definesPresentationContext = true
		
		tableView.tableHeaderView = self.searchController?.searchBar

		navigationItem.title = containerName()
	}
	
	func updateList() {
		self.tableView.reloadData()
	}
	
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
	
	func setupRealm() {
		products = getProductListFromContainer(realm: realm!)
		
		updateCategoryProductLists()
	}
	
	deinit {
		realmConnectedNotification = nil
	}
	
	func didAddProductToList(product: Product) {
		DispatchQueue.main.async { [weak self] _ in
			guard let strongSelf = self else { return }
			strongSelf.performSegue(withIdentifier: strongSelf.tableSelectionSegueIdentifier(), sender: product)
		}
	}
	
	// MARK: - Add function
	
	func addProduct() {
		performSegue(withIdentifier: addProductSegueIdentifier(), sender: nil)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if segue.identifier == selectProductSegue {
			let productToView: Product
			if let cell = sender as? UITableViewCell {
				let indexPath = tableView.indexPath(for: cell)!
				productToView = productForIndexPath(indexPath: indexPath)
			} else {
				productToView = sender as! Product
			}
			
			let navController = segue.destination as! UINavigationController
			let productViewController = navController.topViewController as! ProductViewController
			productViewController.product = productToView
			productViewController.viewType = productViewType()
			
			productViewController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
			productViewController.navigationItem.leftItemsSupplementBackButton = true
		}
	}
}

extension SearchableProductListViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: tableSelectionSegueIdentifier(), sender: tableView.cellForRow(at: indexPath))
	}
}

extension SearchableProductListViewController: UITableViewDataSource {
	
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
	
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return productCategories.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
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
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: productCellIdentifier, for: indexPath)
		let product = productForIndexPath(indexPath: indexPath)
		cell.textLabel?.text = product.name
		cell.detailTextLabel?.text = product.brand
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return ProductListTableSection.tableSectionTitles[section]
	}
	
	// MARK: - Delete function
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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

extension SearchableProductListViewController: UISearchResultsUpdating {
	
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

extension SearchableProductListViewController: UISearchBarDelegate {
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		filteredProducts = nil
	}
}
