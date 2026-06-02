extends Node
class_name DirectoryWatcher

class WatchedDirectory:
	var new: PackedStringArray
	var modified: PackedStringArray
	var current: Dictionary#[String, int]
	var previous: Dictionary#[String, int]

enum MentionType {
	NONE,
	HERE,
	EVERYONE,
	ROLE,
	USER,
}

@export var scan_delay: float = 1
@export var scan_step := 5000
@export var discord_webhook_url: String = ""
@export var recursive: bool = true
@export var mention_type: MentionType = MentionType.NONE
@export var mention_id: String = ""

signal files_created(files: PackedStringArray)
signal files_modified(files: PackedStringArray)
signal files_deleted(files: PackedStringArray)
signal webhook_success(event: String, files: PackedStringArray)
signal webhook_failed(event: String, files: PackedStringArray, error_code: int, error_message: String)
signal scan_completed()

# ← NULL, bukan DirAccess.open(".")
var _directory: DirAccess = null
var _directory_list: Dictionary
var _directory_cache: Array[String]
var _to_delete: Array
var _current_directory_index: int
var _current_directory_name: String
var _remaining_steps: int
var _current_delay: float
var _excluded_paths: Array[String]
var _excluded_extensions: Array[String]
var _initial_scan_done := false

func _ready() -> void:
	_current_delay = scan_delay
	_remaining_steps = scan_step
	# ← hapus _directory.include_hidden, karena _directory sudah null

func add_scan_directory(directory: String) -> void:
	directory = ProjectSettings.globalize_path(directory)
	_add_directory_internal(directory)
	_directory_cache.assign(_directory_list.keys())

func _add_directory_internal(directory: String) -> void:
	if directory in _directory_list:
		return
	
	var watched := WatchedDirectory.new()
	
	# Index semua file sekarang juga
	var dir := DirAccess.open(directory)
	if dir == null:
		push_error("DirectoryWatcher: failed to open: %s" % directory)
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if not dir.current_is_dir():
			var full_file := directory.path_join(entry)
			if not _is_excluded(full_file):
				watched.previous[entry] = FileAccess.get_modified_time(full_file)
		entry = dir.get_next()
	
	_directory_list[directory] = watched
	
	# Recursive subdirs
	if not recursive:
		return
	dir.list_dir_begin()
	entry = dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir() and entry != "." and entry != "..":
			var subdir := directory.path_join(entry)
			if not _is_excluded(subdir):
				_add_directory_internal(subdir)
		entry = dir.get_next()

func remove_scan_directory(directory: String) -> void:
	directory = ProjectSettings.globalize_path(directory)
	_to_delete.append(directory)

func add_excludes(paths: Array[String]) -> void:
	for path in paths:
		path = ProjectSettings.globalize_path(path)
		if not path in _excluded_paths:
			_excluded_paths.append(path)

func remove_excludes(paths: Array[String]) -> void:
	for path in paths:
		path = ProjectSettings.globalize_path(path)
		_excluded_paths.erase(path)

func add_exclude_extensions(extensions: Array[String]) -> void:
	for ext in extensions:
		if not ext in _excluded_extensions:
			_excluded_extensions.append(ext)

func remove_exclude_extensions(extensions: Array[String]) -> void:
	for ext in extensions:
		_excluded_extensions.erase(ext)

func _is_excluded(full_path: String) -> bool:
	if full_path.get_extension() in _excluded_extensions:
		return true
	for excluded in _excluded_paths:
		if full_path == excluded or full_path.begins_with(excluded + "/"):
			return true
	return false

func _get_mention_string() -> String:
	match mention_type:
		MentionType.HERE:
			return "@here"
		MentionType.EVERYONE:
			return "@everyone"
		MentionType.ROLE:
			if mention_id.is_empty():
				push_warning("DirectoryWatcher: mention_type is ROLE but mention_id is empty.")
				return ""
			return "<@&%s>" % mention_id
		MentionType.USER:
			if mention_id.is_empty():
				push_warning("DirectoryWatcher: mention_type is USER but mention_id is empty.")
				return ""
			return "<@%s>" % mention_id
	return ""

func _build_discord_embed(event: String, files: PackedStringArray) -> Dictionary:
	var color: int
	var emoji: String
	match event:
		"created":
			color = 0x57F287
			emoji = "📁"
		"modified":
			color = 0xFEE75C
			emoji = "📝"
		"deleted":
			color = 0xED4245
			emoji = "🗑️"
		_:
			color = 0x5865F2
			emoji = "📄"

	var file_list := ""
	for f in files:
		file_list += "• `%s`\n" % f.get_file()

	var payload: Dictionary = {
		"embeds": [{
			"title": "%s Files %s" % [emoji, event.capitalize()],
			"description": file_list,
			"color": color,
			"footer": {
				"text": "DirectoryWatcher • %s" % Time.get_datetime_string_from_system()
			},
			"fields": [
				{
					"name": "Total",
					"value": str(files.size()) + " file(s)",
					"inline": true
				}
			]
		}]
	}

	var mention := _get_mention_string()
	if not mention.is_empty():
		payload["content"] = mention

	return payload

func _send_discord_webhook(event: String, files: PackedStringArray) -> void:
	if discord_webhook_url.is_empty():
		return
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
			_on_webhook_completed(result, response_code, body, event, files, http)
	)
	var payload := _build_discord_embed(event, files)
	var body := JSON.stringify(payload)
	var error := http.request(
		discord_webhook_url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body
	)
	if error != OK:
		webhook_failed.emit(event, files, error, "Failed to initiate request: %s" % error_string(error))
		http.queue_free()

func _on_webhook_completed(
	result: int,
	response_code: int,
	body: PackedByteArray,
	event: String,
	files: PackedStringArray,
	http: HTTPRequest
) -> void:
	http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_message: String
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_message = "Cannot connect to Discord. Check internet connection."
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_message = "Cannot resolve Discord hostname. Check DNS or internet connection."
			HTTPRequest.RESULT_CONNECTION_ERROR:
				error_message = "Connection error."
			HTTPRequest.RESULT_TIMEOUT:
				error_message = "Request timed out."
			HTTPRequest.RESULT_NO_RESPONSE:
				error_message = "No response from Discord."
			_:
				error_message = "Unknown error (result code %d)." % result
		webhook_failed.emit(event, files, result, error_message)
		return
	if response_code == 204:
		webhook_success.emit(event, files)
	elif response_code == 429:
		var json := JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var retry_after: float = json.data.get("retry_after", 1.0)
			webhook_failed.emit(event, files, response_code,
				"Rate limited by Discord. Retry after %.1f seconds." % retry_after)
		else:
			webhook_failed.emit(event, files, response_code, "Rate limited by Discord.")
	elif response_code >= 400:
		webhook_failed.emit(event, files, response_code,
			"Discord returned HTTP %d: %s" % [response_code, body.get_string_from_utf8()])

func _process(delta: float) -> void:
	
	if _directory_list.is_empty():
		return

	if _current_delay > 0:
		_current_delay -= delta
		return

	while _remaining_steps > 0:
		if _current_directory_name.is_empty():
			_current_directory_name = _directory_cache[_current_directory_index]
			_directory = DirAccess.open(_current_directory_name)
			if _directory == null:
				push_error("failed to open: %s" % _current_directory_name)
				_current_directory_index += 1
				_current_directory_name = ""
				if _current_directory_index >= _directory_list.size():
					_current_directory_index = 0
					break
				continue
			_directory.include_hidden = true
			_directory.list_dir_begin()
			#print("list_dir_begin done, dir: ", _current_directory_name)

		var directory: WatchedDirectory = _directory_list[_current_directory_name]
		var file := _directory.get_next()
		#print("get_next: '", file, "' is_dir: ", _directory.current_is_dir())

		if file.is_empty():
			var finished_dir := _current_directory_name  # ← simpan dulu
			_current_directory_index += 1
			_current_directory_name = ""
			_directory = null

			# ← hapus semua blok if/else first_scan, langsung emit saja
			
			if not directory.new.is_empty():
				files_created.emit(directory.new)
				_send_discord_webhook("created", directory.new)
				directory.new.clear()

			if not directory.modified.is_empty():
				files_modified.emit(directory.modified)
				_send_discord_webhook("modified", directory.modified)
				directory.modified.clear()

			var deleted: PackedStringArray
			for path in directory.previous:
				if not path in directory.current:
					deleted.append(finished_dir.path_join(path))

			if not deleted.is_empty():
				files_deleted.emit(deleted)
				_send_discord_webhook("deleted", deleted)

			directory.previous = directory.current
			directory.current = {}

			if _current_directory_index == _directory_list.size():
				if not _to_delete.is_empty():
					for dir in _to_delete:
						_directory_list.erase(dir)
					_to_delete.clear()
					_directory_cache.assign(_directory_list.keys())
				_current_directory_index = 0
				if not _initial_scan_done:
					_initial_scan_done = true
					scan_completed.emit()  # ← hanya emit sekali
				break
		else:
			if _directory.current_is_dir():
				continue

			var full_file := _current_directory_name.path_join(file)

			if _is_excluded(full_file):
				continue

			directory.current[file] = FileAccess.get_modified_time(full_file)

			if directory.previous.get(file, -1) == -1:
				directory.new.append(full_file)
			elif directory.current[file] > directory.previous[file]:
				directory.modified.append(full_file)

			_remaining_steps -= 1

	_remaining_steps = scan_step
	_current_delay = scan_delay
