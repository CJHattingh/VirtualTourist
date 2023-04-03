//
//  UIViewController+Extention.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2023/03/29.
//

import UIKit

extension UIViewController {
    
    // Universal method to show error messages
    func showFailure(title: String, message: String) {
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            show(alertVC, sender: nil)
    }
}
