//
//  ViewController.swift
//  Flower Classification
//
//  Created by Elina Mansurova on 2020-12-29.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    let baseURL = "https://en.wikipedia.org/w/api.php"
    
    @IBOutlet weak var textLabelfromWiki: UITextView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imageView.image = UIImage(named: "172")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let ciImage = CIImage(image: pickedImage) else {
                fatalError("Couldn't convert to CIImage")
            }
           
            detect(flowerImage: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func plusTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func detect(flowerImage: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else { fatalError("Loading FlowerClassifier model failed") }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results?.first as? VNClassificationObservation else { fatalError("Could not convert results") }
            self.navigationItem.title = results.identifier.capitalized
            self.requestInfo(flowerName: results.identifier)
        }
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let requiredParameters: [String: String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
            
        Alamofire.request(baseURL, method: .get, parameters: requiredParameters).responseJSON { (response) in
            if response.result.isSuccess {
                //print(response.result.value)
                let flowerJSON: JSON = JSON(response.result.value!)
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].string
                self.imageView.sd_setImage(with: URL(string: flowerImageURL ?? ""))
                self.textLabelfromWiki.text = flowerDescription
            }
        }
    }
}

