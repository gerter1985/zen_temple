[Setup]
AppName=Таро Простір • Школа Майстра
AppVersion=1.0.0
AppPublisher=Євген Гертер
DefaultDirName={autopf}\TarotSchool
DefaultGroupName=Таро Простір • Школа Майстра
OutputDir=.
OutputBaseFilename=TarotSchool_Setup
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/fast
SolidCompression=yes
PrivilegesRequired=lowest
[Languages]
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Таро Простір • Школа Майстра"; Filename: "{app}\tarot_flutter.exe"
Name: "{autodesktop}\Таро Простір • Школа Майстра"; Filename: "{app}\tarot_flutter.exe"

[Run]
Filename: "{app}\tarot_flutter.exe"; Description: "Запустити Таро Простір • Школа Майстра"; Flags: nowait postinstall skipifsilent
