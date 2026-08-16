# 在仓库根目录构建 Windows 桌面版 exe 并打包为便携 zip。
#
# 用法（在根目录执行）：
#   ./build-windows.ps1                  # release 构建 + 打包 zip（默认）
#   ./build-windows.ps1 -BuildDebug      # debug 构建
#   ./build-windows.ps1 -BuildMode profile
#   ./build-windows.ps1 -NoZip           # 只构建，不打包
#   ./build-windows.ps1 -Clean           # 构建前先 flutter clean
#   ./build-windows.ps1 -SkipRuntimeDlls # 打包时不附带 VC++ 运行库 DLL
#   ./build-windows.ps1 -BuildInstaller   # 同时用 Inno Setup 编译安装包（需已安装 Inno Setup）
#   ./build-windows.ps1 -Version 1.1.3      # 手动指定产物版本号（CI 中传入 tag 版本）
#
# 产物输出到 <仓库>/dist/：
#   kikoenai-v<version>-windows-x64/     （便携目录，双击 kikoenai.exe 直接运行）
#   kikoenai-v<version>-windows-x64.zip  （分发给用户的压缩包）

[CmdletBinding()]
param(
  [switch]$BuildDebug,
  [switch]$NoZip,
  [switch]$Clean,
  [switch]$SkipRuntimeDlls,
  [switch]$BuildInstaller,
  [string]$Version,
  [string]$BuildMode,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RestArgs
)

$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$appDir  = Join-Path $root 'kikoenai_app'
$distDir = Join-Path $root 'dist'

# 解析 flutter 命令：优先 .fvm 的 flutter_sdk（版本与 .fvmrc 一致），否则回退 PATH 中的 flutter。
function Get-FlutterCmd {
  $fvmFlutter = Join-Path $root '.fvm/flutter_sdk/bin/flutter.bat'
  if (Test-Path $fvmFlutter) { return $fvmFlutter }
  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { return 'flutter' }
  throw '未找到 flutter 命令，也没有 .fvm/flutter_sdk。'
}

if (-not (Test-Path (Join-Path $appDir 'lib/main.dart'))) {
  Write-Error "未找到 $appDir/lib/main.dart，请确认 kikoenai_app 目录结构。"
  exit 1
}

# 从 pubspec 读取版本号（用于产物命名）
$pubspec     = Join-Path $appDir 'pubspec.yaml'
$versionLine = (Select-String -Path $pubspec -Pattern '^version:').Line
$versionRaw  = $versionLine.Replace('version:', '').Trim()
$version     = if ($Version) { $Version.TrimStart('v') } else { $versionRaw.Split('+')[0] }

# 解析构建模式
$mode = if ($BuildDebug) { 'debug' } elseif ($BuildMode) { $BuildMode } else { 'release' }

$flutter = Get-FlutterCmd

if ($Clean) {
  Write-Host "==> flutter clean" -ForegroundColor Cyan
  Push-Location $appDir
  try { & $flutter clean } finally { Pop-Location }
}

$buildArgs = @('build', 'windows', "--$mode")
if ($RestArgs) { $buildArgs += ($RestArgs | Where-Object { $_ -ne '--' }) }

Write-Host "==> flutter $($buildArgs -join ' ')" -ForegroundColor Cyan
Push-Location $appDir
try {
  & $flutter @buildArgs
  $exitCode = $LASTEXITCODE
} finally {
  Pop-Location
}
if ($exitCode -ne 0) {
  Write-Error "构建失败 (exit $exitCode)"
  exit $exitCode
}

if ($NoZip) {
  Write-Host "==> 跳过打包（产物在 $appDir/build/windows/x64/runner）" -ForegroundColor Green
  exit 0
}

# 构建产物目录
$cfg    = if ($mode -eq 'debug') { 'Debug' } elseif ($mode -eq 'profile') { 'Profile' } else { 'Release' }
$srcDir = Join-Path $appDir "build/windows/x64/runner/$cfg"
if (-not (Test-Path $srcDir)) {
  Write-Error "未找到构建产物: $srcDir"
  exit 1
}

# 必需文件校验
foreach ($required in @('kikoenai.exe', 'data', 'flutter_windows.dll')) {
  if (-not (Test-Path (Join-Path $srcDir $required))) {
    Write-Error "构建产物缺少必需文件: $required"
    exit 1
  }
}

# 暂存便携目录
$pkgName  = "kikoenai-v$version-windows-x64"
$stageDir = Join-Path $distDir $pkgName
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
if (Test-Path $stageDir) { Remove-Item $stageDir -Recurse -Force }
New-Item -ItemType Directory -Path $stageDir | Out-Null

Copy-Item (Join-Path $srcDir '*') -Destination $stageDir -Recurse -Force
Write-Host "==> 已复制构建产物到 $stageDir" -ForegroundColor Cyan

# 附带 VC++ 运行库（app-local 部署，目标机器无需预装 VC++ Redistributable）
if (-not $SkipRuntimeDlls) {
  $sys32 = Join-Path $env:WINDIR 'System32'
  $runtimeDlls = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') |
    ForEach-Object { Join-Path $sys32 $_ } |
    Where-Object { Test-Path $_ }
  if ($runtimeDlls.Count -gt 0) {
    $runtimeDlls | ForEach-Object { Copy-Item $_ -Destination $stageDir -Force }
    Write-Host "==> 已附带 VC++ 运行库: $($runtimeDlls | ForEach-Object { Split-Path $_ -Leaf })" -ForegroundColor Cyan
  } else {
    Write-Warning '未找到 VC++ 运行库 DLL，目标机器需已安装 VC++ 2015-2022 Redistributable。'
  }
}

# 压缩为 zip
$zipPath = Join-Path $distDir "$pkgName.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $stageDir -DestinationPath $zipPath -CompressionLevel Optimal

$zip    = Get-Item $zipPath
$sizeMB = [math]::Round($zip.Length / 1MB, 2)
Write-Host "==> 打包完成: $zipPath ($sizeMB MB)" -ForegroundColor Green
Write-Host "==> 解压后双击 kikoenai.exe 即可运行（无需安装）" -ForegroundColor Green

# 可选：使用 Inno Setup 编译安装包
if ($BuildInstaller) {
  $iscc = $null
  foreach ($c in @('F:/Inno Setup 6/ISCC.exe', 'C:/Program Files (x86)/Inno Setup 6/ISCC.exe', 'C:/Program Files/Inno Setup 6/ISCC.exe')) {
    if (Test-Path $c) { $iscc = $c; break }
  }
  if (-not $iscc) {
    $cm = Get-Command iscc.exe -ErrorAction SilentlyContinue
    if ($cm) { $iscc = $cm.Source }
  }
  if ($iscc) {
    $iss = Join-Path $root 'tool/kikoenai_installer.iss'
    Write-Host "==> Inno Setup 编译安装包..." -ForegroundColor Cyan
    & $iscc $iss
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Inno Setup 编译失败 (exit $LASTEXITCODE)"
      exit $LASTEXITCODE
    }
    Write-Host "==> 安装包: $distDir/kikoenai-v$version-setup.exe" -ForegroundColor Green
  } else {
    Write-Warning '未找到 Inno Setup (ISCC.exe)，跳过安装包编译。'
  }
}
