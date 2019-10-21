extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$CanvasLayer/Velo.set_text("Speed: " + str(round($KinematicBody2D.currentVelocity * 3.6)))
	if($KinematicBody2D.currentOmega > 6000):
		$CanvasLayer/rpm.add_color_override("font_color", Color(1,0,0,1))
	else:
		$CanvasLayer/rpm.add_color_override("font_color", Color(1,1,1,1))
	if($KinematicBody2D.currentOmega < 1000):
		$CanvasLayer/rpm.set_text("RPM: " + str(round(1000)))
	else:
		$CanvasLayer/rpm.set_text("RPM: " + str(round($KinematicBody2D.currentOmega)))
	$CanvasLayer/gear.set_text("Gear: " + str(round($KinematicBody2D.currentGear+1)))
