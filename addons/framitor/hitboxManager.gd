
## Manages hitbox collision detection for the Combat Frame Data System.
##
## This manager detects when attack hitboxes collide with bodies and emits
## the [signal hitLanded] signal. Connect to this signal in your character
## scripts to handle damage.
##
## [b]Example Usage:[/b]
## [codeblock]
## # In enemy or player script
## func _ready():
##     Global.hitboxManager.hitLanded.connect(_on_hit_received)
##
## func _on_hit_received(target: Node2D, damage: float):
##     # Hit logic
## [/codeblock]

extends Node
class_name HitboxManager

signal hitLanded(target: Node2D, damage: float)
var currentDamage: float = 0.0

func _ready():
    pass

func loadFrameData(frameData: Dictionary, attackNode: AttackFrameDataNode):
    currentDamage = frameData.get("damage", 0.0)
    checkAndApplyDamage(attackNode)


func checkAndApplyDamage(attackNode: AttackFrameDataNode):
    var bodies = attackNode.get_overlapping_bodies()

    for body in bodies:
        hitLanded.emit(body, currentDamage)
           