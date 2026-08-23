; Kikoenai Windows 安装包脚本（Inno Setup 6）
;
; 使用方法：
;   1. 在 Git Bash 执行 ./build-windows.sh，生成 dist 目录下的便携包
;   2. 编译本脚本：
;        "F:\Inno Setup 6\ISCC.exe" tool\kikoenai_installer.iss
;   3. 安装包输出到 dist\kikoenai-v<version>-setup.exe
;
; 注意：升级版本号时同步修改下面的 #define MyAppVersion。

#define MyAppName "Kikoenai"
#define MyAppVersion "1.1.2"
#define MyAppPublisher "com.karson"
#define MyAppExeName "kikoenai.exe"

[Setup]
AppId={{8F6D9A2B-3C41-4E57-9A2D-KIKOENAI0001}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=kikoenai-v{#MyAppVersion}-setup
SetupIconFile=..\kikoenai_app\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
CloseApplications=yes
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "chinesesimplified"; MessagesFile: "languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Files]
Source: "..\dist\kikoenai-v{#MyAppVersion}-windows-x64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "立即运行 {#MyAppName}"; Flags: nowait postinstall
