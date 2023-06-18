//
//  ViewController.swift
//  ScratchyFilm
//
//  Created by 김인환 on 2023/06/18.
//

import UIKit

class ViewController: UIViewController {
    
    let image = UIImage(named: "CupHead")

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let sepiaImage = applyingSepiaFilter(to: image!),
              let scratchedImage = applyingRandomNoise(to: sepiaImage) else { return }
        let imageView = UIImageView(image: scratchedImage)
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // apply the sepia tone filter to the original image
    func applyingSepiaFilter(to image: UIImage) -> UIImage? {
        let inputImage = CIImage(image: image)
        
        guard let filter = CIFilter(name: "CISepiaTone") else {
            return nil
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.5, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let context = CIContext(options: nil)
        
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // simulate grain by creating randomly varing speckle
    func applyingRandomNoise(to image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return nil }
        
        guard let colorNoise = CIFilter(name: "CIRandomGenerator"),
              let noiseImage = colorNoise.outputImage else {
            return nil
        }
        
        let whitenVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        let fineGrain = CIVector(x: 0, y: 0.005, z: 0, w: 0)
        let zeroVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        
        guard let whiteningFilter = CIFilter(name: "CIColorMatrix", parameters: [
            kCIInputImageKey: noiseImage,
            "inputRVector": whitenVector,
            "inputGVector": whitenVector,
            "inputBVector": whitenVector,
            "inputAVector": fineGrain,
            "inputBiasVector": zeroVector
        ]),
              let whiteSpecks = whiteningFilter.outputImage else {
            return nil
        }
        
        guard let speckCompositor = CIFilter(name: "CISourceOverCompositing", parameters: [
            kCIInputImageKey: whiteSpecks,
            kCIInputBackgroundImageKey: inputImage
        ]),
              let speckledImage = speckCompositor.outputImage else {
            return nil
        }
        
        let verticalScale = CGAffineTransform(scaleX: 1.5, y: 25)
        let transformedNoise = noiseImage.transformed(by: verticalScale)
        
        let darkenVector = CIVector(x: 4, y: 0, z: 0, w: 0)
        let darkenBias = CIVector(x: 0, y: 1, z: 1, w: 1)
        
        guard let darkeningFilter = CIFilter(name: "CIColorMatrix", parameters: [
            kCIInputImageKey: transformedNoise,
            "inputRVector": darkenVector,
            "inputGVector": zeroVector,
            "inputBVector": zeroVector,
            "inputAVector": zeroVector,
            "inputBiasVector": darkenBias
        ]),
              let randomScratches = darkeningFilter.outputImage else {
            return nil
        }
        
        guard let grayscaleFilter = CIFilter(name: "CIMinimumComponent", parameters: [
            kCIInputImageKey: randomScratches
        ]),
              let darkScratches = grayscaleFilter.outputImage else {
            return nil
        }
        
        guard let oldFilmCompositor = CIFilter(name: "CIMultiplyCompositing", parameters: [
            kCIInputImageKey: darkScratches,
            kCIInputBackgroundImageKey: speckledImage
        ]),
              let oldFilmImage = oldFilmCompositor.outputImage else {
            return nil
        }
        
        let finalImage = oldFilmImage.cropped(to: inputImage.extent)
        return UIImage(ciImage: finalImage)
    }
}

