//
//  ProductsVC.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "ProductCell"

final class ProductsVC: UIViewController, NSFetchedResultsControllerDelegate {

    var footerLabel: UILabel!
    let productsViewModel = ProductsViewModel(viewContext: Store.shared.viewContext)
    let cartViewModel = ProductsCartViewModel(viewContext: Store.shared.viewContext)
    
    @IBOutlet var productsCollection: UICollectionView!
    @IBOutlet var cartsCollection: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        productsCollection.dataSource = productsViewModel
        productsCollection.delegate = productsViewModel
        productsViewModel.collectionView = productsCollection

        cartsCollection.dataSource = cartViewModel
        cartsCollection.delegate = cartViewModel
        cartViewModel.collectionView = cartsCollection

        cartViewModel.delegate = productsViewModel
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false

        productsViewModel.update()
        productsCollection.reloadData()

        cartViewModel.update()
        cartsCollection.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        productsViewModel.frc.delegate = nil
    }
}
