//
//  ViewControllerCustomExtension.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 12/8/24.
//
import UIKit

extension UIViewController {
    
    /// Show alert
    func showAlert(title: String, message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alertVC, animated: true)
    }
    
}
