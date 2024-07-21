extends CharacterBody2D


signal Shoot(bullet, Position, Rotation, Weapon)

@onready var Bullet = preload("res://Bullet/bullet.tscn")
@onready var Fusil = preload("res://Player/Weapons/weaponR1.png")
@onready var Pistol = preload("res://Player/Weapons/weaponR2.png")
@onready var Shotgun = preload("res://Player/Weapons/weaponR3.png")

@onready var AnimPlayer = $AnimatedSprite2D
@onready var Weapon = $Weapons/ControlWeapons
@onready var Gun = $Weapons/ControlWeapons/Gun
@onready var MarkerGunsMid = $Weapons/ControlWeapons/MarkerMid
@onready var MarkerGunsUp = $Weapons/ControlWeapons/MarkerUp
@onready var MarkerGunsDown = $Weapons/ControlWeapons/MarkerDown
@onready var HealtBar = $ProgressBarHealt
@onready var SoundPistol = $AudioPistol
@onready var SoundFusil = $AudioFusil
@onready var SoundShotgun = $AudioShotgun
@onready var SoundNoAmmo = $AudioNoAmmo
@onready var SoundShotgunReload = $AudioShotgunReload
@onready var LabelAmmo = $AmmoControl/LabelAmmo
@onready var FollowLeft = $AtFollow/FollowLeft
@onready var FollowRight = $AtFollow/FollowRight
@onready var FollowUpLeft = $AtFollow/FollowUpLeft
@onready var FollowUpRight = $AtFollow/FollowUpRight
@onready var FollowDownLeft = $AtFollow/FollowDownLeft
@onready var FollowDownRight = $AtFollow/FollowDownRight

var TimerMechaShoot = Timer.new()
var AttackSpeedPistol = 0.1 # Before 0.45
var AttackSpeedFusil = 0.05 # Before 0.4
var AttackSpeedShotgun = 0.1 # Before 1.5
var ScatteringShotgun = 6 # Before 5
var Speed = 200 # Before 200
var Live = 100
var EveryHitOfLive = 0
var BulletsPistol = -1 #Before 80 | -1 for Infinity ammo
var BulletsFusil = 230 #Before 230 | -1 for Infinity ammo
var BulletsShotgun = 50 #Before 50 | -1 for Infinity ammo
var Looking = ""
var GunOnHand = ""
var CanShoot = true


func _ready():
	Gun.texture = Pistol
	GunOnHand = "pistol"
	AnimPlayer.play("idle_down")
	HealtBar.max_value = Live
	HealtBar.value = Live
	TimerMechaShootSettings()


func TimerMechaShootSettings():
	TimerMechaShoot.wait_time = AttackSpeedPistol
	TimerMechaShoot.one_shot = true
	TimerMechaShoot.connect("timeout", self._on_TimerMechaShoot_timeout)
	add_child(TimerMechaShoot)


@warning_ignore("unused_parameter")
func _physics_process(delta):
	InputKeys()
	ChangeWeapons()
	WeaponsSystem()
	UpdateAmmoData(GunOnHand)
	move_and_slide()


func InputKeys():
	var Dir = Vector2()
	if Input.is_action_pressed("ui_up"):
		Dir.y = -1
		Looking = "up"
	if Input.is_action_pressed("ui_down"):
		Dir.y = 1
		Looking = "down"
	if Input.is_action_pressed("ui_left"):
		Dir.x = -1
		Looking = "left"
	if Input.is_action_pressed("ui_right"):
		Dir.x = 1
		Looking = "right"
	Dir = Dir.normalized()
	velocity = Dir * Speed
	AnimSettings()
	MechanicsShoot()


func AnimSettings():
	if velocity.x != 0 or velocity.y != 0:
		if velocity.y < 0 and velocity.x == 0:
			AnimPlayer.play("run_up")
		if velocity.y > 0 and velocity.x == 0:
			AnimPlayer.play("run_down")
		if velocity.x < 0:
			AnimPlayer.flip_h = false
			AnimPlayer.play("run_left_right")
		if velocity.x > 0:
			AnimPlayer.flip_h = true
			AnimPlayer.play("run_left_right")
	else:
		LookWhereAimGun()
#		match Looking:
#			"up":
##				AnimPlayer.play("idle_up")
#				AnimPlayer.play("idle_down")
#			"down":
#				AnimPlayer.play("idle_down")
#			"left":
#				AnimPlayer.flip_h = true
#				AnimPlayer.play("idle_lef_right")
#			"right":
#				AnimPlayer.flip_h = false
#				AnimPlayer.play("idle_lef_right")


func WeaponsSystem():
	Weapon.look_at(get_global_mouse_position())
	if get_global_mouse_position() > Weapon.global_position:
		Gun.position.y = -21
		Gun.flip_v = false
	else:
		Gun.position.y = 21
		Gun.flip_v = true


func ChangeWeapons():
	if Input.is_action_just_pressed("ui_1"):
		Gun.texture = Pistol
		GunOnHand = "pistol"
		TimerMechaShoot.wait_time = AttackSpeedPistol
	elif Input.is_action_just_pressed("ui_2"):
		Gun.texture = Fusil
		GunOnHand = "fusil"
		TimerMechaShoot.wait_time = AttackSpeedFusil
	elif Input.is_action_just_pressed("ui_3"):
		Gun.texture = Shotgun
		if GunOnHand != "shotgun":
			SoundShotgunReload.play()
		GunOnHand = "shotgun"
		TimerMechaShoot.wait_time = AttackSpeedShotgun


func MechanicsShoot():
	if !GlobalScript.HaveBeenPause:
		match GunOnHand:
			"pistol":
				if Input.is_action_just_pressed("ui_click"):
					if CanShoot and TheresAmmo(GunOnHand):
						emit_signal("Shoot", Bullet, MarkerGunsMid.global_position, Weapon.rotation_degrees, GunOnHand)
						SoundPistol.play()
						MakeLoadTheGuns()
			"fusil":
				if Input.is_action_pressed("ui_click"):
					if CanShoot and TheresAmmo(GunOnHand):
						emit_signal("Shoot", Bullet, MarkerGunsMid.global_position, Weapon.rotation_degrees, GunOnHand)
						SoundFusil.play()
						MakeLoadTheGuns()
			"shotgun":
				if Input.is_action_just_pressed("ui_click"):#is_action_just_pressed
					if CanShoot and TheresAmmo(GunOnHand):
						emit_signal("Shoot", Bullet, MarkerGunsUp.global_position, Weapon.rotation_degrees - ScatteringShotgun, GunOnHand)
						emit_signal("Shoot", Bullet, MarkerGunsMid.global_position, Weapon.rotation_degrees, GunOnHand)
						emit_signal("Shoot", Bullet, MarkerGunsDown.global_position, Weapon.rotation_degrees + ScatteringShotgun, GunOnHand)
						SoundShotgun.play()
						SoundShotgunReload.stop()
						MakeLoadTheGuns()


func MakeLoadTheGuns():
	CanShoot = false
	TimerMechaShoot.start()


func _on_TimerMechaShoot_timeout():
	CanShoot = true
	if GunOnHand == "shotgun":
		SoundShotgunReload.play()


func _input(event):
	if event.is_action_pressed("ui_l"):
		Hurt(50)


func Hurt(damage):
	AnimPlayer.modulate = Color(1, 0, 0, 1)
	HealtBar.value += -damage
	if HealtBar.value <= 0:
		Death()
	await get_tree().create_timer(0.3).timeout
	AnimPlayer.modulate = Color(1, 1, 1, 1)


func Death():
	call_deferred("queue_free")


func LookWhereAimGun():
	var DetectY = get_global_mouse_position().y - position.y
	var DetectX = get_global_mouse_position().x - position.x
	if DetectY >= 10 and DetectX <= 170: # Before DetectY >= 52
		AnimPlayer.play("idle_down")
	elif get_global_mouse_position().x > position.x:
		AnimPlayer.flip_h = false
		AnimPlayer.play("idle_lef_right")
	elif get_global_mouse_position().x < position.x:
		AnimPlayer.flip_h = true
		AnimPlayer.play("idle_lef_right")


func TheresAmmo(gun):
	match gun:
		"pistol":
			if BulletsPistol > 0:
				BulletsPistol += -1
				return true
			else:
				if BulletsPistol != -1:
					SoundNoAmmo.play()
					return false
				else:
					return true
		"fusil":
			if BulletsFusil > 0:
				BulletsFusil += -1
				return true
			else:
				if BulletsFusil != -1:
					SoundNoAmmo.play()
					return false
				else:
					return true
		"shotgun":
			if BulletsShotgun > 0:
				BulletsShotgun += -1
				return true
			else:
				if BulletsShotgun != -1:
					SoundNoAmmo.play()
					return false
				else:
					return true


func UpdateAmmoData(gun):
	match gun:
		"pistol":
			if BulletsPistol != -1:
				LabelAmmo.text = str(BulletsPistol)
			else:
				LabelAmmo.text = str("999")
		"fusil":
			if BulletsFusil != -1:
				LabelAmmo.text = str(BulletsFusil)
			else:
				LabelAmmo.text = str("999")
		"shotgun":
			if BulletsShotgun != -1:
				LabelAmmo.text = str(BulletsShotgun)
			else:
				LabelAmmo.text = str("999")

