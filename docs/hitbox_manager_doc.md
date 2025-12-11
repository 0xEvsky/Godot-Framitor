# HitboxManager

A singleton node that manages hitbox collision detection and damage events for the Combat Frame Data System.

## Overview

`HitboxManager` detects collisions from `AttackFrameDataNode` instances and emits the `hitLanded` signal. Connect to this signal in your character scripts to implement your own damage logic.

**Key Concept**: This manager **does not apply damage directly**. It only detects hits and emits signals.

## Class Information

- **Extends**: `Node`
- **Class Name**: `HitboxManager`
- **Setup**: Autoload singleton via `Global.gd`

## Signals

### `hitLanded(target: Node2D, damage: float)`

Emitted when an attack hitbox collides with a body.

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `target` | `Node2D` | The body that was hit by the attack |
| `damage` | `float` | The damage value from the current frame data |

#### When It's Emitted

- Called for **every overlapping body** when a frame activates
- Only fires while an attack is active (between `startAttack()` and `endAttack()`)

#### Usage Example

```gdscript
# In your enemy script
extends CharacterBody2D

var health: float = 100.0

func _ready():
    Global.hitboxManager.hitLanded.connect(_on_hit_received)

func _on_hit_received(target: Node2D, damage: float):
    if target == self:
        health -= damage
        print("Health: %s" % health)
        
        if health <= 0:
            queue_free()
```

## Properties

### `currentDamage: float`

The damage value loaded from the current active frame.

- **Default**: `0.0`
- **Updated By**: `loadFrameData()`
- **Access**: Public (can be read directly)
- **Use Case**: Access frame data for custom effects

> **Note**: Only `damage` is currently processed by the system. Other properties like `knockback`, `screenShake`, `hitStop`, and `status` are included in the frame data structure for future expansion but are not yet implemented.

## Methods

### Public Methods

#### `loadFrameData(frameData: Dictionary, attackNode: AttackFrameDataNode) -> void`

Loads frame data from an attack and initiates collision checking.

**Called By**: `AttackFrameDataNode` automatically when a frame activates.

**Parameters**:
- `frameData`: Dictionary containing damage and other attack properties
- `attackNode`: The AttackFrameDataNode that triggered this frame

**Process**:
1. Extracts `damage` from the frame data dictionary
2. Stores it in `currentDamage`
3. Calls `checkAndApplyDamage()` immediately

**Typical Flow**:
```
Animation frame changes
    → AttackFrameDataNode._on_sprite_frame_changed()
    → AttackFrameDataNode._activateFrame()
    → AttackFrameDataNode._activateSingleHitbox()
    → HitboxManager.loadFrameData() ← You are here
    → HitboxManager.checkAndApplyDamage()
    → hitLanded signal emitted
```

---

#### `checkAndApplyDamage(attackNode: AttackFrameDataNode) -> void`

Detects overlapping bodies and emits the `hitLanded` signal for each.

**Parameters**:
- `attackNode`: The Area2D node to check for overlapping bodies

**Process**:
1. Gets all overlapping bodies from the attack node
2. Emits `hitLanded(body, currentDamage)` for each body

### Built-in Methods

#### `_ready() -> void`

Currently empty. Reserved for future initialization if needed.

## Setup Guide

Create a global autoload singleton:

```gdscript
# global.gd
extends Node

var hitboxManager: HitboxManager

func _ready():
    hitboxManager = HitboxManager.new()
    add_child(hitboxManager)
```

**Project Settings**:
1. Go to **Project → Project Settings → Autoload**
2. Add `global.gd` with name **"Global"**
3. Enable it

**Access Anywhere**:
```gdscript
Global.hitboxManager.hitLanded.connect(_on_hit)
```

## Usage Example

Connect to the signal in your character script:

```
User Code                  AttackFrameDataNode              HitboxManager
    |                              |                              |
    |--startAttack()-------------->|                              |
    |                              |                              |
    |                    [Animation frame changes]                |
    |                              |                              |
    |                              |--loadFrameData()------------>|
    |                              |                              |
    |                              |                    [Checks overlaps]
    |                              |                              |
    |<-------------hitLanded signal------------------------[emit]--|
    |                              |                              |
    |--endAttack()---------------->|                              |
```

## Common Issues

### Signal Not Firing

**Possible Causes**:
1. HitboxManager not created or not accessible via `Global.hitboxManager`
2. Forgot to call `startAttack()` on the AttackFrameDataNode
3. No overlapping bodies (check collision layers/masks)
4. Signal not connected properly

**Debug Steps**:
```gdscript
# Verify manager exists
print(Global.hitboxManager)  # Should not be null

# Verify signal connection
print(Global.hitboxManager.hitLanded.get_connections())

# Add debug print in checkAndApplyDamage
func checkAndApplyDamage(attackNode: AttackFrameDataNode):
    var bodies = attackNode.get_overlapping_bodies()
    print("Bodies detected: ", bodies.size())  # Should be > 0
    for body in bodies:
        print("Emitting for: ", body.name)
        hitLanded.emit(body, currentDamage)
```

### Getting Hit By Your Own Attacks

**Solution**: Filter by team, type, or custom logic:

```gdscript
func _on_hit(target: Node2D, damage: float):
    if target == self and target != attacker:  # Don't hit self
        take_damage(damage)
```

### Damage Value Always Zero

**Cause**: Frame data not set properly or `damage` field missing.

**Fix**:
```gdscript
# Verify frame data structure
print(attack_node.frameDataArray)

# Should show:
# [{damage: 10.0, type: 1, ...}, {damage: 15.0, ...}]
```

### Hit Detection Too Sensitive

**Solution**: Use collision layers to filter targets:

```gdscript
# On AttackFrameDataNode (player attacks)
Collision Mask = Layer 2 (enemies only)

# On enemy bodies
Collision Layer = Layer 2
```

## Best Practices

### 1. Use Autoload for Global Access
Always set up HitboxManager as an autoload singleton for easy access from any script.

### 2. Check Target Identity
Always verify the target is what you expect:
```gdscript
if target == self:  # For handling own hits
if target.is_in_group("enemies"):  # For group-based logic
```

### 3. Implement Double-Hit Prevention
Choose a prevention strategy that fits your game's combat style.

### 4. Keep Damage Logic in Characters
Don't put game-specific damage calculations in HitboxManager - keep it generic. Put health, defense, status effects in character scripts.

### 5. Use Collision Layers
Leverage Godot's built-in collision filtering instead of checking types in code.

## Performance Considerations

- **Signal Connections**: Connecting hundreds of entities to one signal is fine - Godot handles this efficiently
- **Overlap Checks**: Called per-frame during active attacks only, not every physics frame
- **Body Iteration**: Only iterates through currently overlapping bodies, not all bodies in scene

## API Summary

```gdscript
# Class
class_name HitboxManager extends Node

# Signal
signal hitLanded(target: Node2D, damage: float)

# Properties
var currentDamage: float

# Methods
func loadFrameData(frameData: Dictionary, attackNode: AttackFrameDataNode) -> void
func checkAndApplyDamage(attackNode: AttackFrameDataNode) -> void
```

## See Also

- [AttackFrameDataNode Documentation](attack_frame_data_node.md) - Frame-based hitbox system
- [Main README](../README.md) - Full plugin setup guide