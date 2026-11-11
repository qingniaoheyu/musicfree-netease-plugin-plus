@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

echo ========================================
echo   MusicFree Plugin - Push to GitHub
echo ========================================
echo.
echo Repo: qingniaoheyu/musicfree-netease-plugin-plus
echo.
echo Need a GitHub Token with 'repo' scope.
echo Create at: https://github.com/settings/tokens/new
echo.
echo ========================================
echo.

set /p TOKEN="Paste your GitHub Token (ghp_...): "

if "!TOKEN!"=="" (
    echo.
    echo [ERROR] Token is empty. Aborted.
    pause
    exit /b 1
)

echo.
echo [1/5] Verifying token...

powershell -NoProfile -Command ^
  "$h=@{Authorization='token %TOKEN%';'User-Agent'='mf-push'}; try { $me=Invoke-RestMethod 'https://api.github.com/user' -Headers $h -TimeoutSec 30; Write-Host ('  OK: ' + $me.login) -ForegroundColor Green } catch { Write-Host '  Invalid token' -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    pause
    exit /b 1
)

echo.
echo [2/5] Creating repository (skip if exists)...

powershell -NoProfile -Command ^
  "$h=@{Authorization='token %TOKEN%';'Accept'='application/vnd.github+json';'User-Agent'='mf-push'}; try { $null=Invoke-RestMethod 'https://api.github.com/repos/qingniaoheyu/musicfree-netease-plugin-plus' -Headers $h -TimeoutSec 30; Write-Host '  Repo already exists' -ForegroundColor Yellow } catch { $b=@{name='musicfree-netease-plugin-plus';description='MusicFree Netease plugin (enhanced) + Cookie-fix APK | MusicFree 网易云插件增强版 + Cookie 修复版 APK';private=$false;has_issues=$true} | ConvertTo-Json; try { $r=Invoke-RestMethod 'https://api.github.com/user/repos' -Method Post -Headers $h -Body ([System.Text.Encoding]::UTF8.GetBytes($b)) -ContentType 'application/json; charset=utf-8' -TimeoutSec 60; Write-Host ('  Created: ' + $r.html_url) -ForegroundColor Green } catch { Write-Host '  Create failed' -ForegroundColor Red; exit 1 } }"

if errorlevel 1 (
    pause
    exit /b 1
)

echo.
echo [3/5] Pushing files (about 62 MB, please wait)...

git remote remove origin 2>nul
git remote add origin https://qingniaoheyu:%TOKEN%@github.com/qingniaoheyu/musicfree-netease-plugin-plus.git
git -c credential.helper= push -u origin main --force

if errorlevel 1 (
    echo.
    echo [ERROR] Push failed. Check output above.
    git remote set-url origin https://github.com/qingniaoheyu/musicfree-netease-plugin-plus.git
    pause
    exit /b 1
)

echo.
echo [4/5] Removing token from local config...

git remote set-url origin https://github.com/qingniaoheyu/musicfree-netease-plugin-plus.git
echo   Token removed from .git/config

echo.
echo [5/5] Setting topics...

powershell -NoProfile -Command ^
  "$h=@{Authorization='token %TOKEN%';'Accept'='application/vnd.github+json';'User-Agent'='mf-push'}; $t=@{names=@('musicfree','netease','netease-cloud-music','plugin','android','cookie-fix','music-player')} | ConvertTo-Json; try { Invoke-RestMethod 'https://api.github.com/repos/qingniaoheyu/musicfree-netease-plugin-plus/topics' -Method Put -Headers $h -Body ([System.Text.Encoding]::UTF8.GetBytes($t)) -ContentType 'application/json; charset=utf-8' -TimeoutSec 30 | Out-Null; Write-Host '  Topics set' -ForegroundColor Green } catch { Write-Host '  Topics failed (not critical)' -ForegroundColor Yellow }"

echo.
echo ========================================
echo   DONE
echo ========================================
echo.
echo Repository: https://github.com/qingniaoheyu/musicfree-netease-plugin-plus
echo.
echo Next: create a Release at
echo https://github.com/qingniaoheyu/musicfree-netease-plugin-plus/releases/new
echo   Tag: v0.7.0
echo   Paste RELEASE-NOTES-v0.7.0.md as description
echo   Upload release/*.apk
echo.
echo IMPORTANT: Delete your token now at
echo https://github.com/settings/tokens
echo.
echo ========================================
pause
