//
//  ReplaceSegue.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit

final class ReplaceSegue: UIStoryboardSegue {
    override func perform() {
        guard let window = UIApplication.shared.keyWindow else {
            fatalError("No window is displayed... Will crash on purpose")
        }
         window.rootViewController = self.destination
    }
}
