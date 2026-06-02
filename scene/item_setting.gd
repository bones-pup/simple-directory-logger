extends HBoxContainer
# item setting, ini untuk list exclude

signal delete_requested(item: HBoxContainer)
signal edit_requested(item: HBoxContainer, old_value: String)

@onready var name_item: Label = $name_item

func _on_edit_pressed() -> void:
	edit_requested.emit(self, name_item.text)

func _on_delete_pressed() -> void:
	delete_requested.emit(self)
