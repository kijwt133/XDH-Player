# 实现说明

## 架构

启动器设置包内工作目录，加载修改后的 shadPS4 0.19.0 核心。核心仍运行原版 PS4 x86-64 游戏程序并实现它使用的 PS4 服务，图形命令经 shader 重编译和 Vulkan 后端执行。未将整个游戏反编译并重写成原生 PC 程序，也没有改变游戏资源或替换游戏逻辑。

默认 `faithful-exposure-readbacks` 配置：`readbacks_mode=0`、`readback_linear_images_enabled=true`、`vblank_frequency=60`；FSR、RCAS 与 shader patch 关闭，pipeline cache 开启。`XHD_HOST_STACK_MUTEX=1`、`XHD_EXPOSURE_READBACKS=1` 启用专用修复。

## 宿主栈兼容

游戏进入启动路径时，某些宿主互斥操作在 guest 栈上调用会崩溃。专用构建使用宿主栈包装互斥 lock/unlock，保留原有互斥语义，不跳过同步。该修复是已实测游戏路径的定向兼容改动，不是通用所有 PS4 软件的栈修复。

## 光照与曝光回读

菜单正常而局内变暗并不能单靠画面对比证明最终 Gamma 请求错误。本地诊断没有证明最终输出 Gamma 是根因；保留线性图像回读后光照恢复，说明 GPU 到 CPU 反馈路径与问题相关。修复没有对整个画面统一抬亮、强制 Gamma 或覆盖最终色调处理。

`texture_cache.cpp` 的专用分支保留原下载候选生成逻辑，仅允许宽、高均不超过 8 且非深度的图像进入该路径。对候选建立下载任务，以 16 字节对齐分配同一 staging buffer。全部 GPU copy 提交后仅等待一次 `scheduler.Finish()`，invalidate staging 后逐个同步写回 guest backing，再返回。既保留 CPU 可见性，又减少大量无关图像回读和等待。

初期的全量回读/所有线性图像方案恢复亮度却出现 30 FPS 以下乃至约 10 FPS。专用批量回读后，使用者反馈亮度和 FPS 都已修复。启动阶段的 A/B 日志显示一次典型批次由约 12.3 MiB、9 次等待降至 1 KiB、1 次等待；两种批次不完全相同，这些数据不是局内帧率基准。

## Windows 内存提交

上游 Windows backing 使用 `SEC_COMMIT` 一次为 8448 MiB 建立 pagefile-backed section。即使物理内存并非完全用尽，系统剩余提交额度不足也会导致启动失败。

X HD 专用构建改用 `SEC_RESERVE`，保留原 7936 MiB direct backing 与其后的 flexible backing 地址布局。`MapRegion` 在内部物理映射且不是外部文件时，检查边界并通过永久 backing view 的 `VirtualAlloc(MEM_COMMIT)` 提交该区域，然后才映射 guest alias。外部文件映射和普通私有虚拟内存路径保持原逻辑。

已提交页面在重复提交时保留内容；共享映射仍指向相同物理页。测试覆盖高偏移的 flexible backing、alias 共享写入、重复提交保留内容、共享清零。当前方案不会在每次 unmap 时取消提交，峰值需求仍取决于游戏实际使用过的区域。

最新核心 SHA-256：`e9a86ba6b22079d8cf002591538ef7c83fcfca706b5f300f4eda3f4b4ee95c19`。

60 秒静音启动测试前，系统提交上限约 26.816 GiB，已使用约 19.088 GiB，剩余约 7.728 GiB；旧 8.25 GiB 一次申请不满足此条件。新核心成功加载开场视频，测试到时由启动器结束，无内存分配断言。这验证启动问题，未证明所有场景的最低内存需求。

参考 [Microsoft SEC_RESERVE 文档](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-createfilemappinga)。

## 启动与数据隔离

Windows PowerShell 5.1 启动脚本使用 UTF-8 BOM，CMD 使用 CRLF 并切换代码页 65001。路径从脚本所在目录解析，不依赖开发机的 E 盘目录。核心 working directory 为 `runtime`，其 `user` 子目录独立保存用户配置与存档。

启动器通过独占锁阻止同一包启动多个实例，校验固定核心/模块及游戏关键文件。`OwnedGameJob.cs` 使用 `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` 约束本次游戏进程；限时诊断使用静音配置并在结束后恢复配置，不终止不相关的应用。

启动日志保留实际退出码、限时测试标记、核心哈希和路径。因限时结束返回成功不等于正常游戏自行退出，更不等于完整流程验证。

## 发布范围

Windows Release 是独立重新生成的干净副本，而不是直接打包活跃运行目录。游戏、Sony 模块、密钥、用户数据、日志与缓存均不发布。纯净模板也不包含核心二进制。完整源包包含固定上游和依赖源树的本地修改版本；源码包没有 Git 历史和开发机运行数据。
