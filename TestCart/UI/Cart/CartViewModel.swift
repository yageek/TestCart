//
//  CartViewModel.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import Foundation
import CoreData

final class CartViewModel {
    private(set) var convertionRatio: CurrencyRate?
    let viewContext: NSManagedObjectContext

    let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    func getTotalText() -> String {

        let request = NSFetchRequest<ProductOrder>(entityName: "ProductOrder")

        do {
            let elements = try viewContext.fetch(request)
            let number = elements.reduce(NSDecimalNumber(value: 0.0), {$0.adding($1.product!.priceUSD!)})

            if let convertionRate = convertionRatio {
                let converted = number.multiplying(by: convertionRate.usdRatio!)
                return "\(converted.stringValue) \(convertionRate.identifier!)"
            }
            return priceFormatter.string(from: number) ?? "Error"

        } catch let error {
            Log.error("An error occurs with CD: \(error)")
            return "Core Data Error: \(error)"
        }
    }

    func setConvertion(rate: CurrencyRate?) {
        self.convertionRatio = rate
    }
}
