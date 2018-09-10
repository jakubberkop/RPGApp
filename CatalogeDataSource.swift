//
//  CatalogeDataSource.swift
//  RPGAapp
//
//  Created by Jakub on 07.09.2018.
//  Copyright © 2018 Jakub. All rights reserved.
//

import Foundation

class CatalogeDataSource{
	
	static var source: CatalogeDataSource = CatalogeDataSource()
	
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(searchCataloge(_:)), name: .searchCataloge, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(modelChanged), name: .catalogeModelChanged, object: nil)
		self.modelChanged()
	}
	
	private var filter: [String : Double?] = [:]
	
	private(set) var model = CatalogeModel(
		sortSection:   CatalogeSortSection(list: [
			CatelogeSortItem(name: NSLocalizedString("Sort by categories", comment: ""), selected: true, type: .categories),
			CatelogeSortItem(name: NSLocalizedString("Sort by name", comment: "")      , selected: false, type: .name),
			CatelogeSortItem(name: NSLocalizedString("Sort by price", comment: "")     , selected: false, type: .price),
			CatelogeSortItem(name: NSLocalizedString("Sort by rarity", comment: "")    , selected: false, type: .rarity)
			]),
		searchSection: CatalogeSearchSection(list: [
			CatalogeSearchItem(name: NSLocalizedString("Search by name", comment: "")			  , selected: true),
			CatalogeSearchItem(name: NSLocalizedString("Search in description", comment: "")	  , selected: true),
			CatalogeSearchItem(name: NSLocalizedString("Search in category name", comment: "")    , selected: false),
			CatalogeSearchItem(name: NSLocalizedString("Search in sub category name", comment: ""), selected: false),
			CatalogeSearchItem(name: NSLocalizedString("Search by price", comment: "")			  , selected: false),
			CatalogeSearchItem(name: NSLocalizedString("Search by atribute name", comment: "")    , selected: false),
			]),
		filterSection: CatalogeFilterSection(list: [
			CatalogeFilterItem(type: .rarity, mode: .min, range: (1.0, 4.0)),
			CatalogeFilterItem(type: .rarity, mode: .max, range: (1.0, 4.0)),
			CatalogeFilterItem(type: .price,  mode: .min, range: Load.priceRange),
			CatalogeFilterItem(type: .price,  mode: .max, range: Load.priceRange)
			])
	)
	
	
	private var searchString: String = ""{
		didSet{
			modelChanged()
		}
	}
	
	var items: [(String, [Item])] = []{
		didSet{
			NotificationCenter.default.post(name: .reloadCataloge, object: nil)
		}
	}
	
	var menuItems: [(String, [String])] = []
	
	private var searchedItems: [Item] = []
	private var filteredItems: [Item] = []
	
	@objc private func modelChanged(){
		let allItems = Load.items()
		searchedItems = searchItems(allItems)
		filteredItems = filterItems(searchedItems)
		items = sortItems(filteredItems)
	}
	
	@objc private func searchCataloge(_ notification: Notification){
		guard let newString = notification.object as? String else { return }
		searchString = newString.replacingOccurrences(of: " ", with: "")
	}
	
	private func searchItems(_ list: [Item]) -> [Item]{
		guard searchString != "" else { return list }
		let searchModel = model.searchModel
		
		let searchedItems = list.filter({
				   ( searchModel[0].selected && ($0.name?.containsIgnoringCase(searchString))!)
				|| ( searchModel[1].selected && ($0.item_description?.containsIgnoringCase(searchString))!)
				|| ( searchModel[2].selected && ($0.category?.name?.containsIgnoringCase(searchString))!)
				|| ( searchModel[3].selected && ($0.subCategory?.name?.containsIgnoringCase(searchString))!)
				|| ( searchModel[4].selected && forTailingZero($0.price) == searchString)
				|| ( searchModel[5].selected && $0.itemAtribute?.filter(
						{(($0 as! ItemAtribute).name?.containsIgnoringCase(searchString))!}).count != 0)
		})
		return searchedItems
	}
	
	private func filterItems(_ list: [Item]) -> [Item]{
		guard filter.count != 0 else { return list }
		let filterdList = FilterHelper.filterItemList(list, using: filter)
		return filterdList
	}
	
	private func sortItems(_ list: [Item]) -> [(String, [Item])]{
		let sortModel = model.sortModel.sortBy
		switch sortModel {
		case .categories:
			var subCategoryList: [(SubCategory, [Item])] = []
			
			for item in list{
				guard let itemSubCategory = item.subCategory else { continue }
				
				if let index = subCategoryList.index(where: {$0.0 == itemSubCategory}){
					subCategoryList[index].1.append(item)
				}else{
					subCategoryList.append((itemSubCategory, [item]))
				}
			}
			
			subCategoryList.sort(by: { !(($0.0.category?.name)! > ($1.0.category?.name)! && ($0.0.name)! > ($1.0.name)! )})
			
			let namedSubCategoryList = subCategoryList.map{($0.0.name!, $0.1)}
			
			let subCategories = subCategoryList.map{$0.0}
			
			var categories: [(Category, [String])] = []
			
			for subCategory in subCategories {
				if let index = categories.index(where: { $0.0 === subCategory.category}){
					categories[index].1.append(subCategory.name!)
				}else{
					categories.append((subCategory.category!, [subCategory.name!]))
				}
			}

			self.menuItems = categories.map{($0.0.name!, $0.1)}
			
			return namedSubCategoryList
			
		case .name:
			var alphabetDict: [String: [Item]] = [: ]
			
			for item in list{
				guard let itemNameLetter = item.name?.characters.first else { continue }
				let itemName = String(itemNameLetter)
				
				if alphabetDict[itemName] == nil{
					alphabetDict[itemName] = []
				}
				
				alphabetDict[itemName]?.append(item)
			}
			
			let alphabetArray = Array(alphabetDict).sorted(by: {$0.key < $1.key})
			
			let localizedAlphabet = NSLocalizedString("Alphabet", comment: "")
			self.menuItems = [(localizedAlphabet, alphabetArray.map{$0.key})]
			
			return alphabetArray
			
		case .price:
			var priceList: [(String, [Item])] = []
			var newList = list
			
			var priceThreshold = 1.0
			
			let thresholdRate: Double
		
			if let currencyRate = Load.currentCurrency()?.rate{
				thresholdRate = currencyRate * 10
			}else{
				thresholdRate = 10
			}
			
			while newList.count > 1{
				
				priceThreshold *= thresholdRate
				
				let itemsLowerThan = newList.filter({$0.price < priceThreshold}).sorted(by: {$0.0.price < $0.1.price})
				newList = newList.filter({$0.price >= priceThreshold})
				
				let sectionName: String
				
				if priceList.count == 0{
					sectionName = "< \(showPrice(thresholdRate))"
				}else if newList.count == 0{
					sectionName = "< \(showPrice(priceThreshold))"
				}else{
					sectionName = "\(showPrice(priceThreshold/thresholdRate)) - \(showPrice(priceThreshold))"
				}
				
				priceList.append((sectionName, itemsLowerThan))
			}
			
			menuItems = [(NSLocalizedString("Price segment", comment: ""), priceList.map{$0.0})]
			return priceList
		default:
			let localizedSearchResults = NSLocalizedString("Search results", comment: "")
			return [(localizedSearchResults, list)]
		}
	}
}

extension Notification.Name{
	static let reloadCataloge = Notification.Name(rawValue: "reloadCataloge")
	static let catalogeModelChanged = Notification.Name(rawValue: "catalogeModelChanged")
}