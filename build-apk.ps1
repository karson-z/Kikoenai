# 在仓库根目录直接构建 APK，无需手动 cd 到 kikoenai_app。
#
# 用法（在根目录执行）：
#   .\build-apk.ps1                  # 默认 release + 分 ABI + 混淆
#   .\build-apk.ps1 -BuildDebug       # debug 构建
#   .\build-apk.ps1 -NoSplit          # 不拆 ABI
#   .\build-apk.ps1 -NoObfuscate     # 不混淆
#   .\build-apk.ps1 -Clean           # 构建前先 flutter clean
#
# 也可以透传任意 flutter build apk 参数：
#   .\build-apk.ps1 -- --no-tree-shake-icons

[CmdletBinding()]
param(
  [switch]$BuildDebug,
  [switch]$NoSplit,
  [switch]$NoObfuscate,
  [switch]$Clean,
  [string]$BuildMode,
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$RestArgs
)

$ErrorActionPreference = 'Stop'
$root   = $PSScriptRoot
$appDir = Join-Path $root 'kikoenai_app'
$symDir = Join-Path $root 'symbols'

if (-not (Test-Path (Join-Path $appDir 'lib\main.dart'))) {
  Write-Error "未找到 $appDir\lib\main.dart，请确认 kikoenai_app 目录结构。"
  exit 1
}

if (-not (Test-Path $symDir)) { New-Item -ItemType Directory -Path $symDir | Out-Null }

# 解析构建模式
$mode = if ($BuildDebug) { 'debug' } elseif ($BuildMode) { $BuildMode } else { 'release' }

# 组装 flutter build apk 参数
# 模式直接作为 flag（--release / --debug / --profile），flutter 没有 --build-mode
$buildArgs = @('build', 'apk', "--$mode")

if (-not $NoSplit)  { $buildArgs += '--split-per-abi' }
if (-not $NoObfuscate) {
  $buildArgs += '--obfuscate'
  $buildArgs += @('--split-debug-info', $symDir)
}

# 透传额外参数（跳过 "--" 分隔符）
if ($RestArgs) {
  $extra = $RestArgs | Where-Object { $_ -ne '--' }
  $buildArgs += $extra
}

Write-Host "==> 进入 $appDir" -ForegroundColor Cyan
if ($Clean) {
  Write-Host "==> flutter clean" -ForegroundColor Cyan
  Push-Location $appDir
  try { flutter clean } finally { Pop-Location }
}

Write-Host "==> flutter $($buildArgs -join ' ')" -ForegroundColor Cyan
Push-Location $appDir
try {
  flutter @buildArgs
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($exitCode -ne 0) {
  Write-Error "构建失败 (exit $exitCode)"
  exit $exitCode
}

Write-Host "==> 构建完成，symbols 已写入 $symDir" -ForegroundColor Green
