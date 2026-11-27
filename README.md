# OAR 智能体 / OAR agent

把任务交给本机装的外部智能体命令行（codex / claude / ollama / llm…），拿回它的输出。

Delegate a task to an external agent CLI installed on this machine (codex / claude / ollama / llm …) and return its output.

> Local-Harness（Godot 版）的独立插件。不随主程序发布，由主程序
> 「设置 → 插件管理」从 GitHub 下载并自动部署到 `user://plugins/oar/`。

## 安装

1. 打开 Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「OAR 智能体」点「安装」
3. 装好后在侧栏底部点同名按钮，里面是这个插件自己的设置页

手动安装：把本仓库下载解压到 `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\oar\`

## 工具

- `oar_agents` —— 列出本机检测到的外部智能体命令行。（只读）
- `oar_run` —— 用指定的外部智能体跑一个任务，返回它的标准输出。（高危）
  - `task`: string，任务内容
  - `agent`: string，可选，codex / claude / ollama / llm，默认自动选第一个可用的
  - `timeout`: int，可选，秒，默认 180
- `oar_custom` —— 用任意命令行跑任务：command 里用 {task} 占位，例如 `mytool.exe --ask "{task}"`。（高危）
  - `command`: string，命令行模板，含 {task}
  - `task`: string，任务内容
  - `timeout`: int，可选，秒，默认 180

## 命令

（没有命令）

## 设置项

- **默认超时（秒）**（`timeout`，默认 `180`）

## 权限

每个工具都能在插件设置页里单独开关。关掉之后它不会出现在模型的工具清单里，
就算模型硬要调用也会被主程序拒绝。协议里用 `level` 标了风险等级：

- `read` 只读：不会改动任何东西
- `act` 会产生操作：会读写文件、联网或占用设备
- `danger` 高危：会操作你的系统

## 怎么用

装好后直接在对话里提需求，例如：“列出本机检测到的外部智能体命令行。”

模型会输出一行 ```tool 协议块，宿主解析后执行，再把结果喂回模型。
也可以直接用斜杠命令，不经过模型。

## 许可

GPL-3.0（与主程序一致）。完整协议文本见仓库根目录的 [LICENSE](LICENSE)。

---

# OAR agent

Delegate a task to an external agent CLI installed on this machine (codex / claude / ollama / llm …) and return its output.

> An independent plugin for **Local-Harness (Godot edition)**. It is not bundled with the
> app; the app downloads it from this repository into `user://plugins/oar/` and hot-loads it.

## Install

1. Local-Harness → Settings → Plugins → Refresh
2. Find "OAR agent" and click Install
3. Open it from the button at the bottom of the sidebar for its own settings page

Manual: unzip this repo into `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\oar\`

## Tools

- `oar_agents` — 列出本机检测到的外部智能体命令行。 (read-only)
- `oar_run` — 用指定的外部智能体跑一个任务，返回它的标准输出。 (dangerous)
  - `task`: string，任务内容
  - `agent`: string，可选，codex / claude / ollama / llm，默认自动选第一个可用的
  - `timeout`: int，可选，秒，默认 180
- `oar_custom` — 用任意命令行跑任务：command 里用 {task} 占位，例如 `mytool.exe --ask "{task}"`。 (dangerous)
  - `command`: string，命令行模板，含 {task}
  - `task`: string，任务内容
  - `timeout`: int，可选，秒，默认 180

## Commands

(no commands)

## Settings

- **默认超时（秒）** (`timeout`, default `180`) 

## Permissions

Every tool can be toggled individually on the plugin settings page. A disabled tool is
removed from the model's tool list and rejected by the host even if the model still calls it.
`level` in the manifest marks the risk:

- `read` — no side effects
- `act` — reads/writes, network or devices
- `danger` — controls your system

## Usage

Just ask in the chat, e.g. “列出本机检测到的外部智能体命令行。”

The model emits a ```tool block, the host executes it and feeds the result back.
You can also use the slash commands above, which skip the model entirely.

## License

GPL-3.0 (same as the host app). Full text: [LICENSE](LICENSE).
