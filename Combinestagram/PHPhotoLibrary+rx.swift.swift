//
//  PHPhotoLibrary+rx.swift .swift
//  Combinestagram
//
//  Created by eng-oday on 17/12/2023.
//  Copyright © 2023 Underplot ltd. All rights reserved.
//

import Foundation
import Photos
import RxSwift

extension PHPhotoLibrary {
  static var authorized:Observable<Bool> {
    return Observable.create { observer in
      
      DispatchQueue.main.async {
        if authorizationStatus() == .authorized {
          observer.onNext(true)
          observer.onCompleted()
        }else {
          observer.onNext(false)
          requestAuthorization{ newStatus in
            observer.onNext(newStatus == .authorized)
            observer.onCompleted()
          }
        }
      }
      
      return Disposables.create()
    }
  }
}
