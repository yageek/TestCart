//
//  BootstrapProcedure.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import ProcedureKit
import ProcedureKitMobile
import CoreData
import UIKit

typealias DownloadContainer = (API.ListResponse, API.RatesResponse)

final class DownloadCurrencies: GroupProcedure, OutputProcedure {

    var downloadContainer: (API.ListResponse?, API.RatesResponse?)
    var output: Pending<ProcedureResult<DownloadContainer>> = .pending

    init() {
        super.init(operations: [])

        let downloadList = DownloadProcedure<API, API.ListResponse>(endpoint: .list)
        let downloadRates = DownloadProcedure<API, API.RatesResponse>(endpoint: .rates)

        let validDownload = BlockProcedure { [unowned self] in
            switch self.downloadContainer {
            case  (let list?, let rates?):
                self.output = .ready(.success(list, rates))
            default:
                self.output = .ready(.failure(API.Error.unexpectedError))
            }
        }

        validDownload.add(dependencies: downloadList, downloadRates)
        validDownload.add(condition: NoFailedDependenciesCondition())
        self.add(children: [downloadList, downloadRates, validDownload])

    }

    override func childWillFinishWithoutErrors(_ child: Operation) {
        if let rates = child as? DownloadProcedure<API, API.RatesResponse> {
            self.downloadContainer.1 = rates.output.success
        }

        if let list = child as? DownloadProcedure<API, API.ListResponse> {
            self.downloadContainer.0 = list.output.success
        }
    }
}

final class ImportCurrencies: Procedure, InputProcedure {

    let psc: NSPersistentStoreCoordinator
    init(psc: NSPersistentStoreCoordinator) {
        self.psc = psc
        super.init()
        name = "ImportCurrencies"
    }

    var input: Pending<DownloadContainer> = .pending

    override func execute() {
        guard !isCancelled else { self.finish(); return }

        guard let element = input.value else {
            self.finish(withError: ProcedureKitError.dependenciesFailed())
            return
        }

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.persistentStoreCoordinator = self.psc
        context.perform {

            let list = element.0
            let values = element.1

            for (key, value) in values.quotes {

                // Search name
                let range = key.index(key.startIndex, offsetBy: 3)..<key.endIndex
                let currencyKey = key.substring(with: range)

                guard let name = list.currencies[currencyKey] else {
                    Log.warning("Name for \(key) was not found")
                    continue
                }

                let entity = NSEntityDescription.insertNewObject(forEntityName: "CurrencyRate", into: context) as! CurrencyRate
                entity.name = name
                entity.usdRatio = NSDecimalNumber(value: value)
                entity.identifier = currencyKey
            }

            // Add USD
            let entity = NSEntityDescription.insertNewObject(forEntityName: "CurrencyRate", into: context) as! CurrencyRate
            entity.name = "US Dollar"
            entity.usdRatio = NSDecimalNumber(value: 1.0)
            entity.identifier = "USD"
            
            if context.hasChanges {
                do {
                    try context.save()
                    self.finish()
                } catch let error {
                    self.finish(withError: error)
                }
            }

        }
    }
}

final class ImportDefaultProduct: Procedure {
    let plistURL: URL
    let psc: NSPersistentStoreCoordinator

    let nameKey = "ProductName"
    let unitUSDValueKey = "UnitUSDValue"

    init(URL: URL, psc: NSPersistentStoreCoordinator) {
        self.plistURL = URL
        self.psc = psc
        super.init()
    }

    override func execute() {
        guard !isCancelled else { return }

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = psc
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.perform {

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ProductDescription")

            do {
                let numbers = try context.count(for: request)
                if numbers > 0 {
                    self.finish()
                    return
                }
            } catch let error {
                self.finish(withError: error)
            }

            guard let elements = NSArray(contentsOf: self.plistURL) as? [[String: Any]] else {
                self.finish()
                return
            }

            for element in elements {
                guard let name = element[self.nameKey] as? String, let value = element[self.unitUSDValueKey] as? NSNumber else { continue }

                let entity = NSEntityDescription.insertNewObject(forEntityName: "ProductDescription", into: context) as! ProductDescription
                entity.name = name
                entity.priceUSD = NSDecimalNumber(value: value.doubleValue)
            }

            if context.hasChanges {
                do {
                    try context.save()
                    self.finish()
                } catch let error {
                    Log.error("Impossible to setup default data: \(error)")
                    self.finish(withError: error)
                }
            }
        }

    }
}

/// The bootstrap procedure
final class BootstrapCurrencyProcedure: Procedure {

    let psc: NSPersistentStoreCoordinator

    let lastRefreshKey = "net.yageek.testcart.last_currencies_refresh"
    let lastRefreshTrigger: TimeInterval = 3600

    init(psc: NSPersistentStoreCoordinator) {
        self.psc = psc
        super.init()
        name = "BootstrapProcedure"
    }

    override func execute() {
        guard !isCancelled else { self.finish(); return }

        Log.debug("Bootstrap...")
        // Last refresh

        let lastRefresh = UserDefaults.standard.object(forKey: lastRefreshKey) as? Date

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = psc
        context.perform { [unowned self] in

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrencyRate")

            do {

                let result = try context.count(for: request)
                if result > 0 {
                    if let date = lastRefresh, Date().timeIntervalSince(date) < self.lastRefreshTrigger {
                        self.finish()
                    } else {
                        self.importCurrencies()
                    }
                } else {
                    self.importCurrencies()
                }

            } catch let error {
                Log.error("Impossible to load element: \(error)")
                self.finish(withError: error)
            }
        }
    }

    // MARK: - Download
    private func importCurrencies() {

        Log.debug("Download elements from the API...")
        let downloadCurrencies = DownloadCurrencies()
        let importCurrencies = ImportCurrencies(psc: self.psc).injectResult(from: downloadCurrencies)

        let group = GroupProcedure(operations: [downloadCurrencies, importCurrencies])
        group.addDidFinishBlockObserver { (_, errors) in
            UserDefaults.standard.set(Date(), forKey: self.lastRefreshKey)
            UserDefaults.standard.synchronize()

            self.finish(withError: errors.first)
        }

        do {
            try self.produce(operation: group)
        } catch let error {
            Log.debug("Impossible to start download: \(error)")
            self.finish(withError: error)
        }

    }
}

final class BootstrapProcedure: GroupProcedure {

    var hasPresentedError: Bool = false
    let controller: UIViewController
    init(controller: UIViewController, defaultProductURL URL: URL, psc: NSPersistentStoreCoordinator) {
        self.controller = controller

        let currencies = BootstrapCurrencyProcedure(psc: psc)
        let defaultProduct = ImportDefaultProduct(URL: URL, psc: psc)

        let presentMain = BlockProcedure {
            DispatchQueue.main.async {
                controller.performSegue(withIdentifier: "ReplaceSegue", sender: nil)
            }
        }

        presentMain.add(condition: NoFailedDependenciesCondition())
        presentMain.add(dependencies: [currencies, defaultProduct])

        super.init(operations: [currencies, defaultProduct, presentMain])
    }

    override func child(_ child: Operation, willAttemptRecoveryFromErrors errors: [Error]) -> Bool {

        if !hasPresentedError {
            let alert = AlertProcedure(presentAlertFrom: self.controller, withPreferredStyle: .alert, waitForDismissal: false)
            alert.title = "An error occurs during the bootstrap."
            add(child: alert)
            hasPresentedError = true
        }
        return false
    }
}
