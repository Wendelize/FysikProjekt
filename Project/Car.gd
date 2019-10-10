extends KinematicBody2D

var wheelDist = 70
var angle = 15
var power = 800
var friction = -0.9
var drag = -0.001
var breaking = - 450
var speedReverse = 250

# new booiiis
var Cd = -0.31
var area = 1.94
var mass = 1393
var wheelRatio = 0.3186
var myStationary = -0.5
var myMove = -0.2
var grav = 9.82
var rpm = 1000
var we = 0
var Te = 220
var Tw = 0
var Ft
var Fd
var Ff
var Ftot

var acceleration = Vector2.ZERO
var oldacceleration = Vector2.ZERO
var dir = Vector2.RIGHT
var steerAngle

func _physics_process(delta):
	acceleration = Vector2.ZERO
	get_input()
	apply_friction()
	calculate_steering(delta)
	#print(acceleration * delta ," speed")
	dir += (acceleration * delta)
	dir = move_and_slide(dir)
	#print("Speed: ", dir.length()*3.6)
	print("speed2: ", (acceleration * delta*3.6).length())

func apply_friction():
	#Slow the car down (add friction- and drag force)
	#if dir.length() > 5:
	Fd = dir.normalized() * 1/2 * 1.22* area * Cd * dir.length()*dir.length() / mass
	if(dir.length() == 0):
		Ff = dir.normalized() *myStationary * grav  #dir * friction
	else:
		Ff = dir.normalized() *myMove * grav  #dir * friction
	acceleration +=  Fd + Ff
	print("motstånd: ",Ff.length())

func get_input():
	#Turn or not turning
	var turn = 0
	if Input.is_action_pressed("ui_right"):
		turn = 1
	if Input.is_action_pressed("ui_left"):
		turn = -1
	steerAngle = turn * deg2rad(angle)
	
	#Omega shit rpm
	#rpm = (dir.length() * 60 * 2.2 * 3.44) / (2 * PI * wheelRatio)
	if(rpm <= 1000):
		Te = 220
	elif(rpm < 4600):
		Te = 0.025 * rpm + 195
	else:
		if(rpm > 7600):
			rpm = 7600
		Te = -0.032 * rpm + 457.2
		
	we = (2*PI*rpm)/60
	
	Tw = Te * 2.2 * 3.44
	Ft = Tw / wheelRatio
	acceleration += (Ft/mass) * dir.normalized()
	print("drag: ",((Ft/mass) * dir.normalized()).length())
	#print("Ft : " , (Ft/mass) * dir.normalized())

	#Accalerations forward and for breaking
	if Input.is_action_pressed("ui_up"):
		rpm += 10
		#acceleration = transform.x * power


	if Input.is_action_pressed("ui_down"):
		rpm -= 10
		#acceleration = transform.x * breaking
	print(rpm , " RPM")
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