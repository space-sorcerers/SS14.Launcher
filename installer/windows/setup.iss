#define MyAppName "Space Station 14 Launcher"
#ifndef MyAppVersion
  #define MyAppVersion "1.1.1"
#endif
#define MyAppPublisher "space-sorcerers"
#define MyAppURL "https://ss14.art"
#define MyAppExeName "Space Station 14 Launcher.exe"

[Setup]
AppId={{B8A0A9B0-8A8A-4A8A-8A8A-8A8A8A8A8A8A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\..\bin\installers
OutputBaseFilename=SS14.Launcher_Windows_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\bin\publish\Windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\bin\publish\Windows\dotnet_x64\*"; DestDir: "{app}\dotnet_x64"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\bin\publish\Windows\bin_x64\*"; DestDir: "{app}\bin_x64"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\bin\publish\Windows\bin_x64\loader\*"; DestDir: "{app}\bin_x64\loader"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{app}\dotnet_x64"
Name: "{app}\bin_x64"
Name: "{app}\bin_x64\loader"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
