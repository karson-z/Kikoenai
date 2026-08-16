# 在仓库根目录一键运行代码生成器（workspace 全量）。
#
# 用法（在根目录执行）：
#   .\build-gen.ps1                  # 生成 kikoenai_core / kikoenai_sites / kikoenai_app 全部产物
#   .\build-gen.ps1 --watch          # 监听模式，文件变化自动重新生成
#   .\build-gen.ps1 --clean          # 清空 build 缓存后重新生成
#
# 原理：build_runner 2.4.6+ 支持 pub workspace，`--workspace` 标志会让
# 每个成员包使用各自的生成器（freezed / json_serializable /
# hive_ce_generator / flutter_gen_runner），无需逐个 cd 进子目录。

[CmdletBinding()]
param(
  [switch]$Watch,
  [switch]$Clean,
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$RestArgs
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
  Write-Error "未找到根 pubspec.yaml，请确认在仓库根目录执行。"
  exit 1
}

# 优先使用 .fvmrc pin 的 Flutter SDK 自带的 dart（PATH 上的 dart 可能版本过旧）。
# 例如 .fvmrc 里 flutter=3.44.8 -> .fvm\versions\3.44.8\bin\dart.bat
$dartExe = 'dart'
$fvmrc = Join-Path $root '.fvmrc'
if (Test-Path $fvmrc) {
  try {
    $pinned = (Get-Content $fvmrc -Raw | ConvertFrom-Json).flutter
    $candidate = Join-Path $root ".fvm\versions\$pinned\bin\dart.bat"
    if (Test-Path $candidate) { $dartExe = $candidate }
  } catch {
    Write-Warning "解析 .fvmrc 失败，回退到 PATH 上的 dart。"
  }
}
Write-Host "==> 使用 dart: $dartExe" -ForegroundColor DarkGray

# 组装命令：dart run build_runner build --workspace
$cmd = @('run', 'build_runner')
if ($Watch) {
  $cmd += 'watch'
} else {
  $cmd += 'build'
}
$cmd += '--workspace'

if ($Clean) {
  Write-Host "==> dart run build_runner clean --workspace" -ForegroundColor Cyan
  Push-Location $root
  try { & $dartExe run build_runner clean --workspace } finally { Pop-Location }
}

Write-Host "==> $dartExe $($cmd -join ' ')" -ForegroundColor Cyan
Push-Location $root
try {
  & $dartExe @cmd @RestArgs
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($exitCode -ne 0) {
  Write-Error "代码生成失败 (exit $exitCode)"
  exit $exitCode
}

Write-Host "==> 代码生成完成" -ForegroundColor Green
