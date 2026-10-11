param([switch]$Check, [int]$TestSeconds = 0)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$playerRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $playerRoot 'runtime'
$gameRoot = Join-Path $playerRoot 'game\CUSA02908'
$corePath = Join-Path $playerRoot 'core\XHD-Runtime.exe'
$process = $null
$job = $null
$previousConfig = $null
$configPath = Join-Path $runtimeRoot 'user\config.json'
$exitCode = 0
$lock = $null
try {
    $lock = [IO.File]::Open((Join-Path $runtimeRoot 'launcher.lock'), 'OpenOrCreate', 'ReadWrite', 'None')
    Write-Host '[1/3] 检查运行环境和游戏。'
    $manifest = Get-Content -LiteralPath (Join-Path $playerRoot 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($asset in $manifest.required_files) {
        $path = Join-Path $playerRoot $asset.path
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "运行环境缺少文件：$($asset.path)" }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $asset.sha256) {
            throw "运行环境文件校验失败：$($asset.path)"
        }
    }
    if (!(Test-Path -LiteralPath (Join-Path $gameRoot 'eboot.bin') -PathType Leaf)) {
        throw "请将完整 CUSA02908 文件夹放到：$gameRoot。应能看到 game\CUSA02908\eboot.bin。"
    }
    foreach ($asset in $manifest.game_critical_files) {
        $path = Join-Path $gameRoot $asset.path
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "游戏缺少文件：$($asset.path)" }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $asset.sha256) {
            throw "游戏关键文件不匹配。此运行时支持 CUSA02908 01.00：$($asset.path)"
        }
    }
    foreach ($name in @('rom', 'sce_module', 'sce_sys')) {
        if (!(Test-Path -LiteralPath (Join-Path $gameRoot $name) -PathType Container)) { throw "游戏文件夹不完整：缺少 $name" }
    }
    if ($Check) {
        Write-Host '检查通过：核心、必要模块和游戏关键文件匹配。未启动游戏。'
    } else {
        Write-Host '[2/3] 准备独立配置。'
        $previousConfig = [IO.File]::ReadAllBytes($configPath)
        $settings = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $settings.GPU.readbacks_mode = 0
        $settings.GPU.readback_linear_images_enabled = $true
        $settings.GPU.vblank_frequency = 60
        $settings.GPU.fsr_enabled = $false
        $settings.GPU.rcas_enabled = $false
        $settings.GPU.patch_shaders = $false
        $settings.Vulkan.pipeline_cache_enabled = $true
        $settings.Vulkan.pipeline_cache_archived = $false
        if ($TestSeconds -gt 0) { $settings.General.volume_slider = 0 }
        [IO.File]::WriteAllText($configPath, ($settings | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
        $env:XHD_HOST_STACK_MUTEX = '1'
        $env:XHD_EXPOSURE_READBACKS = '1'
        Remove-Item Env:XHD_COLOR_DIAGNOSTICS -ErrorAction SilentlyContinue
        Remove-Item Env:XHD_EAGER_CPU_PATCHES -ErrorAction SilentlyContinue
        Add-Type -Path (Join-Path $PSScriptRoot 'OwnedGameJob.cs')
        $logRoot = Join-Path $playerRoot 'logs'
        [IO.Directory]::CreateDirectory($logRoot) | Out-Null
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $stdout = Join-Path $logRoot "$stamp-console.log"
        $stderr = Join-Path $logRoot "$stamp-stderr.log"
        Write-Host '[3/3] 启动游戏；首次生成图形缓存时请等待窗口。'
        Write-Host '当前面键：W=△ D=○ S=× A=□；F8 重载键位，F11 全屏。'
        $argsText = '--fullscreen false --show-fps --ignore-game-patch "' + (Join-Path $gameRoot 'eboot.bin') + '"'
        $process = Start-Process -FilePath $corePath -ArgumentList $argsText -WorkingDirectory $runtimeRoot -PassThru -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $job = New-Object XhdPlayer.OwnedGameJob($process.Handle)
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $nextUpdate = 5
        $timedOut = $false
        while (!$process.HasExited) {
            if ($TestSeconds -gt 0 -and $watch.Elapsed.TotalSeconds -ge $TestSeconds) {
                $timedOut = $true
                $job.Dispose(); $job = $null
                $process.WaitForExit()
                break
            }
            if ($watch.Elapsed.TotalSeconds -ge $nextUpdate) {
                Write-Host ("游戏进程运行中：{0} 秒。取消可按 Ctrl+C。" -f [int]$watch.Elapsed.TotalSeconds)
                $nextUpdate += 10
            }
            Start-Sleep -Milliseconds 500
            $process.Refresh()
        }
        $process.WaitForExit()
        $exitCode = $process.ExitCode
        $gameLog = Join-Path $runtimeRoot 'user\log\shad_log.txt'
        $savedGameLog = Join-Path $logRoot "$stamp-game.log"
        if (Test-Path -LiteralPath $gameLog -PathType Leaf) { Copy-Item -LiteralPath $gameLog -Destination $savedGameLog }
        $record = @{ core_sha256 = $manifest.core_sha256; game_path = $gameRoot; process_exit_code = $exitCode; timed_test = ($TestSeconds -gt 0); test_muted = ($TestSeconds -gt 0); stopped_by_time_limit = $timedOut; seconds = $watch.Elapsed.TotalSeconds; profile = 'faithful-exposure-readbacks'; console_log = $stdout; game_log = $savedGameLog }
        [IO.File]::WriteAllText((Join-Path $logRoot 'last-run.json'), ($record | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
        if ($timedOut) { $exitCode = 0 }
        elseif ($exitCode -ne 0) {
            $logText = [IO.File]::ReadAllText($stdout)
            if (Test-Path -LiteralPath $gameLog -PathType Leaf) { $logText += [IO.File]::ReadAllText($gameLog) }
            if ($logText.Contains('Insufficient system resources')) { Write-Host 'Windows 无法分配游戏内存。请关闭不用的程序后重试。' }
            Write-Host "游戏异常退出，日志目录：$logRoot"
        } else { Write-Host '游戏已关闭，存档和设置保存在 runtime\user。' }
    }
} catch {
    Write-Host ('无法启动：' + $_.Exception.Message) -ForegroundColor Red
    $exitCode = 2
} finally {
    if ($job) { $job.Dispose() }
    if ($process -and !$process.HasExited) { $process.Kill(); $process.WaitForExit() }
    if ($previousConfig -and $TestSeconds -gt 0) { [IO.File]::WriteAllBytes($configPath, $previousConfig) }
    if ($lock) { $lock.Dispose() }
}
exit $exitCode
