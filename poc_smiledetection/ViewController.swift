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
    
    var isCalibratingPokerFace = true
    var isCalibrationDone = false
    
    var totalLaughs = 0
    
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
        sceneView.session.delegate = self
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

        UserDefaults.standard.set(smileFactorMouth, forKey: "mouthFactor")
        UserDefaults.standard.set(smileFactorEye, forKey: "eyeFactor")
        
        isCalibrationDone = true
    }
    
    fileprivate func calculateArrayAvarage(_ array: [Double]) -> Double {
        var sum = 0.0
        for num in array {
            sum += num
        }
        return sum / Double(array.count)
    }
    
    fileprivate func updateMessageText(_ text: String) {
        DispatchQueue.main.sync {
             calibrationState.text = text
        }
       
    }
    
    fileprivate func calibrateLaugh(mouthSmileValue: Double, eyeSquintValue: Double) {
        if isCalibratingPokerFace {
            if pokerfacingMouth.count < 100 {
                pokerfacingMouth.append(mouthSmileValue)
                pokerfacingEye.append(eyeSquintValue)
                
                updateMessageText("Calibrando pokerface.")
                
            } else {
                updateMessageText("Calibração pausada.")
            }
        } else {
            if laughingMouth.count < 100 {
                laughingMouth.append(mouthSmileValue)
                laughingEye.append(eyeSquintValue)
                
                updateMessageText("Calibrando sorisso.")
            } else {
                updateMessageText("Calibração concluídas")
                
                calculateSmileFactor()
            }
        }
    }
    
    fileprivate func detectLaugh(mouthSmileValue: Double, eyeSquintValue: Double) {
        let mouthFactor = UserDefaults.standard.double(forKey: "mouthFactor")
        let eyeFactor = UserDefaults.standard.double(forKey: "eyeFactor")
        
        if mouthSmileValue >= mouthFactor && eyeSquintValue >= eyeFactor {
            totalLaughs += 1
            updateMessageText("Você riu \(totalLaughs) vezes!")
        }
    }
    
    @IBAction func toogleCalibration(_ sender: Any) {
        isCalibratingPokerFace = !isCalibratingPokerFace
    }
    
    @IBAction func reDoCalibration(_ sender: Any) {
        pokerfacingEye.removeAll()
        pokerfacingMouth.removeAll()
        laughingEye.removeAll()
        laughingMouth.removeAll()
        
        isCalibrationDone = false
        isCalibratingPokerFace = true
        totalLaughs = 0
        
        UserDefaults.standard.removeObject(forKey: "mouthFactor")
        UserDefaults.standard.removeObject(forKey: "eyeFactor")
    }
}

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        let leftSmileValue = faceAnchor.blendShapes[.mouthSmileLeft] as! Double
        let rightSmileValue = faceAnchor.blendShapes[.mouthSmileRight] as! Double
        let leftSquintValue = faceAnchor.blendShapes[.eyeSquintLeft] as! Double
        let rightSquintValue = faceAnchor.blendShapes[.eyeSquintRight] as! Double
        
        let mouthSmileValue = Double(leftSmileValue + rightSmileValue) / 2.0
        let eyeSquintValue = Double(leftSquintValue + rightSquintValue) / 2.0
        
        if isCalibrationDone {
            detectLaugh(mouthSmileValue: mouthSmileValue, eyeSquintValue: eyeSquintValue)
        } else {
            calibrateLaugh(mouthSmileValue: mouthSmileValue, eyeSquintValue: eyeSquintValue)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            updateMessageText("Tracking perdido!")
        case .limited(.insufficientFeatures):
            updateMessageText("Pouca luminosidade!")
        default:
            return
        }
    }
    
    fileprivate func handleTrackingError() {
        updateMessageText("Tracking perdido!")
    }
}

