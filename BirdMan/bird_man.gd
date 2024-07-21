extends CharacterBody2D


enum {IDLE, RUN, ATTACK, DEATH}

@onready var Nav = $NavigationAgent2D
@onready var Anim = $AnimatedSprite2D
@onready var AreaAttack = $AreaAttack/CollisionShape2D
@onready var RayAttack1 = $AreaAttack/RayCastAttack1
@onready var RayAttack2 = $AreaAttack/RayCastAttack2
@onready var RayAttack3 = $AreaAttack/RayCastAttack3
@onready var HealthBar = $HealthBar
@onready var CollisionShape = $CollisionShape2D
@onready var SoundLast = $AudioLastOne

var TimerAttack = Timer.new()
var PlayerToChase = null
var Speed = 140 #Before 120
var Acceleration = 7
var AttackSpeed = 1.3
var StartChasingAt = 1#Sec
var Live = 160
var DamageToPlayer = 20
var TimeForDeath = 0.45
var BoostSpeedLastOne = 75
var BoostDamageLastOne = 15
var BonusLiveLast = 1.5 #the same amount of live multiplicate by 'BonusLiveLast' never below to 1.0
var CurrentAnim
var NewAnim
var State
var StartChasing = false
var OneTimeAttack = true
var Death = false
var OneTimeChaseSelfPos = true
var OneTimeLastOne = true
var CanBeHurt = true


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
		
		if PlayerToChase != null:
			if position.x < PlayerToChase.position.x:
				SetTargetToChase(PlayerToChase.FollowLeft.global_position)
			else:
				SetTargetToChase(PlayerToChase.FollowRight.global_position)
		
		if Nav.distance_to_target() > 30 and !RayAttack1.is_colliding() and !RayAttack2.is_colliding() and !RayAttack3.is_colliding():
			if StartChasing:
				OneTimeAttack = true
				TimerAttack.stop()
				AreaAttack.set_deferred("disabled", true)
				Anim_Play(RUN)
				direction = Nav.get_next_path_position() - global_position
				direction = direction.normalized()
				velocity = velocity.lerp(direction * Speed, Acceleration * _delta)
				move_and_slide()
		else:
			if RayAttack1.is_colliding() or RayAttack2.is_colliding() or RayAttack3.is_colliding():
				if OneTimeAttack:
					OneTimeAttack = false
					if OneTimeLastOne:
						Anim_Play(IDLE)
					FirstStrike()
					TimerAttack.start()
					
		if PlayerToChase != null:
			if position.x < PlayerToChase.position.x:
				Anim.offset.x = 0
				Anim.flip_h = false
				AreaAttack.position.x = 45.125
				RayAttack1.target_position.x = 52
				RayAttack2.target_position.x = 52
				RayAttack3.target_position.x = 52
			else:
				Anim.offset.x = -31
				Anim.flip_h = true
				AreaAttack.position.x = -45.125
				RayAttack1.target_position.x = -52
				RayAttack2.target_position.x = -52
				RayAttack3.target_position.x = -52
		
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


func _on_TimerAttack_timeout():
	if !Death and OneTimeChaseSelfPos:
		Anim_Play(ATTACK)


func FirstStrike():
	await get_tree().create_timer(0.5).timeout
	if !Death:
		Anim_Play(ATTACK)


func _on_animated_sprite_2d_animation_finished():
	if Anim.animation == "attack":
		AreaAttack.set_deferred("disabled", true)
		Anim_Play(IDLE)
	if Anim.animation == "death":
		await get_tree().create_timer(TimeForDeath).timeout
		call_deferred("queue_free")


func ExactlyFrameForAttack():
	if !OneTimeAttack and Anim.animation == "attack":# and (RayAttack1.is_colliding() or RayAttack2.is_colliding() or RayAttack3.is_colliding())
		if Anim.frame == 1:
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
		
		Speed += BoostSpeedLastOne
		DamageToPlayer += BoostDamageLastOne
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


func MovementSystemBiggerEnemys():
	if position.y < PlayerToChase.global_position.y:
		if position.y > PlayerToChase.global_position.y - 200:
			print("Mid Up Above")
		else:
			print("Away Up Above")

	if position.y > PlayerToChase.global_position.y:
		if position.y < PlayerToChase.global_position.y + 200:
			print("Mid Up Under")
		else:
			print("Away Up Under")

