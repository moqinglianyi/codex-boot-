# macOS 原生启动器

macOS 版使用 AppKit 与 AVFoundation 播放仓库中已有的龙娘动画和原音轨，同时启动或复用 Codex。视频结尾淡出后将焦点交给真实客户端。

## 环境与构建

- Intel Mac（x86_64）或 Apple Silicon Mac（arm64），macOS 13 或更新版本。
- 构建需要 Xcode 或 Xcode Command Line Tools；运行不需要额外运行时。
- 使用启动器需要已安装应用标识为 `com.openai.codex` 的客户端。按标识查找，不依赖应用显示名或固定安装路径。

在仓库根目录运行：

```sh
./scripts/build-macos-standalone.sh
```

默认按构建机器的架构编译。也可通过 `MACOS_ARCH` 明确指定目标；仅支持 `x86_64` 和 `arm64`：

```sh
# Intel Mac 版本
MACOS_ARCH=x86_64 ./scripts/build-macos-standalone.sh
# Apple Silicon 版本
MACOS_ARCH=arm64 ./scripts/build-macos-standalone.sh
```

输出为 `build/macos/Dragon Codex Boot.app`。两种架构共用此 App 路径，连续构建会覆盖上一次的 App；打包后的 ZIP 按架构分别保留。将它复制到个人 `~/Applications` 或“应用程序”目录，双击即可使用，也可拖入 Dock 作为独立启动入口。

打包并生成 SHA-256：

```sh
./scripts/package-macos-standalone.sh
```

指定 Intel 版本打包（`package-macos.sh` 也是同一打包入口）：

```sh
MACOS_ARCH=x86_64 ./scripts/package-macos.sh
```

Intel 输出为 `dist/DragonCodexBoot-版本-macos-x86_64-with-video.zip`，Apple Silicon 输出为 `dist/DragonCodexBoot-版本-macos-arm64-with-video.zip`，各自附带对应 `.sha256`。包中保留原仓库许可和媒体说明。构建使用本地 ad-hoc 签名，未作 Developer ID 签名或 Apple 公证；在其他电脑上分发仍可能需要系统的正常首次打开确认。本脚本不修改 Gatekeeper 设置。

## 在 GitHub Actions 编译和下载

1. 将源码推送到 GitHub，确保一并上传 `.github/workflows/macos.yml`、`scripts/`、`src/macos/`、`macos/`、`tests/` 和仓库随附的 `media/startup.mp4`；不要只上传 Swift 文件。
2. 打开仓库 **Actions → macOS build**。推送会自动触发，也可用 **Run workflow** 手动启动。
3. 工作流在 `macos-15-intel` 原生编译、测试 x86_64，在 `macos-15` 原生编译、测试 arm64；两者的最低运行版本均为 macOS 13。
4. 构建成功后，在本次运行的 **Artifacts** 下载 **DragonCodexBoot-macos-x86_64**（Intel）或 **DragonCodexBoot-macos-arm64**（Apple Silicon）。artifact 内含带视频的轻量版 App ZIP 和 SHA-256 校验文件。
5. 下载 artifact 后先解压外层压缩包，再解压其中 `DragonCodexBoot-版本-macos-x86_64-with-video.zip`（或 arm64 版本），将得到的 `Dragon Codex Boot.app` 放入“应用程序”目录使用。

工作流保留产物 30 天，不会自动创建 GitHub Release；需要长期分发时，可把 ZIP 和 `.sha256` 上传到 Release。使用 GitHub Actions 时无需在本机安装编译工具，也不需要 API key 或 Apple 签名密钥；GitHub runner 提供编译工具链。这里的运行要求仅针对启动器，已安装的 Codex 客户端也必须能在该 Mac 上正常运行。

## 使用与行为

- 窗口在鼠标所在屏幕居中显示，保持 16:9，最大 1280 × 720 点，并适应屏幕可用空间。
- 后台打开 Codex；若已经运行，复用现有实例。
- 按 `Esc`、`Command+.` 或点击右上角“跳过”可立即请求交接。`Command+Q` 退出启动器。
- 默认保留原音轨。客户端启动未完成时，在约 11.3 秒处暂停等待；启动完成后继续播放，在 12.7 秒处开始 0.95 秒淡出。
- 媒体失败会尝试跳过；媒体卡住和客户端启动都有有限等待，避免永久遮挡。
- 最近一次诊断日志位于系统临时目录下的 `local.dragoncodexboot.macos/last-run.log`，只记录启动、播放及交接状态，不记录聊天内容或屏幕画面。
- 删除启动器即可卸载；若自行固定到 Dock，再移除该入口。

## 与 Windows 版的差异

macOS 版使用淡出交接，没有移植 Windows DWM 实时窗口嵌入、客户端窗口重排、全盘快捷方式替换或 `launcher.json` 配置读取。当前时间点和音量匹配仓库自带视频；若更换视频，需调整 `src/macos/main.swift` 中的时间点并重新构建。

`NSWorkspace` 的启动回调只能说明应用已启动，不保证客户端窗口或所有后台内容加载完成。启动器不请求辅助功能或屏幕录制权限，不修改官方应用包、Dock 设置或登录项。

## 验证

```sh
./scripts/test-macos-standalone.sh
```

该脚本默认检查本机架构，也可用 `MACOS_ARCH=x86_64 ./scripts/test-macos-standalone.sh` 明确检查 Intel 版本。它检查编译、目标架构、最低系统版本、应用元数据、素材一致性、许可文件、签名，以及 ZIP 解包后的二进制和视频一致性；播放看门狗单元测试始终按构建机器的本机架构运行。不需要安装 Codex，不把静态检查当作真实播放验证。

无需 Swift 工具链的架构选择回归检查：

```sh
./scripts/test-macos-architecture.sh
```

Intel 版本的真实视频播放、跳过和客户端交接仍需在 Intel Mac 桌面上按下列项目验收；CI 构建通过不代表已验证桌面行为。

桌面手动检查：

1. 在 Codex 已运行时双击启动器，确认动画和音轨播放、窗口适应屏幕，约 14 秒后启动器退出，客户端可操作。
2. 再次启动，在视频开始时按 Esc，确认立即淡出并切换到客户端；单独测试右上角按钮和 Command+.。
3. 在可关闭 Codex 的测试环境中退出客户端后启动，确认打开客户端并交接，等待有上限。
4. 在测试副本中移除视频，确认错误提示；在未安装 Codex 的测试环境中确认缺少客户端的提示。

原有文档记录了 Apple Silicon / macOS 27.0.1 下的完整播放和 Esc 跳过验收，日志均记录 `HANDOFF activation=true` 和 `FINISHED`；该记录不代表本次 Intel 适配已经过桌面实测。原有记录未覆盖关闭客户端后的冷启动、缺少客户端或损坏媒体的分支。Windows 测试应继续在 Windows 环境运行原有 `scripts/test.ps1`。
