//
//  ViewController.swift
//  CocaColaCard
//
//  Created by macbook on 3/17/20.
//  Copyright © 2020 bolattleubayev. All rights reserved.


import UIKit
import SceneKit
import ARKit
import WebKit

class ViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Variables and Constants
    
    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Enable lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages
        
        // Run the view's session
        sceneView.session.run(configuration, options: ARSession.RunOptions(arrayLiteral: [.resetTracking, .removeExistingAnchors]))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let referenceImage = imageAnchor.referenceImage
        
        let physicalWidth = referenceImage.physicalSize.width
        let physicalHeight = referenceImage.physicalSize.height
        
        // Plane for detected image
        let foundImagePlane = SCNPlane(width: physicalWidth, height: physicalHeight)
        foundImagePlane.firstMaterial?.colorBufferWriteMask = .alpha
        
        // Node for detected image
        let detectedNode = SCNNode(geometry: foundImagePlane)
        
        // Rotate plane
        detectedNode.eulerAngles.x = -.pi / 2
        detectedNode.renderingOrder = -1
        detectedNode.opacity = 1
        
        // Add the plane visualization to the scene
        node.addChildNode(detectedNode)
        
        
        flashPlane(on: detectedNode, width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height, completionHandler: {
            
            // Animate the WebView to the right
            self.displayPyramid(on: detectedNode)
            
            // Animate the WebView to the right
            self.displayWebSite(on: detectedNode, horizontalOffset: referenceImage.physicalSize.width)
            
            // Animate the WebView to the right
            self.displayImage(on: detectedNode, horizontalOffset: referenceImage.physicalSize.width)
        })
        
        
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - SceneKit Helpers
    
    
    func displayImage(on rootNode: SCNNode, horizontalOffset: CGFloat) {
        
        let imageToDisplay = UIImage(named: "logoPng")!
        
        let photoPlane = SCNPlane(width: 0.06, height: 0.06)
        
        photoPlane.firstMaterial?.diffuse.contents = imageToDisplay
        photoPlane.cornerRadius = 0.03
        
        let photoPlaneNode = SCNNode(geometry: photoPlane)
        photoPlaneNode.opacity = 1
        photoPlaneNode.position.z += 0.05
        
        rootNode.addChildNode(photoPlaneNode)
        
        photoPlaneNode.runAction(.sequence([.fadeOpacity(to: 1.0, duration: 1.5), .moveBy(x: horizontalOffset * 1.1, y: 0, z: -0.05, duration: 1.5)])
        )
    }
    
    func displayPyramid(on rootNode: SCNNode) {
        DispatchQueue.main.async {
            
            let pyramidScene = SCNScene(named: "art.scnassets/aqorda.scn")
            
            guard let pyramidNode = pyramidScene?.rootNode.childNode(withName: "parent", recursively: false) else {
                return
            }
            
            // Place the node in the correct position
            pyramidNode.position = rootNode.position
            
            // Add the node to the scene
            rootNode.addChildNode(pyramidNode)
            
            pyramidNode.runAction(.sequence([.fadeOpacity(to: 1.0, duration: 1.5), .moveBy(x: 0, y: 0.05, z: 0, duration: 1.5)])
            )
            
        }
    }
    
    func displayWebSite(on rootNode: SCNNode, horizontalOffset: CGFloat) {
        DispatchQueue.main.async {
            
            // Open Google
            let request = URLRequest(url: URL(string: "https://youtu.be/7ehEPsrw1X8")!)
            
            // Define size for Web View, use UI instead WK due to bug
            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: 600, height: 900))
            webView.loadRequest(request)
            
            // Set size
            let webViewPlane = SCNPlane(width: horizontalOffset, height: horizontalOffset * 1.45)
            webViewPlane.cornerRadius = 0.03
            
            // Define geometry
            let webViewNode = SCNNode(geometry: webViewPlane)
            webViewNode.geometry?.firstMaterial?.diffuse.contents = webView
            webViewNode.opacity = 0
            
            // Put a little in from to avoid merger with detected image
            webViewNode.position.z += 0.04
            
            rootNode.addChildNode(webViewNode)
            webViewNode.runAction(.sequence([.fadeOpacity(to: 1.0, duration: 1.5),.moveBy(x: -1 * horizontalOffset * 1.1, y: 0, z: 0, duration: 1.5),])
            )
        }
    }
    
    func flashPlane(on rootNode: SCNNode, width: CGFloat, height: CGFloat, completionHandler block: @escaping (() -> Void)) {
        
        let planeNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        planeNode.opacity = 0
        
        rootNode.addChildNode(planeNode)
        
        planeNode.runAction(SCNAction.sequence([ .wait(duration: 0.2), .fadeOpacity(to: 0.65, duration: 0.25), .fadeOpacity(to: 0.05, duration: 0.25), .fadeOpacity(to: 0.65, duration: 0.25), .fadeOut(duration: 0.5), .removeFromParentNode()])) {
            block()
        }
    }
    
}
