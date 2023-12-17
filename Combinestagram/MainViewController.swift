

import UIKit
import RxSwift
import RxCocoa
import RxRelay

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!
  
  private let disposeBag        = DisposeBag()
  private let images            = BehaviorRelay<[UIImage]>(value:[])
  private var imageCache        = [Int]()
  override func viewDidLoad() {
    super.viewDidLoad()
    subscribeToImagesToSetupUi()
    subscribeOnImagesToUpdateImagePreview()
  }
  
  @IBAction func actionClear() {
    images.accept([])
    imageCache = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else {return}

    PhotoWriter.save(image)
      .subscribe(
        onSuccess: { [weak self] id in
          self?.showMessage("Saved with id: \(id)")
          self?.actionClear()
        },
        onFailure: { [weak self] error in
          self?.showMessage("Error", description: error.localizedDescription)
        }
      )
      .disposed(by: disposeBag)
  }

  @IBAction func actionAdd() {
    let photosViewController = storyboard!.instantiateViewController(
      withIdentifier: "PhotosViewController") as! PhotosViewController
    
    navigationController!.pushViewController(photosViewController, animated:
    true)
    
    // Share this Observable to different subscription
    // so u can with this observable create 2 subscription and each one is alone
    
    let newPhoto  = photosViewController.selectedPhotos.share()
    
    

    newPhoto
      .filter {  image in
      // 1.Filter to just get image with width greater than height
      return image.size.width > image.size.height
    }
    .filter({  [weak self] image in
      // 2. second filter prevent get same image twice by comapring it by his data
      let length = image.pngData()?.count ?? 0
      guard self?.imageCache.contains(length) == false else {
        return false
      }
      self?.imageCache.append(length)
      return true
    })
    .subscribe { [weak self] image in
      guard let self else {return}
      let arrayOfImages = self.images.value + [image]
      self.images.accept(arrayOfImages)
    }onDisposed: {
      print("completed photo selection")
    }
    .disposed(by: disposeBag)

    
    newPhoto.ignoreElements()
      .subscribe(onCompleted: { [weak self] in
      self?.updateNavigationIcon()
    }).disposed(by: disposeBag)

  }
  
  private func subscribeToImagesToSetupUi(){
    images.asObservable().subscribe { [weak self ] photos in
      guard let self else {return}
      self.updateUI(with: photos)
    }.disposed(by: disposeBag)
  }
  
  private func subscribeOnImagesToUpdateImagePreview(){
    images.asObservable().subscribe { [weak self] arrayOfImage in
      guard let self = self else {return}
      self.imagePreview.image = arrayOfImage.collage(size: self.imagePreview.frame.size)
    }.disposed(by: disposeBag)

  }
  
  func showMessage(_ title: String, description: String? = nil) {
    alert(title, text: description)
      .subscribe()
      .disposed(by: disposeBag)
  }

  
  private func updateUI(with photos:[UIImage]){
    let checkPhotoIsGreaterThan0  = photos.count > 0
    buttonSave.isEnabled  = checkPhotoIsGreaterThan0 && photos.count % 2 == 0
    buttonClear.isEnabled = checkPhotoIsGreaterThan0
    itemAdd.isEnabled     = photos.count < 6
    title                 = checkPhotoIsGreaterThan0 ? "\(photos.count) photos" : "Collage"
  }
  
  private func updateNavigationIcon(){
    let icon = imagePreview.image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                       style: .done,
                                                       target: nil, action: nil)
  }
}



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
