//
//  RoutineLogTableSectionHeaderView.swift
//  skin
//
//  Created by Becky Henderson on 3/6/18.
//  Copyright © 2018 Becky Henderson. All rights reserved.
//

import UIKit

class RoutineLogTableSectionHeaderView: UITableViewHeaderFooterView {

	static let reuseIdentifier = "routineLogSectionHeader"

	let deleteButton: UIButton

	init(frame: CGRect,
		 routineName: String,
		 section: Int,
		 editButtonTarget: Any?,
		 editButtonSelector: Selector,
		 deleteButtonTarget: Any?,
		 deleteButtonSelector: Selector,
		 inEditingMode: Bool) {

		let addProductButton = UIButton(type: UIButtonType.system)
		addProductButton.accessibilityIdentifier = "Add Product to \(routineName) Routine"
		addProductButton.setTitle("+ Add Product", for: .normal)
		addProductButton.tag = section
		addProductButton.translatesAutoresizingMaskIntoConstraints = false
		addProductButton.addTarget(editButtonTarget, action: editButtonSelector, for: .touchUpInside)

		let routineLogNameLabel = UILabel()
		routineLogNameLabel.accessibilityIdentifier = "Routine Name"
		routineLogNameLabel.text = routineName
		routineLogNameLabel.translatesAutoresizingMaskIntoConstraints = false

		self.deleteButton = UIButton(type: UIButtonType.system)
		self.deleteButton.accessibilityIdentifier = "Delete \(routineName) Routine"
		self.deleteButton.setTitle("Delete Routine", for: .normal)
		self.deleteButton.tag = section
		self.deleteButton.translatesAutoresizingMaskIntoConstraints = false
		self.deleteButton.addTarget(deleteButtonTarget, action: deleteButtonSelector, for: .touchUpInside)

		let nameAndDeleteStackView = UIStackView(arrangedSubviews: [self.deleteButton, routineLogNameLabel])
		nameAndDeleteStackView.axis = .horizontal
		nameAndDeleteStackView.distribution = .fill
		nameAndDeleteStackView.alignment = .firstBaseline
		nameAndDeleteStackView.translatesAutoresizingMaskIntoConstraints = false
		nameAndDeleteStackView.spacing = 8

		let stackView = UIStackView(arrangedSubviews: [nameAndDeleteStackView, addProductButton])
		stackView.axis = .horizontal
		stackView.distribution = .fill
		stackView.alignment = .firstBaseline
		stackView.translatesAutoresizingMaskIntoConstraints = false

		self.deleteButton.isHidden = !inEditingMode

		super.init(reuseIdentifier: RoutineLogTableSectionHeaderView.reuseIdentifier)

		addSubview(stackView)

		let margins = layoutMarginsGuide
		stackView.widthAnchor.constraint(equalTo: margins.widthAnchor).isActive = true
		stackView.heightAnchor.constraint(equalTo: margins.heightAnchor).isActive = true
		stackView.centerXAnchor.constraint(equalTo: margins.centerXAnchor).isActive = true
		stackView.centerYAnchor.constraint(equalTo: margins.centerYAnchor).isActive = true

		backgroundColor = .white
		accessibilityIdentifier = "\(routineName) Routine"
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func toggleDeleteButton() {
		deleteButton.isHidden = !deleteButton.isHidden
	}
}
