extends Player

func _ready() -> void:
	if not character or not character.dna:
		return
	toon.construct_toon(character.dna)
	animator = toon.body.animator
	laff_meter.set_meter(character.dna)
	laff_meter.hide()
	gui.hide()
	camera.current = false
	set_animation("neutral")

func lose() -> void:
	state = PlayerState.SAD
	set_animation("lose")
	await Task.delay(1.0)
	state = PlayerState.STOPPED
	set_animation("neutral")
