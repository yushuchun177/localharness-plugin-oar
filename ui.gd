extends VBoxContainer
## OAR 智能体 —— 这个页面是插件自己提供的界面。
## 界面全部由插件自己拼，主程序只提供积木。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_child(PluginUI.section("本机装了哪些外部智能体"))
	add_child(PluginUI.action_row("重新检测", "看看 codex / claude / ollama / llm 有没有装", "检测",
		func(): return Plugins.invoke("oar_agents", {})))
	add_child(PluginUI.section("参数"))
	add_child(PluginUI.slider_row(plugin_id, "timeout", "最长等多久", 30, 600, 30, "秒", 180,
		"外部程序跑太久会被终止"))
	add_child(PluginUI.overview(plugin_id))
	add_child(PluginUI.permissions_section(plugin_id))
	add_child(PluginUI.doc_section(plugin_id))
