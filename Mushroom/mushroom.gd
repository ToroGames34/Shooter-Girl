extends CharacterBody2D


enum {IDLE, RUN, ATTACK, DEATH}

@onready var Nav = $NavigationAgent2D
@onready var Anim = $AnimatedSprite2D
@onready var AreaAttack = $AreaAttack/CollisionShape2D
@onready var RayAttack = $AreaAttack/RayCast2D
@onready var RayAttack2 = $AreaAttack/RayCast2D2
@onready var RayAttack3 = $AreaAttack/RayCast2D3
@onready var RayAttack4 = $AreaAttack/RayCast2D4
@onready var HealthBar = $HealthBar
@onready var CollisionShape = $CollisionShape2D
@onready var SoundLast = $AudioLastOne

var TimerAttack = Timer.new()
var PlayerToChase = null
var Speed = 145 # Before 120
var Acceleration = 7
var AttackSpeed = 1.5
var StartChasingAt = 1#Sec
var Live = 100
var DamageToPlayer = 10
var TimeForDeath = 0.45
var BoostSpeedLastOne = 30
var BoostDamageLastOne = 20
var BonusLiveLast = 2#the same amount of live multiplicate by 'BonusLiveLast'
var CurrentAnim
var NewAnim
var State
var StartChasing = false
var OneTimeAttack = true
var Death = false
var OneTimeChaseSelfPos = true
var OneTimeLastOne = true
var CanBeHurt = true
var OneTimeFirstStrike = true
var Running = false


func _ready():
	Anim_Play(IDLE)
	HealthBar.max_value = Live
	HealthBar.value = Live
	RlyStartChasing()
	TimerAttackSettings()


func TimerAttackSettings():
	TimerAttack.wait_time = AttackSpeed
	TimerAttack.connect("timeout", self._on_TimerAttack_timeout)
	add_child(TimerAttack)


@warning_ignore("unused_parameter")
func _process(delta):
	UpdateAnim()


func _physics_process(_delta: float):
	var direction = Vector2()
	
	if !Death:
#		if position.x < Player.position.x:
#			SetTargetToChase(Player.FollowLeft.global_position)
#		else:
#			SetTargetToChase(Player.FollowRight.global_position)
		
		if PlayerToChase != null and !RayAttack.is_colliding() and !RayAttack2.is_colliding() and !RayAttack3.is_colliding() and !RayAttack4.is_colliding():
			if position.x < PlayerToChase.position.x and position.y < PlayerToChase.position.y:
				SetTargetToChase(PlayerToChase.FollowUpLeft.global_position)
			elif position.x < PlayerToChase.position.x and position.y > PlayerToChase.position.y:
				SetTargetToChase(PlayerToChase.FollowDownLeft.global_position)
			elif position.x > PlayerToChase.position.x and position.y < PlayerToChase.position.y:
				SetTargetToChase(PlayerToChase.FollowUpRight.global_position)
			elif position.x > PlayerToChase.position.x and position.y > PlayerToChase.position.y:
				SetTargetToChase(PlayerToChase.FollowDownRight.global_position)
			
		if Nav.distance_to_target() > 20 and !RayAttack.is_colliding() and !RayAttack2.is_colliding() and !RayAttack3.is_colliding() and !RayAttack4.is_colliding():
			if StartChasing:
				OneTimeAttack = true
				OneTimeFirstStrike = true
				Running = true
				TimerAttack.stop()
				AreaAttack.set_deferred("disabled", true)
				Anim_Play(RUN)
				direction = Nav.get_next_path_position() - global_position
				direction = direction.normalized()
				velocity = velocity.lerp(direction * Speed, Acceleration * _delta)
				move_and_slide()
		else:
			Running = false
			if RayAttack.is_colliding() or RayAttack2.is_colliding() or RayAttack3.is_colliding() or RayAttack4.is_colliding():
				if OneTimeAttack:
					OneTimeAttack = false
					FirstStrike()
					if OneTimeLastOne:
						Anim_Play(IDLE)
					TimerAttack.start()
			
		if PlayerToChase != null:
			if position.x < PlayerToChase.position.x:
				Anim.flip_h = false
				AreaAttack.position.x = 30.5
#				RayAttack.target_position.x = 30
			else:
				Anim.flip_h = true
				AreaAttack.position.x = -30.5
#				RayAttack.target_position.x = -30
		
		ExactlyFrameForAttack()
		IsPlayerDeath()


func Anim_Play(state):
	State = state
	match State:
		IDLE:
			NewAnim = "idle"
		RUN:
			NewAnim = "run"
		ATTACK:
			NewAnim = "attack"
		DEATH:
			NewAnim = "death"


func UpdateAnim():
	if NewAnim != CurrentAnim:
		Anim.play(NewAnim)
		CurrentAnim = NewAnim


func SetTargetToChase(t: Vector2):
	Nav.target_position = t


func IsPlayerDeath():
	if PlayerToChase == null:
		if OneTimeChaseSelfPos:
			OneTimeChaseSelfPos = false
			AreaAttack.set_deferred("disabled", true)
			TimerAttack.stop()
			SetTargetToChase(position)
			Anim_Play(IDLE)
	else:
		OneTimeChaseSelfPos = true


func RlyStartChasing():
	await get_tree().create_timer(StartChasingAt).timeout
	StartChasing = true


func FirstStrike():
	if OneTimeFirstStrike:
		OneTimeFirstStrike = false
		await get_tree().create_timer(0.15).timeout
		if !Death:
			Anim_Play(ATTACK)


func _on_TimerAttack_timeout():
	if !Death and OneTimeChaseSelfPos:
		Anim_Play(ATTACK)


func _on_animated_sprite_2d_animation_finished():
	if Anim.animation == "attack":
		AreaAttack.set_deferred("disabled", true)
		Anim_Play(IDLE)
	if Anim.animation == "death":
		await get_tree().create_timer(TimeForDeath).timeout
		call_deferred("queue_free")


func ExactlyFrameForAttack():
	if !OneTimeAttack and Anim.animation == "attack":# and RayAttack.is_colliding()
		if Anim.frame == 6:
			AreaAttack.set_deferred("disabled", false)


func _on_area_attack_body_entered(body):
	if body.is_in_group("player"):
		body.Hurt(DamageToPlayer)


func Hurt(damage):
	Anim.modulate = Color(1, 0, 0, 1)
	if CanBeHurt:
		HealthBar.value += -damage
	if HealthBar.value <= 0:
		DeathF()
	await get_tree().create_timer(0.3).timeout
	Anim.modulate = Color(1, 1, 1, 1)


func DeathF():
	CollisionShape.set_deferred("disabled", true)
	Death = true
	TimerAttack.stop()
	Anim_Play(DEATH)


func LastOne():
	if OneTimeLastOne:
		OneTimeLastOne = false
		CanBeHurt = false
		HealthBar.max_value = HealthBar.max_value * BonusLiveLast
		HealthBar.value = HealthBar.value * BonusLiveLast
		
		Speed += 50
		DamageToPlayer += 20
		SoundLast.play()
		ChangeColor()


func ChangeColor():
	var tween = create_tween()
	
	if !Death:
		var InterChangeColor = 0.5
		var FinistCol = InterChangeColor * 2
		
		tween.tween_property(Anim, "modulate", Color(1, 0, 1, 1), InterChangeColor
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		tween.tween_property(Anim, "modulate", Color(1, 1, 1, 1), InterChangeColor
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		await create_tween().tween_interval(FinistCol).finished
		if !Death:
			ChangeColor()
	else:
		tween.stop()
		Anim.modulate = Color(1, 1, 1, 1)


func _on_audio_last_one_finished():
	CanBeHurt = true
