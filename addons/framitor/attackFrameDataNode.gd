
## Manages frame-based hitbox data for character attacks.
##
## Requires the HitboxManager singleton to handle collision detection
## and damage application. By default, HitboxManager should be accessible
## via [code]Global.hitboxManager[/code].

@tool
extends Area2D
class_name AttackFrameDataNode

@export var animationName: String = ""
@export var sprite: AnimatedSprite2D
@export var hitboxManager: HitboxManager = null
@export var frameDataArray: Array[Dictionary] = []

enum FrameType {
    EMPTY, 
    SINGLE, 
    MULTI  
}

var hitboxShapes: Array[CollisionShape2D] = []
var isAttackActive: bool = false


func _ready():
	monitoring = false
	monitorable = false

	if animationName.is_empty():
		push_error("animationName must be set")
	
	if not sprite:
		push_error("sprite must be set")

	_cacheHitboxes()


func startAttack():
	isAttackActive = true
	Global.hitboxManager.alreadyHit.clear()
	monitoring = false


func endAttack():
	isAttackActive = false
	_disableAllHitboxes()
	monitoring = false


func _cacheHitboxes():
	hitboxShapes.clear()
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
			hitboxShapes.append(child)
	
	hitboxShapes.sort_custom(func(a, b): return a.name < b.name)


func _setupSpriteConnection():
	if not sprite:
		push_warning("_setupSpriteConnection: Could not find AnimatedSprite2D for " + name)
		return

	if sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		sprite.frame_changed.disconnect(_on_sprite_frame_changed)
	sprite.frame_changed.connect(_on_sprite_frame_changed)


func _disableAllHitboxes():
	for hitbox in hitboxShapes:
		hitbox.disabled = true


func _activateSingleHitbox(frameData: Dictionary):
	var hitboxIndex = frameData.hitboxIndex
	if hitboxIndex >= hitboxShapes.size():
		return

	var hitbox = hitboxShapes[hitboxIndex]
	if hitbox:
		hitbox.disabled = false
	else:
		push_warning("_activateSingleHitbox: Could not load for hitbox")
		return

	monitoring = true
	if not hitboxManager:
		hitboxManager = Global.hitboxManager

	hitboxManager.loadFrameData(frameData, self)


func _on_sprite_frame_changed():
	if not isAttackActive:
		return
	
	if sprite:
		if sprite.animation != animationName:
			return

		var currentSpriteFrame = sprite.frame
		_activateFrame(currentSpriteFrame)
	else:
		push_warning("_on_sprite_frame_changed: Could not find AnimatedSprite2D for " + name)
		return


func _activateFrame(frameIndex: int):
	_disableAllHitboxes()

	if frameIndex >= frameDataArray.size():
		monitoring = false
		return

	var frameData = frameDataArray[frameIndex]

	match frameData.get("type", "empty"):
		FrameType.SINGLE:
			_activateSingleHitbox(frameData)
		FrameType.MULTI:
			pass #NOT YET IMPLEMENTED
		FrameType.EMPTY:
			monitoring = false

	


# ============ TOOL SECTION ==============
func _get_tool_buttons() -> Array:
	return [
		{
			call=_create_single_frame,
			text="➕ Add Single Frame",
			tint=Color(0.3, 0.8, 1.0),
			hint="Add a frame with one hitbox"
		},
		{
			call="_create_multi_frame_2",
			text="➕ Add Multi-Frame (2)",
			tint=Color(0.5, 0.7, 1.0),
			hint="Add a frame with 2 hitboxes"
		},
		{
			call="_create_multi_frame_3",
			text="➕ Add Multi-Frame (3)",
			tint=Color(0.7, 0.6, 1.0),
			hint="Add a frame with 3 hitboxes"
		},
		{
			call=_create_empty_frame,
			text="⚪ Add Empty Frame",
			tint=Color(0.7, 0.7, 0.7),
			hint="Add a frame with no hitbox (wind-up/recovery)"
		},
		{
			call=_clear_all_frames,
			text="🗑️ Clear All Frames",
			tint=Color(1.0, 0.3, 0.3), 
			hint="Delete all frame data",
		},
		{
			call=_log_frame_data_array,
			text="Log Frame Data Array",
			tint=Color(1.0, 0.2, 0.5),
		}
	]


@export var NewFrameData: Dictionary = {
	"type": FrameType.SINGLE,
	"damage": 0.0,
	"knockback": Vector2(0, 0),
	"screenShake": 0.0,
	"hitStop": 0.00,
	"status": {}
}


func _create_single_frame():
	if not Engine.is_editor_hint():
		return
	
	print("\nCreating single frame...")
	
	var hitbox = CollisionShape2D.new()
	hitbox.name = "Frame" + str((get_child_count()))
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 160)
	hitbox.shape = shape
	hitbox.disabled = true
	hitbox.position = Vector2(10, 0)
	hitbox.scale = Vector2(1, 0.1)
	
	add_child(hitbox)
	hitbox.owner = get_tree().edited_scene_root
	
	var frameData = NewFrameData.duplicate(true)

	frameDataArray.append(frameData)
	frameData["hitboxIndex"] = get_child_count() - 1
	
	_cacheHitboxes()
	
	notify_property_list_changed()


func _create_empty_frame():
	print("\nCreating an empty frame...")
	frameDataArray.append({"type": "empty"})



func _clear_all_frames():
	if not frameDataArray:
		print("FRAME DATA ARRAY IS ALREADY EMPTY")
		return

	frameDataArray.clear()
	for n in get_children():
		remove_child(n)
	print("\nData array cleared")


func _log_frame_data_array():
	if not frameDataArray:
		print("\nFRAME DATA ARRAY IS EMPTY")
		return

	for data in frameDataArray:
		print(data, "\n")