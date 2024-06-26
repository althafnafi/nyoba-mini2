//
//  GameScene.swift
//  nyoba-mini2
//
//  Created by Althaf Nafi Anwar on 10/06/24.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    /* Constants */
    private var groundCategory : UInt32 = 0b1 << 0 // 1
    private var ballCategory : UInt32 = 0b1 << 1 // 2
    private let restoringTorqueMult : CGFloat = 10.0
    private let dampingTorqueMult : CGFloat = 0.5
    /* Constants */
    
    override func sceneDidLoad() {
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        spawnGround()
        
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        print("touchDown")
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
        print("touchUp \(pos)")
        spawnPhysicsObject(posClicked: pos)
    }
    
    func spawnGround() {
        // Define the anchor node
        let anchorNode = SKNode()
        anchorNode.position = CGPoint(x: 0, y: 0)
        anchorNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: 1))
        anchorNode.physicsBody?.isDynamic = false // Anchor node is static
        
        // Define the ground node
        let ground = SKSpriteNode(color: .white, size: CGSize(width: UIScreen.main.bounds.width * 0.8, height: 35))
        ground.position = CGPoint(x: 0, y: 0) // Middle of the screen
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        
        // Set up the physics body properties
        ground.physicsBody?.isDynamic = true // Allows the ground to move
        ground.physicsBody?.affectedByGravity = true // Allow the ground to be affected by gravity
        ground.physicsBody?.allowsRotation = true // Allows the ground to rotate
        
        // Set up the category and contact bitmasks
        ground.physicsBody?.categoryBitMask = groundCategory
        ground.physicsBody?.contactTestBitMask = ballCategory
        
        // Set the restitution (bounciness)
        ground.physicsBody?.restitution = 0.75
        ground.physicsBody?.friction = 0.2
        
        // Create a spring joint to allow vertical movement and rotation
        let springJoint = SKPhysicsJointSpring.joint(withBodyA: anchorNode.physicsBody!, bodyB: ground.physicsBody!, anchorA: anchorNode.position, anchorB: ground.position)
        springJoint.frequency = 2 // Spring frequency
        springJoint.damping = 0.1 // Spring damping
        
        // Add the nodes to the scene
        self.addChild(anchorNode)
        self.addChild(ground)
        
        // Add the spring joint to the physics world
        self.physicsWorld.add(springJoint)
        
        // Add an action to the ground to apply restoring torque with damping
        let restoreAction = SKAction.repeatForever(SKAction.customAction(withDuration: 0.1) { node, _ in
            if let physicsBody = node.physicsBody {
                let currentAngle = physicsBody.node?.zRotation ?? 0
                let angularVelocity = physicsBody.angularVelocity
                let restoringTorque = -currentAngle * self.restoringTorqueMult // Increased factor for faster restoration
                let dampingTorque = -angularVelocity * self.dampingTorqueMult // Damping factor to reduce oscillation
                physicsBody.applyTorque(restoringTorque + dampingTorque)
            }
        })
        ground.run(restoreAction)
        spawnTestCube(ground: ground)
    }
    
    func spawnTestCube(ground: SKSpriteNode) {
        // Add a green cube on top of the middle of the ground
        let cubeSize = CGSize(width: 30, height: 30)
        let greenCube = SKSpriteNode(color: .green, size: cubeSize)
        greenCube.position = CGPoint(x: 0, y: ground.position.y + ground.size.height / 2 + cubeSize.height / 2)
        greenCube.physicsBody = SKPhysicsBody(rectangleOf: cubeSize)

        // Set up the cube's physics body properties
        greenCube.physicsBody?.isDynamic = true
        greenCube.physicsBody?.affectedByGravity = true
        greenCube.physicsBody?.allowsRotation = true
        
        greenCube.physicsBody?.collisionBitMask = groundCategory

        // Add the cube to the scene
        self.addChild(greenCube)
    }
    
    func spawnPhysicsObject(posClicked: CGPoint) {
        // Define the object
        let ballRadius : CGFloat = 20
        let newObject = SKShapeNode(circleOfRadius: ballRadius)
        newObject.fillColor = .red
        newObject.position = posClicked
        
        // Add physics properties to the object
        newObject.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
        newObject.physicsBody?.collisionBitMask = groundCategory
//        newObject.physicsBody?.categoryBitMask = ballCategory
        
        // Add object to scene
        self.addChild(newObject)
        
        print("Added a new object")
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Will only be triggered if any of below returns a non-zero
        // bodyA.category AND bodyB.contact
        // bodyA.contact AND bodyB.category
        print("Collision")
        print("A: \(contact.bodyA.collisionBitMask), B: \(contact.bodyB.collisionBitMask)")
        print("Category")
        print("A: \(contact.bodyA.categoryBitMask), B: \(contact.bodyB.categoryBitMask)")
        print("Contact")
        print("A: \(contact.bodyA.contactTestBitMask), B: \(contact.bodyB.contactTestBitMask)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
