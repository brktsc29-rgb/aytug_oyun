extends CanvasLayer

@onready var coin_label: Label = $MarginContainer/HBoxContainer/CoinLabel

func bind_player(player: Player) -> void:
	player.coin_collected.connect(_on_coin_collected)

func _on_coin_collected(total: int) -> void:
	coin_label.text = "Coins: %d" % total
