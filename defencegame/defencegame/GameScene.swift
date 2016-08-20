//
//  GameScene.swift
//  defencegame
//
//  Created by 大谷勇陽 on 2016/02/18.
//  Copyright (c) 2016年 大谷勇陽. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    enum State {
        case Playing
        case GameClear
        case GameOver
    }
    var state = State.Playing
    var enemyList = EnemyList()
    let char = SKSpriteNode(imageNamed: "Char")
    var routes = [float2]()
    var shotLayer = SKSpriteNode()
    override func didMoveToView(view: SKView) {
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        let fieldImageLength = view.frame.width / 10
        let field = FieldFactory().createField(view.frame.size, fieldImageLength: fieldImageLength)
        field.nodes.forEach {
            addChild($0)
        }
        //主人公の作成
        char.position = CGPoint(x:250, y:300)
        char.physicsBody = SKPhysicsBody(rectangleOfSize: char.size)
        char.physicsBody?.categoryBitMask = 0x1
        char.physicsBody?.collisionBitMask = 0x10
        char.name = "Char"
        addChild(char)
        //弾レイヤーの作成
        //shotLayer = SKSpriteNode(color: SKColor.clearColor(), size: CGSizeMake(360,640))
        //shotLayer.anchorPoint = CGPointMake(0, 0)
        self.addChild(shotLayer)
        
        
        routes = routesWithField(field)
        // 敵を10体出現させる処理
        (0...10).forEach {
            performSelector("createEnemy", withObject: nil, afterDelay: Double($0))
        }
    }
    
    private func routesWithField(field: Field) -> [vector_float2] {
        let fields = children.filter { $0.name == "Field0" }
        let obstacles = SKNode.obstaclesFromNodePhysicsBodies(fields)
        let graph = GKObstacleGraph(obstacles: obstacles, bufferRadius: 10)
        let start = GKGraphNode2D(point: vector_float2(Float(field.start.x), Float(field.start.y)))
        let end = GKGraphNode2D(point: vector_float2(Float(field.end.x), Float(field.end.y)))
        graph.connectNodeUsingObstacles(start)
        graph.connectNodeUsingObstacles(end)
        let nodes = graph.findPathFromNode(start, toNode: end)
        return nodes.flatMap { $0 as? GKGraphNode2D }.map { $0.position }
    
    }
    
    func createEnemy() {
        guard let view = view else {
            return
        }
        
        let enemy = SKSpriteNode(imageNamed: "Enemy")
        var routes = self.routes
        var prevPosition = routes.removeFirst()
        let actions = routes.map { p -> SKAction in
            let dx = p.x - prevPosition.x
            let dy = p.y - prevPosition.y
            let duration = Double(sqrt(dx * dx + dy * dy) / 100)
            prevPosition = p
            return SKAction.moveTo(CGPoint(x: Double(p.x), y: Double(p.y)), duration: duration)
        }
        
        let fieldImageLength = view.frame.width / 10
        enemy.name = "enemy"
        enemy.position = CGPoint(x: fieldImageLength * 2, y: view.frame.height)
        enemy.physicsBody = SKPhysicsBody(rectangleOfSize: enemy.size)
        enemy.physicsBody?.contactTestBitMask = 0xFFFFFFFF
        enemy.runAction(SKAction.sequence(actions)) {
            self.state = .GameOver
            
            let myLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
            myLabel.text = "ゲームオーバー"
            myLabel.fontSize = 45
            myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame) - 20)
            self.addChild(myLabel)
        }
        addChild(enemy)
        
        //enemies.append(enemy)
        enemyList.appendEnemy(enemy)
    }
    //衝突
    func didBeginContact(contact: SKPhysicsContact) {
        var contactlist = [contact.bodyA, contact.bodyB]
        print(contactlist[0].node?.name)
        print(contactlist[1].node?.name)
        if contactlist[0].node?.name == "enemy" && contactlist[1].node?.name == "sht1"{
                contactlist[0].node?.removeFromParent()
                contactlist[0].node?.removeAllActions()
                contactlist[1].node?.removeFromParent()
                contactlist[1].node?.removeAllActions()
        }
        if contactlist[1].node?.name == "enemy" && contactlist[0].node?.name == "sht1"{
            contactlist[0].node?.removeFromParent()
            contactlist[0].node?.removeAllActions()
            contactlist[1].node?.removeFromParent()
            contactlist[1].node?.removeAllActions()
        }


        
        if enemyList.isAllEnemyRemoved() {
            state = .GameClear
        
            let myLabel = SKLabelNode(fontNamed: "HiraginoSans-W6")
            myLabel.text = "ゲームクリア"
            myLabel.fontSize = 45
            myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame)-20)
            addChild(myLabel)
        }
    }
    var movestatus = "non"
    override func touchesBegan( touches: Set<UITouch>, withEvent event:UIEvent?) {
        let location = touches.first!.locationInNode(self)
        let touchednode = self.nodeAtPoint(location)
        if touchednode.name == "Char" {
           movestatus = "Char"
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if movestatus == "Char" {
            let touchPos = touches.first!.locationInNode(self)
            char.runAction(SKAction.moveTo(touchPos, duration:0.0))
        }
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if movestatus == "Char" {
            movestatus = "non"
            addShot()
        }
    }
    override func didEvaluateActions() {
        for (var i = 0; i < shotLayer.children.count; i++) {
            let shot = shotLayer.children[i] as! SKSpriteNode
            if shot.position.x == 0 || shot.position.x >= 480{
                shot.removeFromParent()
            }
        }
    }
    //弾の追加
    func addShot() {
        let shot = SKSpriteNode(imageNamed: "sht1")
        shot.position = CGPointMake(char.position.x, char.position.y)
        shot.physicsBody = SKPhysicsBody(rectangleOfSize: shot.size)
        shot.physicsBody?.categoryBitMask = 0x1
        shot.physicsBody?.collisionBitMask = 0x10
        //shot.physicsBody?.dynamic = false
        shot.name="sht1"
        shot.runAction(SKAction.moveToX(0, duration: 3))
        shotLayer.addChild(shot)
    }
    
}
