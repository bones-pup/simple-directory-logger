extends HBoxContainer
@onready var date: Label = $date
@onready var jenis: Label = $jenis
@onready var nama: Label = $nama
@onready var path_label: Label = $path
@onready var go_btn: Button = $go


func _on_go_pressed() -> void:
	go(path_label.text)
	pass # Replace with function body.


func _ready() -> void:
	#modulate.a = 0
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	#tw.tween_property(self,"modulate:a",1.0,0.5)
	tw.tween_property(self,"scale",Vector2(1.1,1.0),0.2)
	tw.tween_property(self,"scale",Vector2(1.0,1.0),0.2)

func go(target_path:String):
	if FileAccess.file_exists(target_path):
		OS.shell_show_in_file_manager(target_path)
	else:
		OS.alert("file telah dihapus")
