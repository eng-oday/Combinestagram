

import Foundation
import UIKit
import Photos
import RxSwift

class PhotoWriter {
  enum Errors: Error {
    case couldNotSavePhoto
  }

  // 1. Challenge1 -> Use Single
  static func save(_ image:UIImage) -> Single<String> {
    
    return Single.create { observer in
      var savedAssetId:String?
     
        
        PHPhotoLibrary.shared().performChanges {
          // save
            let request   = PHAssetChangeRequest.creationRequestForAsset(from: image)
            savedAssetId  = request.placeholderForCreatedAsset?.localIdentifier
        } completionHandler: { success, error in
          DispatchQueue.main.async {
            if success , let id = savedAssetId{

              observer(.success(id))
            }else {
              observer(.failure(error ?? Errors.couldNotSavePhoto))
            }
          }
        }

      return Disposables.create()
    }
  }

}
