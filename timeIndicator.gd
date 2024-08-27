extends Label

var environment: WorldEnvironment

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	environment = get_node("../../../../WorldEnvironment")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
