# 真机 USB 调试时，将手机 3002 端口转发到电脑
# 运行前确保：1) 手机已 USB 连接 2) 已开启 USB 调试
# 使用方式：.\scripts\adb-reverse.ps1

adb reverse tcp:3002 tcp:3002
if ($LASTEXITCODE -eq 0) {
    Write-Host "已建立端口转发: 手机 127.0.0.1:3002 -> 电脑 3002" -ForegroundColor Green
    Write-Host "请保持 USB 连接，然后运行 flutter run" -ForegroundColor Cyan
} else {
    Write-Host "失败：请确认手机已连接且已开启 USB 调试" -ForegroundColor Red
}
