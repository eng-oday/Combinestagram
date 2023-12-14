

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

  override func viewDidLoad() {
    super.viewDidLoad()
    subscribeToImagesToSetupUi()
    subscribeOnImagesToUpdateImagePreview()
  }
  
  @IBAction func actionClear() {
    images.accept([])
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
    
    photosViewController.selectedPhotos.subscribe { [weak self] image in
      guard let self else {return}
      let arrayOfImages = self.images.value + [image]
      self.images.accept(arrayOfImages)
    }onDisposed: { 
      print("completed photo selection")
    }
    .disposed(by: disposeBag)
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
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
    present(alert, animated: true, completion: nil)
  }
  
  private func updateUI(with photos:[UIImage]){
    let checkPhotoIsGreaterThan0  = photos.count > 0
    buttonSave.isEnabled  = checkPhotoIsGreaterThan0 && photos.count % 2 == 0
    buttonClear.isEnabled = checkPhotoIsGreaterThan0
    itemAdd.isEnabled     = photos.count < 6
    title                 = checkPhotoIsGreaterThan0 ? "\(photos.count) photos" : "Collage"
  }
}
