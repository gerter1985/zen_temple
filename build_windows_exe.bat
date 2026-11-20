@echo off
chcp 65001 >nul
echo [1/4] Building Flutter Windows Release...
call flutter build windows --release
if errorlevel 1 pause & exit /b 1

echo [2/4] Downloading yt-dlp.exe and mpv.exe...
powershell -NoProfile -Command ^
  "$out = 'build\windows\x64\runner\Release';" ^
  "New-Item -ItemType Directory -Force -Path \"$out\tools\", \"$out\books\" | Out-Null;" ^
  "if (Test-Path 'books_bundle') { Copy-Item 'books_bundle\*.epub' \"$out\books\\" -ErrorAction SilentlyContinue };" ^
  "Invoke-WebRequest -Uri 'https://github.com' -OutFile \"$out\tools\yt-dlp.exe\";" ^
  "Invoke-WebRequest -Uri 'https://github.com' -OutFile 'mpv.7z';" ^
  "& 'C:\Program Files\7-Zip\7z.exe' x mpv.7z -o'mpv_tmp' -y | Out-Null;" ^
  "Copy-Item 'mpv_tmp\mpv.exe' \"$out\tools\mpv.exe\";" ^
  "Copy-Item 'mpv_tmp\*.dll' \"$out\tools\\" -ErrorAction SilentlyContinue"

echo [3/4] Packing into single ZenTemple.exe with custom icon...
powershell -NoProfile -Command ^
  "$out = 'build\windows\x64\runner\Release';" ^
  "& 'C:\Program Files\7-Zip\7z.exe' a -mx=5 app.7z \"$out\*\";" ^
  "Invoke-WebRequest -Uri 'https://github.com' -OutFile '7zSD.sfx';" ^
  "Invoke-WebRequest -Uri 'https://github.com' -OutFile 'rcedit.exe';" ^
  ".\rcedit.exe '7zSD.sfx' --set-icon 'windows\runner\resources\app_icon.ico';" ^
  "$cfg = ';!@Install@!UTF-8!' + \"`r`n\" + 'RunProgram=\"zen_temple.exe\"' + \"`r`n\" + 'GUIMode=\"2\"' + \"`r`n\" + ';!@InstallEnd@!' + \"`r`n\";" ^
  "[System.IO.File]::WriteAllText('config.txt', $cfg, [System.Text.UTF8Encoding]::new($false));" ^
  "cmd /c copy /b 7zSD.sfx + config.txt + app.7z ZenTemple.exe"

echo [4/4] Done! File created: ZenTemple.exe
pause
