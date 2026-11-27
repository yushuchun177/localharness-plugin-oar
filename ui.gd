extends VBoxContainer
## 本插件的设置界面 —— 由插件自己提供，主程序只负责挂载。
## 想改这个插件在这里长什么样、有哪些开关，改这个文件即可。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(PluginUI.title("OAR 智能体"))
	add_child(PluginUI.hint("把任务交给本机装的外部智能体命令行（codex / claude / ollama…）。"))
	add_child(PluginUI.section("行为"))
	add_child(PluginUI.int_field(plugin_id, "timeout", "默认超时（秒）", 180, ""))
	add_child(PluginUI.section("能力开关"))
	add_child(PluginUI.hint("每一项都能单独关掉；关掉后模型看不到这个能力，也调用不了。"))
	for t in Plugins.tools_of(plugin_id):
		var tname := str(t.get("name", ""))
		var human := tname
		var desc := str(t.get("description", ""))
		if tname == "oar_agents":
			human = "检测已装智能体"
			desc = "只读"
		if tname == "oar_run":
			human = "调用外部智能体"
			desc = "会启动别的程序"
		if tname == "oar_custom":
			human = "执行自定义命令"
			desc = "完全自定义，风险最高"
		add_child(PluginUI.perm_row(tname, human, desc, bool(t.get("dangerous", false))))
	add_child(PluginUI.readme_box(plugin_id))
