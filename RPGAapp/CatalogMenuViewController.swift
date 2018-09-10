//
//  KatalogMenuViewController.swift
//  RPGAapp
//
//  Created by Jakub on 09.08.2017.
//  Copyright © 2017 Jakub. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class catalogeMenu: UIViewController {
	
	var list: [(String, [String])] = CatalogeDataSource.source.menuItems
	var model: CatalogeModel = CatalogeDataSource.source.model
	
    @IBOutlet weak var searchBar: UISearchBar!
	@IBOutlet weak var tableView: UITableView!
	
	var showModel: Bool = false
	
    var filter: [String: Double?] = [:]
	
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(setFilters(_:)))
        NotificationCenter.default.addObserver(self, selector: #selector(reloadFilter(_:)), name: .reloadCatalogeFilter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissKeyboard), name: .dismissKeyboard, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reloadTableView), name: .reloadCataloge, object: nil)
		
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        super.viewWillAppear(animated)
    }
	
	func reloadTableView(){
		list = CatalogeDataSource.source.menuItems
		tableView.reloadData()
	}
	
    func dismissKeyboard() {
        searchBar.endEditing(true)
    }
    
    func reloadFilter(_ notification: Notification){
		guard let newFilter = notification.object as? [String: Double?] else { return }

		filter = newFilter
    }
    
    func setFilters(_ sender: UIBarButtonItem){
        let filterPopover = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "catalogeFilter") as! CatalogeFilterPopover
        
        filterPopover.modalPresentationStyle = .popover
        filterPopover.popoverPresentationController?.sourceView = self.view
            //UIView(frame: CGRect(x: 500, y: 100, width: 300, height: 300))
        if filter.count != 0{
            filterPopover.filter = filter
        }
        
        self.present(filterPopover, animated: true, completion: nil)
    }
	
}

extension catalogeMenu: UITableViewDataSource, UITableViewDelegate{
	
	func numberOfSections(in tableView: UITableView) -> Int {
		if showModel {
			return 2
		}
		
		return list.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if showModel{
			return model[section].count
		}else{
			return list[section].1.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "catalogeMenuCell")
		
		if showModel{
			let modelItem = model[indexPath.section][indexPath.row]
			
			cell?.textLabel?.text = modelItem.name
			cell?.accessoryType = modelItem.selected ? .checkmark : .none
			
		}else{
			let cellSubCategory = list[indexPath.section].1[indexPath.row]
			
			cell?.textLabel?.text = cellSubCategory.capitalized
			cell?.accessoryType = .none
		}
		
		return cell!
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if showModel{
			return model[section].name
		}else{
			return list[section].0
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if showModel{
			model[indexPath.section].select(index: indexPath.row)
			
			tableView.reloadData()
		}else{
			let cellSubCategory = list[indexPath.section].1[indexPath.row]
			
			NotificationCenter.default.post(name: .goToSectionCataloge, object: cellSubCategory)
		}
	}
	
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if showModel {
			model[indexPath.section].select(index: indexPath.row)
			tableView.reloadData()
		}
	}
}

extension catalogeMenu: UISearchBarDelegate{
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		let searchFieldIsFull = searchText.replacingOccurrences(of: " ", with: "").characters.count > 0
		
		NotificationCenter.default.post(name: .searchCataloge, object: searchText)
		
		if searchFieldIsFull {
			if showModel == false{
				
				showModel = true
				
				tableView.reloadData()
			}
			
		}else{
			showModel = false
			
			tableView.reloadData()
		}
    }
}

extension Notification.Name{
    static let goToSectionCataloge = Notification.Name("goToSectionCataloge")
    static let reloadCatalogeFilter = Notification.Name("reloadCatalogeFilter")
    static let searchCataloge = Notification.Name("searchCataloge")
    static let dismissKeyboard = Notification.Name("dismissKeyboard")
	static let searchCatalogeModelChanged = Notification.Name("searchCatalogeModelChanged")
	static let sortModelChanged = Notification.Name("sortModelChanged")
}
