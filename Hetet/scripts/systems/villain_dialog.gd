extends Node
class_name VillainDialog

static func show_intro(text: String) -> void:
	print("Villain: %s" % text)

static func taunt(level_name: String) -> void:
	print("Villain: %s? Let's see if your jumps are better than your luck!" % level_name)
