//
//  ProductsCartViewModel.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit
import CoreData

protocol ProductsCartViewModelDelegate {
    func didRemoveElement()
}

final class ProductsCartViewModel: NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {
    var collectionView: UICollectionView!
    var delegate: ProductsCartViewModelDelegate?

    let frc: NSFetchedResultsController<ProductOrder>
    var configureCellBlock: (ProductCellRemove, IndexPath) -> Void = { (_, _) in }
    let context: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.context  = viewContext

        let request = NSFetchRequest<ProductOrder>(entityName: "ProductOrder")
        request.sortDescriptors = [NSSortDescriptor(key: "product.name", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        configureCellBlock = { (cell, indexPath) in
            let order = self.frc.object(at: indexPath)
            cell.nameLabel.text = order.product!.name!
        }

        frc.delegate = self
    }

    func update() {
        do {
            try frc.performFetch()
        } catch let error {
            Log.error("Can not fetch: \(error)")
        }
    }

    func getCartDecorationTitle() -> String {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ProductOrder")

        do {
            let total = try context.count(for: request)
            return "\(total) Objects in Cart"
        } catch let error {
            return "Core Data error: \(error)"
        }
    }

    func add(product: ProductDescription) {
        let order = NSEntityDescription.insertNewObject(forEntityName: "ProductOrder", into: self.context) as! ProductOrder
        order.product = product
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return frc.sections?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let object = frc.sections?[section]
        return object?.numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCellRemove", for: indexPath) as! ProductCellRemove
        configureCellBlock(cell, indexPath)
        return cell
    }

    func delete(order: ProductOrder) {
        self.context.delete(order)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = frc.object(at: indexPath)
        delete(order: product)
        delegate?.didRemoveElement()
    }

    // MARK: NSFetchedResultsControllerDelegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch (type, indexPath, newIndexPath) {
        case let (.insert, _, .some(newPath)):
            self.collectionView?.insertItems(at: [newPath])
        case let (.delete, .some(oldPath), _):
            self.collectionView?.deleteItems(at: [oldPath])
        default:
            break
        }
    }
}
