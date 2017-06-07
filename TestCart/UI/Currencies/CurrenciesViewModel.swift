//
//  CurrenciesViewModel.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import CoreData
import UIKit

final class CurrenciesViewModel {

    private(set) var selectedCurrency: CurrencyRate?
    let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        return formatter
    }()

    let frc: NSFetchedResultsController<CurrencyRate>
    var configureCellBlock: (CurrencyCell, IndexPath) -> Void = { (_, _) in }

    var lastSelectedIndexPath: IndexPath?

    init(context: NSManagedObjectContext) {

        let request = NSFetchRequest<CurrencyRate>(entityName: "CurrencyRate")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

        configureCellBlock = { [unowned self] (cell, indexPath) in
            let currency = self.frc.object(at: indexPath)
            cell.nameLabel.text = "\(currency.identifier!) - \(currency.name!)"
            cell.priceLabel.text = self.priceFormatter.string(from: currency.usdRatio!)
        }
    }

    func selectCurrency(indexPath: IndexPath) {
        self.selectedCurrency = self.frc.object(at: indexPath)
    }

}
