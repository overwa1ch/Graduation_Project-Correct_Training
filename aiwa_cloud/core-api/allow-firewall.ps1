# 以管理员身份运行此脚本，允许 core-api 端口 3002 的入站连接
# 右键 -> 使用 PowerShell 运行（需管理员权限）

$port = 3002
$ruleName = "AIWA core-api $port"

$existing = netsh advfirewall firewall show rule name=$ruleName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "规则已存在: $ruleName" -ForegroundColor Green
} else {
    netsh advfirewall firewall add rule name=$ruleName dir=in action=allow protocol=TCP localport=$port
    Write-Host "已添加防火墙规则: 允许 TCP 端口 $port 入站" -ForegroundColor Green
}
