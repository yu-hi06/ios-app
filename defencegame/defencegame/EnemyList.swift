//
//  EnemyList.swift
//  defencegame
//
//  Created by 大谷勇陽 on 2016/02/19.
//  Copyright © 2016年 大谷勇陽. All rights reserved.
//

import UIKit
import SpriteKit
class EnemyList {
    private var enemies = [SKSpriteNode]()
    func count() -> Int {
        return enemies.count
    }
    func Enemies(Integer: Int) -> SKSpriteNode{
        return enemies[Integer]
    }
    func appendEnemy(enemy: SKSpriteNode) {
        enemies.append(enemy)
    }
    
    func isAllEnemyRemoved() -> Bool {
        return enemies.filter { $0.parent != nil }.count == 0
    }
}
