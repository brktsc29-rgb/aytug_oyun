extends Node

# ---------------------------------------------------------------------------
# ShopSystem — Skin shop and equip logic for Hetet
# Register as autoload singleton "ShopSystem" in Project Settings.
# Depends on GameManager (coin spending) and SaveSystem (persistence).
# ---------------------------------------------------------------------------

## Full skin catalogue.
## Structure per entry: { "name": String, "cost": int, "color": Color }
const SKINS: Dictionary = {
	"default": {
		"name": "Standart",
		"cost": 0,
		"color": Color(0.3, 0.7, 1.0),
	},
	"red": {
		"name": "Kırmızı Kahraman",
		"cost": 50,
		"color": Color(1.0, 0.3, 0.2),
	},
	"green": {
		"name": "Orman Bekçisi",
		"cost": 50,
		"color": Color(0.2, 0.85, 0.3),
	},
	"golden": {
		"name": "Altın Savaşçı",
		"cost": 200,
		"color": Color(1.0, 0.84, 0.0),
	},
	"rainbow": {
		"name": "Gökkuşağı Ustası",
		"cost": 500,
		"color": Color(1.0, 0.5, 1.0),
	},
	"dark": {
		"name": "Karanlık Gezgin",
		"cost": 150,
		"color": Color(0.2, 0.1, 0.4),
	},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

## Returns the display colour for skin_id, or Color.WHITE on unknown id.
func get_skin_color(skin_id: String) -> Color:
	if not SKINS.has(skin_id):
		push_warning("ShopSystem.get_skin_color: unknown skin '%s'" % skin_id)
		return Color.WHITE
	return SKINS[skin_id]["color"] as Color


## Returns the localised Turkish display name for skin_id.
func get_skin_name(skin_id: String) -> String:
	if not SKINS.has(skin_id):
		push_warning("ShopSystem.get_skin_name: unknown skin '%s'" % skin_id)
		return skin_id
	return SKINS[skin_id]["name"] as String


## Returns the coin cost for skin_id, or 0 on unknown id.
func get_skin_cost(skin_id: String) -> int:
	if not SKINS.has(skin_id):
		push_warning("ShopSystem.get_skin_cost: unknown skin '%s'" % skin_id)
		return 0
	return SKINS[skin_id]["cost"] as int


## Returns all registered skin ids in catalogue order.
func get_all_skin_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: String in SKINS.keys():
		ids.append(key)
	return ids


# ---------------------------------------------------------------------------
# Purchase
# ---------------------------------------------------------------------------

## Attempts to buy skin_id.
## Returns true if the player already owns it, or if the purchase succeeds.
## Returns false if the skin is unknown or the player cannot afford it.
func try_buy_skin(skin_id: String) -> bool:
	if not SKINS.has(skin_id):
		push_warning("ShopSystem.try_buy_skin: unknown skin '%s'" % skin_id)
		return false

	# No charge if already owned.
	if SaveSystem.is_skin_owned(skin_id):
		return true

	var cost: int = get_skin_cost(skin_id)
	if not GameManager.spend_coins(cost):
		return false  # Insufficient funds.

	SaveSystem.add_skin(skin_id)
	return true


# ---------------------------------------------------------------------------
# Equip
# ---------------------------------------------------------------------------

## Equips skin_id if owned, persists via SaveSystem, and updates the live player.
func equip_skin(skin_id: String) -> void:
	if not SKINS.has(skin_id):
		push_warning("ShopSystem.equip_skin: unknown skin '%s'" % skin_id)
		return

	if not SaveSystem.is_skin_owned(skin_id):
		push_warning("ShopSystem.equip_skin: skin not owned – '%s'" % skin_id)
		return

	SaveSystem.equip_skin(skin_id)

	# Hot-swap the skin on the active player if one is present in the tree.
	var player: CharacterBody2D = GameManager.active_player
	if player != null and player.is_inside_tree() and player.has_method("apply_skin"):
		player.apply_skin(skin_id)
