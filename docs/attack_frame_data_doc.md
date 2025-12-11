# AttackFrameDataNode

A custom Area2D node that manages frame-based hitbox data for character attacks in the Combat Frame Data System.

## Overview

`AttackFrameDataNode` synchronizes hitbox activation with AnimatedSprite2D animation frames. Each frame of your attack animation can have different hitbox properties (damage, knockback, etc.) or no hitbox at all (for wind-up and recovery frames).

## Class Information

- **Extends**: `Area2D`
- **Class Name**: `AttackFrameDataNode`
- **Tool Script**: Yes (provides editor buttons)

## Properties

### Exported Properties

#### `animationName: String`
The name of the animation this attack node syncs with.

- **Default**: `""` (empty)
- **Required**: Yes
- **Example**: `"light_attack"`, `"heavy_punch"`, `"special_move"`

**Error if empty**: The node will push an error on `_ready()` if this is not set.

---

#### `sprite: AnimatedSprite2D`
Reference to the character's AnimatedSprite2D node.

- **Default**: `null`
- **Required**: Yes
- **Setup**: Drag and drop from the scene tree in the inspector

**Error if null**: The node will push an error on `_ready()` if this is not assigned.

---

#### `hitboxManager: HitboxManager`
Optional reference to a custom HitboxManager instance.

- **Default**: `null`
- **Required**: No (falls back to `Global.hitboxManager`)
- **Use Case**: For testing or multiple combat systems in one project

---

#### `frameDataArray: Array[Dictionary]`
Array containing frame-by-frame attack data.

- **Default**: `[]` (empty array)
- **Populated By**: Editor buttons (see [Editor Tools](#editor-tools))
- **Structure**: See [Frame Data Structure](#frame-data-structure)

### Internal Properties

#### `hitboxShapes: Array[CollisionShape2D]`
Cached array of child CollisionShape2D nodes. Automatically populated by `_cacheHitboxes()`.

#### `isAttackActive: bool`
Flag indicating whether the attack is currently active. Set by `startAttack()` and `endAttack()`.

## Enums

### FrameType

Defines the type of hitbox behavior for each frame.

```gdscript
enum FrameType {
    EMPTY,   # No hitbox active (wind-up/recovery)
    SINGLE,  # One active hitbox
    MULTI    # Multiple hitboxes (not yet implemented)
}
```

## Methods

### Public Methods

#### `startAttack() -> void`
Enables attack detection. Call this when the attack animation begins.

**Behavior**:
- Sets `isAttackActive` to `true`
- Clears the hit list (prevents double-hits from previous attacks)
- Disables monitoring initially (enabled per-frame)

**Example**:
```gdscript
# In attack state or input handler
func start_light_attack():
    attack_node.startAttack()
    sprite.play("light_attack")
```

---

#### `endAttack() -> void`
Disables attack detection. Call this when the attack animation finishes.

**Behavior**:
- Sets `isAttackActive` to `false`
- Disables all hitboxes
- Disables monitoring

**Example**:
```gdscript
# After animation finishes
await sprite.animation_finished
attack_node.endAttack()
```

### Private Methods

#### `_ready() -> void`
Initializes the node.

**Operations**:
1. Disables Area2D monitoring and monitorable
2. Validates `animationName` and `sprite` are set
3. Caches all child CollisionShape2D nodes

---

#### `_cacheHitboxes() -> void`
Collects all CollisionShape2D children and sorts them by name.

**Sort Order**: Alphabetical by node name (e.g., "Frame0", "Frame1", "Frame2")

---

#### `_setupSpriteConnection() -> void`
Connects to the sprite's `frame_changed` signal.

**Note**: Currently not called automatically - intended for future use or manual setup.

---

#### `_disableAllHitboxes() -> void`
Disables all cached CollisionShape2D nodes.

---

#### `_activateSingleHitbox(frameData: Dictionary) -> void`
Activates a single hitbox based on frame data.

**Process**:
1. Gets hitbox index from frame data
2. Enables the corresponding CollisionShape2D
3. Enables Area2D monitoring
4. Loads frame data into HitboxManager

---

#### `_on_sprite_frame_changed() -> void`
Signal callback when the sprite's current frame changes.

**Conditions**:
- Only processes if `isAttackActive` is true
- Only processes if sprite animation matches `animationName`
- Calls `_activateFrame()` with current sprite frame

---

#### `_activateFrame(frameIndex: int) -> void`
Activates hitboxes for a specific frame index.

**Process**:
1. Disables all hitboxes
2. Checks if frame index is valid
3. Gets frame data from `frameDataArray`
4. Matches frame type and activates accordingly

## Frame Data Structure

Each dictionary in `frameDataArray` represents one animation frame:

```gdscript
{
    "type": FrameType.SINGLE,      # Frame type (EMPTY, SINGLE, MULTI)
    "hitboxIndex": 0,              # Which CollisionShape2D to use (0-based)
    "damage": 10.0,                # Damage amount
    "knockback": Vector2(100, -50),# Knockback force (not yet implemented)
    "screenShake": 0.2,            # Screen shake intensity (not yet implemented)
    "hitStop": 0.1,                # Hitstop duration (not yet implemented)
    "status": {}                   # Custom status effects (not yet implemented)
}
```

### Field Descriptions

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | `FrameType` | `SINGLE` | Frame behavior type |
| `hitboxIndex` | `int` | Auto-set | Index of CollisionShape2D child to activate |
| `damage` | `float` | `0.0` | Damage value passed to HitboxManager |
| `knockback` | `Vector2` | `(0, 0)` | Knockback force (future feature) |
| `screenShake` | `float` | `0.0` | Screen shake intensity (future feature) |
| `hitStop` | `float` | `0.0` | Hitstop duration in seconds (future feature) |
| `status` | `Dictionary` | `{}` | Custom status effects (future feature) |

> **Note**: Currently only `type`, `hitboxIndex`, and `damage` are processed. Other fields are reserved for future features but can be accessed manually via `Global.hitboxManager`.

## Editor Tools

The node provides editor buttons in the inspector for easy frame creation:

### Available Buttons

#### ➕ Add Single Frame
Creates a new frame with one hitbox.

**Creates**:
- A CollisionShape2D child node named "FrameN"
- Default RectangleShape2D (20x160 size)
- Frame data entry with default values

---

#### ⚪ Add Empty Frame
Creates a frame with no active hitbox.

**Use Cases**:
- Wind-up frames at attack start
- Recovery frames at attack end
- Transition frames between active frames

---

#### ➕ Add Multi-Frame (2/3)
Reserved for future multi-hitbox support.

**Status**: Not yet implemented

---

#### 🗑️ Clear All Frames
Removes all frame data and child CollisionShape2D nodes.

**Warning**: This action cannot be undone. Use with caution.

---

#### Log Frame Data Array
Prints the current `frameDataArray` to the console for debugging.

## Setup Guide

### Basic Setup

1. **Add the Node**
   ```
   Player (CharacterBody2D)
   ├── Sprite (AnimatedSprite2D)
   ├── FrameDataContainer (Node2D)
   │   └── LightAttack (AttackFrameDataNode) ← Add here
   └── CollisionShape2D
   ```

2. **Configure Properties**
   - Set **Animation Name** to match your AnimatedSprite2D animation
   - Drag your **AnimatedSprite2D** into the Sprite field

3. **Create Frames**
   - Click **➕ Add Single Frame** for each frame in your animation
   - Click **⚪ Add Empty Frame** for wind-up/recovery frames
   - Adjust CollisionShape2D positions and sizes in the viewport

4. **Trigger in Code**
   ```gdscript
   # Start attack
   attack_node.startAttack()
   sprite.play("light_attack")
   
   # End attack
   await sprite.animation_finished
   attack_node.endAttack()
   ```

### Advanced Setup

#### Multiple Attacks Per Character

```
Player
├── Sprite
└── FrameDataContainer
    ├── LightAttack (AttackFrameDataNode)
    ├── HeavyAttack (AttackFrameDataNode)
    └── SpecialMove (AttackFrameDataNode)
```

Access different attacks dynamically:
```gdscript
var attack_node = $FrameDataContainer.get_node(attack_name)
attack_node.startAttack()
```

#### Custom Collision Layers

Use Godot's collision layer system to filter what gets hit:

- **Inspector > AttackFrameDataNode > Collision**
  - **Layer**: Which layer this attack is on (e.g., Layer 1 for player attacks)
  - **Mask**: Which layers this attack can hit (e.g., Layer 2 for enemies)

## Workflow Example

### Creating a 5-Frame Attack Animation

1. Your animation has 5 frames: [wind-up, active, active, active, recovery]

2. In inspector, click buttons:
   - **⚪ Add Empty Frame** (frame 0 - wind-up)
   - **➕ Add Single Frame** (frame 1 - first active)
   - **➕ Add Single Frame** (frame 2 - second active)
   - **➕ Add Single Frame** (frame 3 - third active)
   - **⚪ Add Empty Frame** (frame 4 - recovery)

3. Adjust the three CollisionShape2D children in the viewport to match your sprite's attack visuals

4. Modify frame data in inspector:
   ```
   frameDataArray[1]: damage = 5.0
   frameDataArray[2]: damage = 8.0  (sweet spot)
   frameDataArray[3]: damage = 3.0  (late hit)
   ```

## Common Issues

### "animationName must be set" Error
**Cause**: The Animation Name field is empty.  
**Fix**: Set it to match an animation in your AnimatedSprite2D (e.g., "attack", "punch").

### "sprite must be set" Error
**Cause**: No AnimatedSprite2D is assigned.  
**Fix**: Drag your AnimatedSprite2D node into the Sprite field in the inspector.

### Hitboxes Not Activating
**Possible Causes**:
1. Forgot to call `startAttack()`
2. Animation name doesn't match exactly (case-sensitive)
3. No frames created with editor buttons
4. Frame data array size doesn't match animation frame count

**Debug Steps**:
1. Click "Log Frame Data Array" button to verify frames exist
2. Print `sprite.animation` and `animationName` to verify they match
3. Verify `isAttackActive` is true during animation

### Hitting Same Enemy Multiple Times
**This shouldn't happen** - the system prevents double hits automatically via `Global.hitboxManager.alreadyHit`.

**If it does happen**:
- Make sure you're calling `endAttack()` when the attack finishes
- Verify you're not starting multiple attacks simultaneously

## Best Practices

### Naming Conventions
- **Node Names**: Descriptive attack names (e.g., "LightAttack", "HeavyPunch")
- **Animation Names**: Match node names when possible for clarity
- **Frame Names**: Auto-generated "Frame0", "Frame1", etc. work well

### Performance
- Create one AttackFrameDataNode per attack type, not per animation frame
- Reuse nodes for similar attacks if frame data is the same
- CollisionShape2D nodes are lightweight - don't worry about having many children

### Organization
- Use a container Node2D to group all attack nodes
- Keep attack nodes as children of the character, not the sprite
- Name nodes clearly to identify which attack they represent

## API Summary

```gdscript
# Public API
func startAttack() -> void
func endAttack() -> void

# Properties to set
@export var animationName: String
@export var sprite: AnimatedSprite2D
@export var frameDataArray: Array[Dictionary]

# Enum
enum FrameType { EMPTY, SINGLE, MULTI }
```

## See Also

- [HitboxManager Documentation](hitbox_manager.md) - Signal handling and damage application
- [Main README](../README.md) - Full plugin setup guide