extends KinematicBody2D

var wheelDist = 70
var angle = 15
var power = 800
var friction = -0.9
var drag = -0.001
var breaking = - 450
var speedReverse = 250

var acceleration = Vector2.ZERO
var dir = Vector2.ZERO
var steerAngle

func _physics_process(delta):
	acceleration = Vector2.ZERO
	get_input()
	apply_friction()
	calculate_steering(delta)
	dir += acceleration * delta
	dir = move_and_slide(dir)
	print(global_position)

func apply_friction():
	#Slow the car down (add friction- and drag force)
	if dir.length() < 5:
		dir = Vector2.ZERO
	var frictionForce = dir * friction
	var dragForce = dir * dir.length() * drag
	acceleration += frictionForce #+ dragForce

func get_input():
	#Turn or not turning
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn += 1
	if Input.is_action_pressed("ui_left"):
		turn -= 1
	steerAngle = turn * deg2rad(angle)
	
	#Accalerations forward and for breaking
	if Input.is_action_pressed("ui_up"):
		acceleration = transform.x * power
	if Input.is_action_pressed("ui_down"):
		acceleration = transform.x * breaking
		
	#Animations
	if dir.length() > 0:
		$AnimatedSprite.play("Forward")
	if dir.length() < 0:
		$AnimatedSprite.play("Backwards")
	if dir.length() == 0:
		$AnimatedSprite.stop()
	if turn > 0:
		$AnimatedSprite.play("Turn")
		$AnimatedSprite.flip_h = false
	if turn < 0:
		$AnimatedSprite.play("Turn")
		$AnimatedSprite.flip_h = true


func calculate_steering(delta):
	#Location of front- & rear wheel
	var rearWheel = position - transform.x * wheelDist / 2.0
	var frontWheel = position + transform.x * wheelDist / 2.0
	rearWheel += dir * delta
	frontWheel += dir.rotated(steerAngle) * delta
	
	#Calculating our new dir
	var newDir = (frontWheel - rearWheel).normalized()
	var d = newDir.dot(dir.normalized())
	if d > 0:
		dir = newDir * dir.length()
	if d < 0:
		dir = -newDir *min(dir.length(), speedReverse)
	rotation = newDir.angle()