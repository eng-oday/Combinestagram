

import UIKit
import Photos
import RxSwift
import RxRelay

class PhotosViewController: UICollectionViewController {

  // MARK: private properties
  private lazy var photos = PhotosViewController.loadPhotos()
  private lazy var imageManager = PHCachingImageManager()
  private let selectedPhotoSubject  = PublishSubject<UIImage>()
  let disposeBag                    = DisposeBag()
  
  // MARK: public properties
  var selectedPhotos:Observable<UIImage> {
    return selectedPhotoSubject.asObservable()
  }
  
  private lazy var thumbnailSize: CGSize = {
    let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    return CGSize(width: cellSize.width * UIScreen.main.scale,
                  height: cellSize.height * UIScreen.main.scale)
  }()

  static func loadPhotos() -> PHFetchResult<PHAsset> {
    let allPhotosOptions = PHFetchOptions()
    allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    return PHAsset.fetchAssets(with: allPhotosOptions)
  }

  // MARK: View Controller
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let authorized = PHPhotoLibrary.authorized.share()
    
    authorized
      .skip(while: {$0 == false})
      .subscribe { [weak self] auth in
        self?.photos = PhotosViewController.loadPhotos()
        DispatchQueue.main.async {
          self?.collectionView.reloadData()
      }
      }.disposed(by: disposeBag)
    
    authorized
    // there is no reason to use these two operators one of them is enough
      .skip(1)
      .takeLast(1)
      .filter({
        print($0)
        return $0 == false
      })
      .subscribe(onNext: { [weak self] auth in
        print(auth)
        guard let errorMessage = self?.errorMessage else { return }
        DispatchQueue.main.async(execute: errorMessage)
        
      })
      .disposed(by: disposeBag)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    selectedPhotoSubject.onCompleted()

  }
  
  private func errorMessage() {
    alert("No access to Camera Roll",
      text: "You can grant access to Combinestagram from the Settings app")
      .subscribe(onDisposed: { [weak self] in
        self?.dismiss(animated: true, completion: nil)
        _ = self?.navigationController?.popViewController(animated: true)
      })
      .disposed(by: disposeBag)
  }

  // MARK: UICollectionView

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

    let asset = photos.object(at: indexPath.item)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell

    cell.representedAssetIdentifier = asset.localIdentifier
    imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
      if cell.representedAssetIdentifier == asset.localIdentifier {
        cell.imageView.image = image
      }
    })

    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let asset = photos.object(at: indexPath.item)

    if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
      cell.flash()
    }

    imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
      guard let image = image, let info = info else { return }
      
      if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as?
      Bool, !isThumbnail {
        self?.selectedPhotoSubject.onNext(image)
      }
    })
  }
}
