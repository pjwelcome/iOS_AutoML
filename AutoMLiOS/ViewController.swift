//
//  ViewController.swift
//  AutoMLiOS
//
//  Created by pjapple on 2019/10/28.
//  Copyright © 2019 DVT. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    private var labeler : VisionImageLabeler?
    private var options: VisionOnDeviceAutoMLImageLabelerOptions?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let remoteModel = downloadModelRemotely()
        
        let localModel = useLocalModel()
        if (ModelManager.modelManager().isModelDownloaded(remoteModel)) {
            self.options = VisionOnDeviceAutoMLImageLabelerOptions(remoteModel: remoteModel)
        } else {
            self.options = VisionOnDeviceAutoMLImageLabelerOptions(localModel: localModel!)
        }
        self.options?.confidenceThreshold = 0
        
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        labeler = self.configureModel(with: options)
        presentImagePicker()
    }
    
    private func configureModel(with options: VisionOnDeviceAutoMLImageLabelerOptions?) -> VisionImageLabeler? {
        guard let options = options else {
            return nil
        }
        return Vision.vision().onDeviceAutoMLImageLabeler(options: options)
    }
    
    private func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    private func downloadModelRemotely() -> AutoMLRemoteModel{
        let remoteModel = AutoMLRemoteModel(
            name: "Pavonia_ios"
        )
        let downloadConditions = ModelDownloadConditions(
          allowsCellularAccess: true,
          allowsBackgroundDownloading: true
        )
        let _ = ModelManager.modelManager().download(
          remoteModel,
          conditions: downloadConditions
        )
        return remoteModel
    }
    
    fileprivate func classify(image: UIImage, with labeler :VisionImageLabeler){
        let image = VisionImage(image: image)
        labeler.process(image) {
            guard $1 == nil, let labels = $0 else { return }
            labels.forEach {
                let result = "Label: \($0.text) with a confidence of \(($0.confidence ?? 0).doubleValue * 100) \n"
                self.resultLabel.text = "\(self.resultLabel.text ?? "") \(result)"
                print(result)
            }
        }
    }
    
    private func useLocalModel() -> AutoMLLocalModel? {
        
        guard let manifestPath = Bundle.main.path(
            forResource: "manifest",
            ofType: "json"
        ) else { return nil }
        let localModel = AutoMLLocalModel(manifestPath: manifestPath)
        return localModel
    }
}

extension ViewController : UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var image : UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        } else if let orginalImage = info[.originalImage] as? UIImage {
            image = orginalImage
        }
        guard let labeler = self.labeler , let imageToPredict = image else { return }
        self.imageView.image = imageToPredict
        self.classify(image: imageToPredict, with: labeler)
        dismiss(animated: true)
    }
}

extension ViewController : UINavigationControllerDelegate {}

