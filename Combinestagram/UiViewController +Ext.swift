//
//  UiViewController +Ext.swift
//  Combinestagram
//
//  Created by 3rabApp-oday on 18/12/2023.
//  Copyright © 2023 Underplot ltd. All rights reserved.
//

import Foundation
import RxSwift
extension UIViewController {
  
  // 2. Challenge2 -> Use Completable
  func alert(_ title: String, text: String?) -> Completable {
    return Completable.create { [weak self] completable in
      let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
      alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: {_ in
        completable(.completed)
      }))
      self?.present(alertVC, animated: true, completion: nil)
      return Disposables.create {
        self?.dismiss(animated: true)
      }
    }
  }
  
}
