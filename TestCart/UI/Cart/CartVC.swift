//
//  CartVC.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit

final class CartVC: UIViewController {

    @IBOutlet weak var totalLabel: UILabel!
    let viewModel = CartViewModel(viewContext: Store.shared.viewContext)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        self.totalLabel.text = viewModel.getTotalText()
    }

    @IBAction func unwindToCartVC(_ segue: UIStoryboardSegue) { }
}
