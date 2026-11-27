# OAR 智能体 / OAR agent

把任务交给本机装的外部智能体命令行（codex / claude / ollama / llm…），拿回它的输出。

Delegate a task to an external agent CLI installed on this machine (codex / claude / ollama / llm …) and return its output.

Local-Harness（Godot 版）的独立插件。**不随主程序发布**，由主程序「设置 → 插件管理」从 GitHub 下载并自动部署到 `user://plugins/oar/`。

## 工具

- `oar_agents` —— 列出本机检测到的外部智能体命令行。
- `oar_run` —— 用指定的外部智能体跑一个任务，返回它的标准输出。
  - `task`: string，任务内容
  - `agent`: string，可选，codex / claude / ollama / llm，默认自动选第一个可用的
  - `timeout`: int，可选，秒，默认 180
- `oar_custom` —— 用任意命令行跑任务：command 里用 {task} 占位，例如 `mytool.exe --ask "{task}"`。
  - `command`: string，命令行模板，含 {task}
  - `task`: string，任务内容
  - `timeout`: int，可选，秒，默认 180

## 安装

1. Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「OAR 智能体」点安装
3. 装完直接在对话里让模型调用（插件会出现在系统提示的工具清单里）

手动安装：把仓库解压到 `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\oar\`。

## 结构

```
manifest.json   清单：id / 版本 / 工具定义
main.gd         extends Node，实现 run(tool, args) -> {ok, output}
```

## 许可

GPL-3.0（与主程序一致）。
