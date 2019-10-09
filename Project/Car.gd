extends KinematicBody2D

var wheelDist = 50
var angle = 15
var speed = 500
var dir = Vector2.ZERO
var steerAngle
var currentSpeed = 0

func _physics_process(delta):
	get_input(delta)
	calculate_steering(delta)
	dir = move_and_slide(dir)

func get_input(delta):
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn += 1
	if Input.is_action_pressed("ui_left"):
		turn -= 1
	steerAngle = turn * deg2rad(angle)
	
	if Input.is_action_pressed("ui_up"):
		currentSpeed += speed * delta
	else:
		#sjukmotorbroms
		if(currentSpeed > 0):
			currentSpeed -= speed * delta / 2
		if(currentSpeed < 0):
			currentSpeed += speed * delta / 2
	if Input.is_action_pressed("ui_down"):
		currentSpeed -= (speed/2) * delta * 2
		#dir = transform.x * -speed  #byt till bromskrafter
		
func calculate_steering(delta):
	var rearWheel = position - transform.x * wheelDist / 2.0
	var frontWheel = position + transform.x * wheelDist / 2.0
	rearWheel += dir * delta
	frontWheel += dir.rotated(steerAngle) * delta
	var newDir = (frontWheel - rearWheel).normalized()
	dir = newDir * currentSpeed #dir.length()
	rotation = newDir.angle()