//
//  ViewController.swift
//  ARShots
//
//  Created by 新井進鎬 on 2019/01/18.
//  Copyright © 2019 chino. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        configuration.environmentTexturing = .automatic

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    var hoopAdded = false
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if !hoopAdded {
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult   = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
            
            if let result = hitTestResult.first {
                addHoop(result: result)
                hoopAdded = true
            }
        } else {
            createBasketball()
        }
    }

    func addHoop(result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else {
            return
        }
        
        // worldTransform は 4x4行列（0: x軸回転, 1: y軸回転, 2: z軸回転, 3: 空間座標位置）
        let planePosition = result.worldTransform.columns.3
        hoopNode.position = SCNVector3(planePosition.x, planePosition.y, planePosition.z)

        let hoopShape = SCNPhysicsShape(node: hoopNode,
                                        options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: hoopShape)
        sceneView.scene.rootNode.addChildNode(hoopNode)
    }
    
    func createBasketball() {
        guard let currentFrame = sceneView.session.currentFrame else { return  }
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        
        let cameraTransform = SCNMatrix4(currentFrame.camera.transform)
        ball.transform = cameraTransform
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        ball.physicsBody = physicsBody
        
        let power = Float(10.0)
        let force = SCNVector3(x: -cameraTransform.m31*power,
                                                y: -cameraTransform.m32*power,
                                                z: -cameraTransform.m33*power)
        ball.physicsBody?.applyForce(force, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    func createWall(from anchor: ARPlaneAnchor) -> SCNNode{
        let anchorWidth  = CGFloat(anchor.extent.x)
        let anchorHeight = CGFloat(anchor.extent.y)
        
        let wallGeometry = SCNPlane(width: anchorWidth, height: anchorHeight)
        wallGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        let wallNode = SCNNode(geometry: wallGeometry)
        wallNode.opacity = 0.25
        wallNode.eulerAngles.x = -Float.pi/2

        return wallNode
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return  }
        
        let wall = createWall(from: planeAnchor)
        node.addChildNode(wall)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let wallNode = node.childNodes.first,
            let wallNodeGeometry = wallNode.geometry as? SCNPlane
            else { return }
        
        let updatedPosition = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        wallNode.position = updatedPosition
        
        wallNodeGeometry.width  = CGFloat(planeAnchor.extent.x)
        wallNodeGeometry.height = CGFloat(planeAnchor.extent.z)
    }
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
