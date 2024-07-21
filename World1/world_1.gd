extends Node2D


@onready var Mushroom = preload("res://Mushroom/mushroom.tscn")
@onready var BirdMan = preload("res://BirdMan/bird_man.tscn")
@onready var Skeleton = preload("res://Skeleton/skeleton.tscn")

@onready var Player = $Player
@onready var BulletPlayerCont = $BulletPlayerContainer
@onready var Camera = $Camera2D
@onready var EnemyContainer = $GeneralEnemyContainer
@onready var RespawnContainer = $RespawnsContainer
@onready var MushroomContainer = $GeneralEnemyContainer/MushroomContainer
@onready var BirdManContainer = $GeneralEnemyContainer/BirdManContainer
@onready var SkeletonContainer = $GeneralEnemyContainer/SkeletonContainer

const NUM_OF_MUSHROOMS = 45 # Before 45
const NUM_OF_BIRDMAN = 20 # Before 30
const NUM_OF_SKELETON = 10 # Before 30 | 5

var ArrayCanRespawn = [0, true, true, true, true, true, true, true,
 true, true, true, true, true, true, true, true, true]
var PosForEnemy = Vector2()
var ContOfMush = 0
var ContOfBird = 0
var ContOfSkeleton = 0
var RoundOfMushrooms = 1 # Before 3
var RoundOfBirdMans = 1 # Before 3
var RoundOfSkeletons = 1 #Before 3
var NoLongerRounds = -1
var NumOfEnemyContainers = 0
var KeepSpawmingMush = true # Before true
var KeepSpawmingBird = true # Before true
var KeepSpawmingSkeleton = true # Before true
var KnowTheLastOne = true # Before true


func _ready():
	NumOfEnemyContainers = EnemyContainer.get_child_count()
	Player.connect("Shoot", self._Player_Shoot)


@warning_ignore("unused_parameter")
func _process(delta):
	if Player != null:
		Camera.position = Player.position
		UpdateLastRound()
		
		if KeepSpawmingMush:
			RespawnMushrooms()
		if KeepSpawmingBird:
			RespawnBirdMans()
		if KeepSpawmingSkeleton:
			RespawnSkeletons()
		
		if KnowTheLastOne:
			KnowWhoIsTheLastOne()


func _Player_Shoot(bullet, Position, Rotation, Weapon):
	var Bullet = bullet.instantiate()
	Bullet.position = Position
	Bullet.FireFrom = Weapon
	Bullet.rotation_degrees = Rotation + 90
	BulletPlayerCont.call_deferred("add_child", Bullet)


func RespawnMushrooms():
	if MushroomContainer.get_child_count() < NUM_OF_MUSHROOMS:
		PosForEnemy = Vector2()
		if SetPosOfEnemy():
			Mushroom = preload("res://Mushroom/mushroom.tscn").instantiate()
			Mushroom.PlayerToChase = Player
			Mushroom.position = PosForEnemy
			MushroomContainer.call_deferred("add_child", Mushroom)
			ContRoundsOfMushrooms()


func ContRoundsOfMushrooms():
	ContOfMush += 1
	if ContOfMush >= NUM_OF_MUSHROOMS:
		RoundOfMushrooms += -1
		ContOfMush = 0
	if RoundOfMushrooms <= 0:
		KeepSpawmingMush = false


func RespawnBirdMans():
	if BirdManContainer.get_child_count() < NUM_OF_BIRDMAN:
		PosForEnemy = Vector2()
		if SetPosOfEnemy():
			BirdMan = preload("res://BirdMan/bird_man.tscn").instantiate()
			BirdMan.PlayerToChase = Player
			BirdMan.position = PosForEnemy
			BirdManContainer.call_deferred("add_child", BirdMan)
			ContRoundsOfBirdMans()


func ContRoundsOfBirdMans():
	ContOfBird += 1
	if ContOfBird >= NUM_OF_BIRDMAN:
		RoundOfBirdMans += -1
		ContOfBird = 0
	if RoundOfBirdMans <= 0:
		KeepSpawmingBird = false


func RespawnSkeletons():
	if SkeletonContainer.get_child_count() < NUM_OF_SKELETON:
		PosForEnemy = Vector2()
		if SetPosOfEnemy():
			Skeleton = preload("res://Skeleton/skeleton.tscn").instantiate()
			Skeleton.PlayerToChase = Player
			Skeleton.position = PosForEnemy
			SkeletonContainer.call_deferred("add_child", Skeleton)
			ContRoundsOfSkeletons()


func ContRoundsOfSkeletons():
	ContOfSkeleton += 1
	if ContOfSkeleton >= NUM_OF_SKELETON:
		RoundOfSkeletons += -1
		ContOfSkeleton = 0
	if RoundOfSkeletons <= 0:
		KeepSpawmingSkeleton = false


func UpdateLastRound():
	if !KeepSpawmingMush and !KeepSpawmingBird and !KeepSpawmingSkeleton:
		NoLongerRounds = 0


func KnowWhoIsTheLastOne():
	var LastAlive = 0
	var EnemyContEmpty = 0
	var WhichLastOne = 0
	var ChildEnemyCont = null
	
	for i in range(NumOfEnemyContainers):
		ChildEnemyCont = EnemyContainer.get_child(i)
		
		if ChildEnemyCont.get_child_count() == 1:
			LastAlive += 1
			WhichLastOne = i
		if ChildEnemyCont.get_child_count() == 0:
			EnemyContEmpty += 1
	
	if LastAlive == 1 and EnemyContEmpty == NumOfEnemyContainers - 1 and NoLongerRounds == 0:
		EnemyContainer.get_child(WhichLastOne).get_child(0).LastOne()
		KnowTheLastOne = false
	else:
		KnowTheLastOne = true


func SetPosOfEnemy():
	randomize()
	var Respawn = randi_range(1, RespawnContainer.get_child_count())
	if ArrayCanRespawn[Respawn]:
		if !RespawnContainer.get_child(Respawn - 1).get_child(2).is_colliding():
			PosForEnemy = RespawnContainer.get_child(Respawn - 1).get_child(0).global_position
			return true
		else:
			return false
	else:
			return false


func _on_visible_notifi_respawn_1_screen_entered():
	ArrayCanRespawn[1] = false


func _on_visible_notifi_respawn_1_screen_exited():
	ArrayCanRespawn[1] = true


func _on_visible_notifi_respawn_2_screen_entered():
	ArrayCanRespawn[2] = false


func _on_visible_notifi_respawn_2_screen_exited():
	ArrayCanRespawn[2] = true


func _on_visible_notifi_respawn_3_screen_entered():
	ArrayCanRespawn[3] = false


func _on_visible_notifi_respawn_3_screen_exited():
	ArrayCanRespawn[3] = true


func _on_visible_notifi_respawn_4_screen_entered():
	ArrayCanRespawn[4] = false


func _on_visible_notifi_respawn_4_screen_exited():
	ArrayCanRespawn[4] = true


func _on_visible_notifi_respawn_5_screen_entered():
	ArrayCanRespawn[5] = false


func _on_visible_notifi_respawn_5_screen_exited():
	ArrayCanRespawn[5] = true


func _on_visible_notifi_respawn_6_screen_entered():
	ArrayCanRespawn[6] = false


func _on_visible_notifi_respawn_6_screen_exited():
	ArrayCanRespawn[6] = true


func _on_visible_notifi_respawn_7_screen_entered():
	ArrayCanRespawn[7] = false


func _on_visible_notifi_respawn_7_screen_exited():
	ArrayCanRespawn[7] = true


func _on_visible_notifi_respawn_8_screen_entered():
	ArrayCanRespawn[8] = false


func _on_visible_notifi_respawn_8_screen_exited():
	ArrayCanRespawn[8] = true


func _on_visible_notifi_respawn_9_screen_entered():
	ArrayCanRespawn[9] = false


func _on_visible_notifi_respawn_9_screen_exited():
	ArrayCanRespawn[9] = true


func _on_visible_notifi_respawn_10_screen_entered():
	ArrayCanRespawn[10] = false


func _on_visible_notifi_respawn_10_screen_exited():
	ArrayCanRespawn[10] = true


func _on_visible_notifi_respawn_11_screen_entered():
	ArrayCanRespawn[11] = false


func _on_visible_notifi_respawn_11_screen_exited():
	ArrayCanRespawn[11] = true


func _on_visible_notifi_respawn_12_screen_entered():
	ArrayCanRespawn[12] = false


func _on_visible_notifi_respawn_12_screen_exited():
	ArrayCanRespawn[12] = true


func _on_visible_notifi_respawn_13_screen_entered():
	ArrayCanRespawn[13] = false


func _on_visible_notifi_respawn_13_screen_exited():
	ArrayCanRespawn[13] = true


func _on_visible_notifi_respawn_14_screen_entered():
	ArrayCanRespawn[14] = false


func _on_visible_notifi_respawn_14_screen_exited():
	ArrayCanRespawn[14] = true


func _on_visible_notifi_respawn_15_screen_entered():
	ArrayCanRespawn[15] = false


func _on_visible_notifi_respawn_15_screen_exited():
	ArrayCanRespawn[15] = true


func _on_visible_notifi_respawn_16_screen_entered():
	ArrayCanRespawn[16] = false


func _on_visible_notifi_respawn_16_screen_exited():
	ArrayCanRespawn[16] = true


