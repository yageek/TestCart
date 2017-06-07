//
//  CurrenciesVC.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit
import CoreData

class CurrenciesVC: UITableViewController, NSFetchedResultsControllerDelegate {

    let viewModel = CurrenciesViewModel(context: Store.shared.viewContext)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView(frame: .zero)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true

        viewModel.frc.delegate = self

        do {
            try viewModel.frc.performFetch()
        } catch let error {
            Log.error("Can not fetch: \(error)")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.frc.delegate = nil
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
      return viewModel.frc.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let object = viewModel.frc.sections?[section]
        return object?.numberOfObjects ?? 0
    }

    // MARK: - NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CurrencyCell", for: indexPath) as! CurrencyCell
        viewModel.configureCellBlock(cell, indexPath)
        return cell
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch (type, indexPath, newIndexPath) {
        case let (.insert, _, .some(newPath)):
            self.tableView.insertRows(at: [newPath], with: .automatic)
        case let (.delete, .some(oldPath), _):
            self.tableView.deleteRows(at: [oldPath], with: .automatic)
        default:
            break
        }
    }
    // MARK: - Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCurrency(indexPath: indexPath)

        performSegue(withIdentifier: "unwindToCartVC", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CartVC {
            destination.viewModel.setConvertion(rate: viewModel.selectedCurrency)
        }
    }
}
