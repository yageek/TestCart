//
//  LoadingVC.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit
import ProcedureKit

final class LoadingVC: UIViewController {
    let queue = ProcedureQueue()

    @IBOutlet var titleLabel: UILabel!

    static var defaultProductURL: URL = {
        return Bundle.main.url(forResource: "DefaultProducts", withExtension: "plist")!
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let bootstrap = BootstrapProcedure(controller: self, defaultProductURL: LoadingVC.defaultProductURL, psc: Store.shared.storeCoordinator)
        queue.add(operation: bootstrap)

        bootstrap.addDidFinishBlockObserver { (_, errors) in
            if !errors.isEmpty {

                DispatchQueue.main.async { [unowned self] in
                    self.titleLabel.text = "Kill and restart the app :("
                }
            }
        }
    }
}
