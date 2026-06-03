# 📁 Simple Directory Logger

A lightweight desktop app built with **Godot 4** to monitor file system changes in real-time and optionally push notifications to a **Discord webhook**.

> Detects created, modified, and deleted files — with filtering, recursive scanning, and configurable Discord alerts.

---

## ✨ Features

- 🔍 **Real-time file monitoring** — detects created, modified, and deleted files
- 📂 **Recursive scanning** — optionally watch subdirectories automatically
- 🤖 **Discord webhook integration** — push notifications with rich embeds per event type
- 🔔 **Mention support** — `@here`, `@everyone`, role, or user mentions
- 🚫 **Exclude filters** — skip specific folders or file extensions
- ⏱️ **Item lifetime** — log entries auto-dismiss after a configurable duration
- 💾 **Persistent config** — settings saved and restored between sessions
- ▶️ **Autostart** — optionally start watching on launch

---

## 🖥️ Requirements

- [Godot 4.x](https://godotengine.org/)
- Internet connection (only required for Discord webhook)

---

## 🚀 Getting Started

1. Clone or download this repository
2. Open the project in Godot 4
3. Run the project (`F5`)

### Or use the exported binary (if provided)
Download the latest release from the [Releases](../../releases) page and run the executable directly — no Godot installation needed.

---

## ⚙️ Configuration

All settings are saved automatically to `user://sdl_user.cfg`.

### Scan Directory
Set the folder path you want to monitor. Use the folder picker button or type the path manually.

| Option | Description |
|--------|-------------|
| Scan Path | Root directory to watch |
| Recursive | Also watch all subdirectories |

### Exclude Filters
| Option | Description |
|--------|-------------|
| Exclude Folders | Skip specific directories from scanning |
| Exclude Extensions | Skip files by extension (e.g. `tmp`, `import`, `uid`) |

Default excluded extensions: `import`, `tmp`, `uid`, `godot`, `cfg`

### Discord Webhook
| Option | Description |
|--------|-------------|
| Webhook URL | Your Discord channel webhook URL |
| Mention Type | `None` / `@here` / `@everyone` / Role / User |
| Mention ID | Role or User ID (only required for Role/User mention type) |
| Push on Created | Send notification when files are created |
| Push on Deleted | Send notification when files are deleted |
| Push on Modified | Send notification when files are modified |

### Other Settings
| Option | Description |
|--------|-------------|
| Item Lifetime | How long (in seconds) a log entry stays visible before auto-removing |
| Autostart | Automatically begin watching when the app launches |

---

## 📋 Log View

The main panel shows a live log of all detected file events:

| Column | Description |
|--------|-------------|
| Date | Timestamp of the event |
| Type | `created` / `modified` / `deleted` / `info` |
| Name | File name |
| Path | Full file path |

Log entries are color-coded:
- 🟢 **Green** — created
- 🟡 **Orange** — modified
- 🔴 **Red** — deleted
- ⚪ **Gray** — info / system messages

---

## 📣 Discord Notification Example

When a file event occurs, a rich embed is sent to your configured webhook:

```
📁 Files Created
• myfile.png
• script.gd

Total: 2 file(s)
DirectoryWatcher • 2025-01-01 12:00:00
```

---

## 🗂️ Project Structure

```
├── scenes/
│   ├── main.tscn          # Main UI scene
│   └── ...
├── scripts/
│   ├── main.gd            # Main UI controller
│   ├── DirectoryWatcher.gd # Core file watcher node
│   └── ...
└── README.md
```

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

---

## 📄 License

This project is open source. See [LICENSE](LICENSE) for details.

---

## 🔗 Links

- [Report a Bug](../../issues)
- [Request a Feature](../../issues)
