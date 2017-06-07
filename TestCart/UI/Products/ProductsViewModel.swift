//
//  ProductsViewModel.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import CoreData
import UIKit

final class ProductsViewModel:NSObject, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, ProductsCartViewModelDelegate {

    let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    var collectionView: UICollectionView!

    let frc: NSFetchedResultsController<ProductDescription>
    var configureCellBlock: (ProductCell, IndexPath) -> Void = { (_, _) in }
    let context: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.context  = viewContext

        let request = NSFetchRequest<ProductDescription>(entityName: "ProductDescription")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)

        super.init()

        configureCellBlock = { (cell, indexPath) in
            let product = self.frc.object(at: indexPath)
            cell.nameLabel.text = product.name
            cell.priceLabel.text = self.priceFormatter.string(from: product.priceUSD!)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCell", for: indexPath) as! ProductCell
        configureCellBlock(cell, indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "CarReusable", for: indexPath) as! CartReusableView
        view.titleLabel.text = getCartDecorationTitle()
        return view
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = frc.object(at: indexPath)
        add(product: product)
        invalidateFooter()
    }

    func invalidateFooter() {
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutAttributes = false
        context.invalidateFlowLayoutDelegateMetrics = false

        context.invalidateSupplementaryElements(ofKind: UICollectionElementKindSectionFooter, at: [IndexPath(row: 0, section: 0)])
        collectionView.collectionViewLayout.invalidateLayout(with: context)
        collectionView.reloadData()

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

    // MARK: ProductsCartViewModelDelegate
    func didRemoveElement() {
        self.invalidateFooter()
    }
}
