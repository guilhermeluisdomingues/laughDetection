//
//  ViewController.swift
//  poc_smiledetection
//
//  Created by Guilherme Domingues on 13/04/20.
//  Copyright © 2020 Guilherme Domingues. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    var configuration = ARFaceTrackingConfiguration()
    
    var laughingMouth: [Double] = []
    var laughingEye: [Double] = []
    var pokerfacingMouth: [Double] = []
    var pokerfacingEye: [Double] = []
    
    var isValidatingPokerFace = true
    var isCalibrationDone = false
    
    @IBOutlet weak var calibrationState: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Devices does not support ARFaceTraking")
            return
        }
        
        grantAccessToCameraDevice()
    
    }
    
    fileprivate func grantAccessToCameraDevice() {
           AVCaptureDevice.requestAccess(for: .video) { (granted) in
               if granted {
                   DispatchQueue.main.sync {
                       self.setupFaceTracking()
                   }
               } else {
                   print("Camera access not granted")
                   UserDefaults.standard.set(granted, forKey: "hasGrantToCamera")
               }
           }
       }
       
    
    fileprivate func setupFaceTracking() {
        sceneView.session.run(configuration)
        sceneView.delegate = self
        view.addSubview(sceneView)
    }
    
    fileprivate func calculateSmileFactor() {
        let pokerFaceMouthAvg = calculateArrayAvarage(pokerfacingMouth)
        let smileFaceMouthAvg = calculateArrayAvarage(laughingMouth)
        let pokerFaceEyeAvg = calculateArrayAvarage(pokerfacingEye)
        let smileFaceEyeAvg = calculateArrayAvarage(laughingEye)
        
        print("smileFaceEyeAvg: \(smileFaceEyeAvg)")
        print("pokerFaceEyeAvg: \(pokerFaceEyeAvg)")
        print("smileFaceMouthAvg: \(smileFaceMouthAvg)")
        print("pokerFaceMouthAvg: \(pokerFaceMouthAvg)")
        
        let smileFactorMouth = (pokerFaceMouthAvg + smileFaceMouthAvg) / 2.0
        let smileFactorEye = (pokerFaceEyeAvg + smileFaceEyeAvg) / 2.0
        
        print("smileFactorMouth: \(smileFactorMouth)")
        print("smileFactorEye: \(smileFactorEye)")
        
        let smileFactor = (smileFactorEye + smileFactorMouth) / 2.0
        
        print("smileFactor: \(smileFactor)")
        print("=======================================")

        //        UserDefaults.standard.set(smileFactor, forKey: "smile_factor")
        isCalibrationDone = true
    }
    
    fileprivate func calculateArrayAvarage(_ array: [Double]) -> Double {
        var sum = 0.0
        for num in array {
            sum += num
        }
        return sum / Double(array.count)
    }
    
    @IBAction func toogleCalibration(_ sender: Any) {
        isValidatingPokerFace = !isValidatingPokerFace
    }
    
    @IBAction func reDoCalibration(_ sender: Any) {
        pokerfacingEye.removeAll()
        pokerfacingMouth.removeAll()
        laughingEye.removeAll()
        laughingMouth.removeAll()
        
        isCalibrationDone = false
        isValidatingPokerFace = true
    }
}

extension ViewController: ARSCNViewDelegate {
    
    fileprivate func updateCalibrationState(_ text: String) {
        DispatchQueue.main.sync {
             calibrationState.text = text
        }
       
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else {return}
        
        guard !isCalibrationDone else { return }
        
        let leftSmileValue = faceAnchor.blendShapes[.mouthSmileLeft] as! Double
        let rightSmileValue = faceAnchor.blendShapes[.mouthSmileRight] as! Double
        let leftSquintValue = faceAnchor.blendShapes[.eyeSquintLeft] as! Double
        let rightSquintValue = faceAnchor.blendShapes[.eyeSquintRight] as! Double
        
        if isValidatingPokerFace {
            if pokerfacingMouth.count < 100 {
                let mouthSmileValue = Double(leftSmileValue + rightSmileValue) / 2.0
                pokerfacingMouth.append(mouthSmileValue)
                
                let eyeSquintValue = Double(leftSquintValue + rightSquintValue) / 2.0
                pokerfacingEye.append(eyeSquintValue)
                
                updateCalibrationState("Calibrando pokerface.")
                
            } else {
                updateCalibrationState("Calibração pausada.")
            }
        } else {
            if laughingMouth.count < 100 {
                let mouthSmileValue = Double(leftSmileValue + rightSmileValue) / 2.0
                laughingMouth.append(mouthSmileValue)
                
                let eyeSquintValue = Double(leftSquintValue + rightSquintValue) / 2.0
                laughingEye.append(eyeSquintValue)
                                
                updateCalibrationState("Calibrando sorisso.")
            } else {
                updateCalibrationState("Calibração concluídas")
                
                calculateSmileFactor()
            }
        }
    }
}

