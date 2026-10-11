# 对应源码与构建

Windows 二进制的对应源代码在同一 Release 的 `XDH-Player-source-v0.1.0.zip`。其中 `reference/shadPS4` 是当前核心所用的完整上游/依赖源树，并已包含本地修改；不需要游戏或 Sony 系统模块即可编译。`patches/` 供审核本地核心改动。上游子模块的 FDK-AAC、libusb 与 WMI 兼容改动同时保存在源树中，并由 `tools/build_core.py` 检查。

核心基线：shadPS4 提交 `c7e065d1b415be16c23e260a21f1dd8bbfc4cb57`。工具链：Zig 0.15.2，Windows x86-64 目标；构建脚本采用 CMake、Ninja、Python。依赖版本以源码包内完整源树为准，避免在构建时切换到上游最新版本。

## 目录与工具准备

解压源包为 `XDH-Player-source/`，使用 Git、Python 3.11 或更新版本，安装 CMake/Ninja Python 包到该目录的 `toolchain/python-packages`：

```powershell
python -m pip install --target ./toolchain/python-packages cmake ninja
```

从 [Zig 官方](https://ziglang.org/download/) 取得 Windows x86-64 Zig 0.15.2，将解压目录放到源码目录的同级 `native/toolchain/zig-x86_64-windows-0.15.2/`：

```text
work/
  XDH-Player-source/
    config.json
    tools/build_core.py
    tools/runtime.py
    patches/
    reference/shadPS4/
    toolchain/python-packages/
  native/toolchain/zig-x86_64-windows-0.15.2/zig.exe
```

在 `XDH-Player-source` 运行：

```powershell
python tools/build_core.py --build --jobs 4
```

输出 `build/core/XHD-Runtime.exe`；构建日志与 SHA-256 记录位于 `evidence/`。脚本还会生成 Zig ar/ranlib 包装器及 CMake 工具规则，执行宿主 PE 的固定高地址和栈提交设置。不能省略最后 PE 处理步骤或用 guest eboot 替换宿主 EXE。

源码导出没有 `.git`，脚本从 `SOURCE_REVISION` 验证上游基线，并检查已应用核心补丁。源码包的辅助 `runtime.py` 仅提供构建所需的配置和哈希功能，去掉了开发机路径与本地运行入口。编译时 SCM 信息、构建时间和工具版本可能导致二进制哈希不同，不承诺逐字节复现发布 EXE。

完整源包包含上游依赖的许可证和某些上游自带的预编译依赖；这些文件遵循各自原有许可。上游构建说明可参阅 [shadPS4 Windows build documentation](https://github.com/shadps4-emu/shadPS4/blob/c7e065d1b415be16c23e260a21f1dd8bbfc4cb57/documents/building-windows.md)。

## 测试边界

`python tools/test_reserved_backing.py` 在 Windows 上验证共享 backing 按需提交语义，不启动游戏。真实游戏测试需自备资源与模块。新机器上的源包完整构建尚未单独验证；发布 EXE 则来自本地固定源树的成功构建，并通过最新内存改动的 60 秒启动测试。
