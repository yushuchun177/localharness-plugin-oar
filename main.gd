extends Node
## OAR 智能体插件 · local-harness
## 工具：oar_agents / oar_run / oar_custom
##
## 思路和 DSH 的 OAR 一样：本机模型是"主脑"，重活交给外部智能体 CLI：
##   codex exec "..."   claude -p "..."   ollama run <model> "..."   llm "..."
##
## 中文优先：命令通过 UTF-16 的 .ps1 交给 PowerShell，中文参数不会在 cmd 那层
## 被 GBK 解码弄坏；输出统一按 UTF-8 写文件再读。

const AGENTS := [
	{"id": "codex", "cmd": "codex", "args": ["exec", "{task}"], "label": "Codex CLI"},
	{"id": "claude", "cmd": "claude", "args": ["-p", "{task}"], "label": "Claude Code"},
	{"id": "ollama", "cmd": "ollama", "args": ["run", "{model}", "{task}"], "label": "Ollama"},
	{"id": "llm", "cmd": "llm", "args": ["{task}"], "label": "llm (simonw)"},
]



func _pref(key: String, def_value):
	# 直接读设置文件：在后台线程里也能用（不能碰场景树）
	var f := FileAccess.open("user://plugin_settings.json", FileAccess.READ)
	if f == null:
		return def_value
	var obj = JSON.parse_string(f.get_as_text())
	if not (obj is Dictionary):
		return def_value
	var vals: Dictionary = obj.get("values", {})
	var mine: Dictionary = vals.get("oar", {})
	return mine.get(key, def_value)

func run(tool: String, args: Dictionary) -> Dictionary:
	match tool:
		"oar_agents":
			return _agents()
		"oar_run":
			return _run(args)
		"oar_custom":
			return _custom(args)
	return {"ok": false, "output": "未知工具：%s" % tool}


func _which(cmd: String) -> String:
	var out: Array = []
	var code := OS.execute("where.exe", PackedStringArray([cmd]), out, true)
	if code == 0 and out.size() > 0:
		var first := str(out[0]).split("\n")[0].strip_edges()
		if first != "":
			return first
	return ""


func _agents() -> Dictionary:
	var found: PackedStringArray = []
	var missing: PackedStringArray = []
	for a in AGENTS:
		var p := _which(str(a["cmd"]))
		if p != "":
			found.append("- %s  →  %s" % [a["label"], p])
		else:
			missing.append(str(a["id"]))
	var text := ""
	if found.is_empty():
		text = "没有检测到外部智能体命令行。\n"
	else:
		text = "可用：\n" + "\n".join(found) + "\n"
	if not missing.is_empty():
		text += "未安装：" + ", ".join(missing) + "\n"
	text += "提示：任何命令行都能用 oar_custom 接进来（用 {task} 占位；中文建议用 {taskfile}）。"
	return {"ok": true, "output": text}


func _run(args: Dictionary) -> Dictionary:
	var task := str(args.get("task", "")).strip_edges()
	if task == "":
		return {"ok": false, "output": "task 不能为空"}
	var want := str(args.get("agent", "")).strip_edges().to_lower()
	var timeout: int = clampi(int(args.get("timeout", int(_pref("timeout", 180)))), 10, 900)
	var chosen: Dictionary = {}
	for a in AGENTS:
		if want != "" and str(a["id"]) != want:
			continue
		if _which(str(a["cmd"])) != "":
			chosen = a
			break
	if chosen.is_empty():
		return {"ok": false, "output": "没找到可用的外部智能体（先用 oar_agents 看看装了哪些）"}

	var argv: Array = []
	for piece in chosen["args"]:
		argv.append(str(piece).replace("{task}", task))
	if str(chosen["id"]) == "ollama":
		var models: Array = []
		OS.execute("ollama", PackedStringArray(["list"]), models, true)
		var first_model := ""
		for line in str(models[0]).split("\n"):
			var t := line.strip_edges()
			if t != "" and not t.begins_with("NAME"):
				first_model = t.split(" ")[0]
				break
		if first_model == "":
			return {"ok": false, "output": "ollama 里没有已下载的模型"}
		for i in argv.size():
			if argv[i] == "{model}":
				argv[i] = first_model

	var parts: PackedStringArray = []
	parts.append(_q(str(chosen["cmd"])))
	for a in argv:
		parts.append(_q(str(a)))
	return _execute(" ".join(parts), timeout, str(chosen["label"]))


func _custom(args: Dictionary) -> Dictionary:
	var command := str(args.get("command", "")).strip_edges()
	var task := str(args.get("task", "")).strip_edges()
	if command == "" or task == "":
		return {"ok": false, "output": "command 和 task 都要填"}
	var timeout: int = clampi(int(args.get("timeout", 180)), 10, 900)
	var task_file := OS.get_temp_dir().path_join("lh_oar_task_%d.txt" % randi())
	var tf := FileAccess.open(task_file, FileAccess.WRITE)
	if tf:
		tf.store_string(task)
		tf.close()
	var full := command.replace("{taskfile}", "\"" + task_file + "\"").replace("{task}", task)
	return _execute(full, timeout, "自定义命令")


## cmd 参数转义：含空格/引号才加引号，内部引号写成 ""
func _q(s: String) -> String:
	if s == "":
		return "\"\""
	if s.find(" ") == -1 and s.find("\"") == -1 and s.find("&") == -1:
		return s
	return "\"" + s.replace("\"", "\"\"") + "\""


func _execute(cmdline: String, timeout: int, label: String) -> Dictionary:
	var out_file := OS.get_temp_dir().path_join("lh_oar_%d.txt" % randi())
	var ps_file := OS.get_temp_dir().path_join("lh_oar_%d.ps1" % randi())
	var script := """
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$out = & cmd.exe /c "chcp 65001 >nul & CMDLINE" 2>&1 | Out-String
[System.IO.File]::WriteAllText('OUTFILE', $out, [System.Text.Encoding]::UTF8)
""".replace("CMDLINE", cmdline.replace("`", "``").replace("\"", "`\"")) \
	.replace("OUTFILE", out_file.replace("'", "''"))
	var f := FileAccess.open(ps_file, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "output": "写临时脚本失败"}
	f.store_buffer(PackedByteArray([0xFF, 0xFE]))
	f.store_buffer(script.to_utf16_buffer())
	f.close()

	var pid := OS.create_process("powershell.exe", PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", ps_file]), false)
	if pid <= 0:
		return {"ok": false, "output": "启动 %s 失败" % label}

	var t0 := Time.get_ticks_msec()
	while OS.is_process_running(pid):
		if (Time.get_ticks_msec() - t0) / 1000.0 > timeout:
			OS.kill(pid)
			DirAccess.remove_absolute(ps_file)
			return {"ok": false, "output": "%s 超时（%d 秒）已终止" % [label, timeout]}
		OS.delay_msec(200)

	var text := ""
	if FileAccess.file_exists(out_file):
		var rf := FileAccess.open(out_file, FileAccess.READ)
		if rf:
			text = rf.get_as_text()
		DirAccess.remove_absolute(out_file)
	DirAccess.remove_absolute(ps_file)
	if text.strip_edges() == "":
		return {"ok": true, "output": "%s 跑完了，但没有输出" % label}
	if text.length() > 8000:
		text = text.substr(0, 8000) + "\n…（已截断）"
	return {"ok": true, "output": "[%s]\n%s" % [label, text]}
