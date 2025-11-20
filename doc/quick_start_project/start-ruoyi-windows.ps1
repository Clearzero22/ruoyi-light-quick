#!/usr/bin/env pwsh

<#
.SYNOPSIS
    RuoYi Project One-Click Startup Script for Windows
.DESCRIPTION
    This script automatically starts MySQL, Redis, backend and frontend services for RuoYi project
.AUTHOR
    RuoYi Project Team
.VERSION
    1.0.0
#>

# 设置颜色输出
$Colors = @{
    "Green" = "Green"
    "Yellow" = "Yellow"
    "Red" = "Red"
    "Blue" = "Blue"
    "Cyan" = "Cyan"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Separator {
    Write-ColorOutput "`n" + ("=" * 60) + "`n" "Cyan"
}

function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ForService {
    param(
        [string]$ServiceName,
        [int]$TimeoutSeconds = 60,
        [string]$TestCommand
    )

    Write-ColorOutput "等待 $ServiceName 服务启动..." "Yellow"
    $startTime = Get-Date
    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $timeout) {
        try {
            $result = Invoke-Expression $TestCommand 2>$null
            if ($result -match "healthy" -or $result -match "pong" -or $result -match "1") {
                Write-ColorOutput "✓ $ServiceName 服务已就绪" "Green"
                return $true
            }
        }
        catch {
            # 继续等待
        }

        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        Write-Progress -Activity "等待 $ServiceName" -Status "已等待 $([int]$elapsed) 秒" -PercentComplete (($elapsed / $TimeoutSeconds) * 100)
        Start-Sleep -Seconds 2
    }

    Write-ColorOutput "✗ $ServiceName 服务启动超时" "Red"
    return $false
}

function Start-DockerServices {
    Write-ColorOutput "正在启动 Docker 服务..." "Blue"

    # 检查 Docker 是否运行
    try {
        $dockerInfo = docker info 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Docker 未运行，正在尝试启动 Docker Desktop..." "Yellow"
            Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -WindowStyle Minimized
            Write-ColorOutput "请等待 Docker Desktop 启动完成后重新运行此脚本" "Yellow"
            return $false
        }
    }
    catch {
        Write-ColorOutput "Docker 未安装或未启动" "Red"
        Write-ColorOutput "请先安装 Docker Desktop: https://www.docker.com/products/docker-desktop" "Yellow"
        return $false
    }

    Write-ColorOutput "✓ Docker 服务正常" "Green"

    # 启动 MySQL
    Write-ColorOutput "正在启动 MySQL..." "Blue"
    Set-Location "$PSScriptRoot\..\..\mysql-env"
    docker-compose up -d

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✓ MySQL 容器启动成功" "Green"
    } else {
        Write-ColorOutput "✗ MySQL 容器启动失败" "Red"
        return $false
    }

    # 启动 Redis
    Write-ColorOutput "正在启动 Redis..." "Blue"
    Set-Location "$PSScriptRoot\..\..\redis-dev"
    docker-compose up -d

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✓ Redis 容器启动成功" "Green"
    } else {
        Write-ColorOutput "✗ Redis 容器启动失败" "Red"
        return $false
    }

    # 等待数据库服务就绪
    $mysqlReady = Wait-ForService "MySQL" 60 "docker exec dev-mysql-8.0-ruoyi-vue3 mysqladmin ping -h localhost -u root -p123456"
    if (-not $mysqlReady) {
        return $false
    }

    $redisReady = Wait-ForService "Redis" 30 "docker exec dev-redis-7-ruoyi-vue3 redis-cli -a 123456 ping"
    if (-not $redisReady) {
        return $false
    }

    return $true
}

function Start-Backend {
    Write-ColorOutput "正在启动后端服务..." "Blue"

    Set-Location "$PSScriptRoot\..\.."

    # 检查是否需要编译
    if (-not (Test-Path "ruoyi-admin\target\classes")) {
        Write-ColorOutput "正在编译项目..." "Yellow"
        mvn clean compile -DskipTests
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "✗ 项目编译失败" "Red"
            return $false
        }
        Write-ColorOutput "✓ 项目编译成功" "Green"
    }

    # 启动后端服务
    Write-ColorOutput "正在启动 Spring Boot 应用..." "Yellow"
    $backendJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        cd ruoyi-admin
        mvn spring-boot:run
    }

    # 等待后端启动
    Write-ColorOutput "等待后端服务启动..." "Yellow"
    $backendReady = $false
    for ($i = 0; $i -lt 60; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $backendReady = $true
                break
            }
        }
        catch {
            # 继续等待
        }
        Write-Progress -Activity "等待后端服务" -Status "已等待 $i 秒" -PercentComplete (($i / 60) * 100)
        Start-Sleep -Seconds 2
    }

    if ($backendReady) {
        Write-ColorOutput "✓ 后端服务启动成功 (http://localhost:8080)" "Green"
        return $backendJob
    } else {
        Write-ColorOutput "✗ 后端服务启动超时" "Red"
        Stop-Job $backendJob
        Remove-Job $backendJob
        return $false
    }
}

function Start-Frontend {
    Write-ColorOutput "正在启动前端服务..." "Blue"

    Set-Location "$PSScriptRoot\..\..\ruoyi-ui"

    # 检查 node_modules 是否存在
    if (-not (Test-Path "node_modules")) {
        Write-ColorOutput "正在安装前端依赖..." "Yellow"
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "✗ 前端依赖安装失败" "Red"
            return $false
        }
        Write-ColorOutput "✓ 前端依赖安装成功" "Green"
    }

    # 启动前端服务
    Write-ColorOutput "正在启动 Vue 开发服务器..." "Yellow"
    $frontendJob = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        npm run dev
    }

    # 等待前端启动
    Write-ColorOutput "等待前端服务启动..." "Yellow"
    $frontendReady = $false
    for ($i = 0; $i -lt 60; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:80" -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $frontendReady = $true
                break
            }
        }
        catch {
            # 继续等待
        }
        Write-Progress -Activity "等待前端服务" -Status "已等待 $i 秒" -PercentComplete (($i / 60) * 100)
        Start-Sleep -Seconds 2
    }

    if ($frontendReady) {
        Write-ColorOutput "✓ 前端服务启动成功 (http://localhost:80)" "Green"
        return $frontendJob
    } else {
        Write-ColorOutput "✗ 前端服务启动超时" "Red"
        Stop-Job $frontendJob
        Remove-Job $frontendJob
        return $false
    }
}

function Show-ServiceStatus {
    Write-Separator
    Write-ColorOutput "🎉 RuoYi 项目启动完成！" "Green"
    Write-Separator
    Write-ColorOutput "服务访问地址：" "Cyan"
    Write-ColorOutput "• 前端界面: http://localhost:80" "Blue"
    Write-ColorOutput "• 后端API:   http://localhost:8080" "Blue"
    Write-ColorOutput "• API文档:   http://localhost:8080/swagger-ui/" "Blue"
    Write-ColorOutput "• 数据库监控: http://localhost:8080/druid/" "Blue"
    Write-Separator
    Write-ColorOutput "默认登录账号：" "Cyan"
    Write-ColorOutput "• 用户名: admin" "Blue"
    Write-ColorOutput "• 密码:   admin123" "Blue"
    Write-Separator
    Write-ColorOutput "按 Ctrl+C 停止所有服务" "Yellow"
}

function Stop-Services {
    Write-ColorOutput "`n正在停止所有服务..." "Yellow"

    # 停止所有后台作业
    Get-Job | Stop-Job
    Get-Job | Remove-Job

    # 停止 Docker 容器
    try {
        Set-Location "$PSScriptRoot\..\..\mysql-env"
        docker-compose down
        Set-Location "$PSScriptRoot\..\..\redis-dev"
        docker-compose down
        Write-ColorOutput "✓ Docker 容器已停止" "Green"
    }
    catch {
        Write-ColorOutput "停止 Docker 容器时出现错误" "Yellow"
    }

    Write-ColorOutput "所有服务已停止" "Green"
    exit 0
}

# 主程序
try {
    # 设置 Ctrl+C 处理
    [Console]::TreatControlCAsInput = $false
    $originalErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    Write-ColorOutput "🚀 RuoYi 项目一键启动脚本 (Windows)" "Cyan"
    Write-Separator

    # 环境检查
    Write-ColorOutput "正在检查系统环境..." "Blue"

    $envChecks = @(
        @{Name="Java"; Command="java"; VersionCmd="java -version"},
        @{Name="Node.js"; Command="node"; VersionCmd="node -v"},
        @{Name="Maven"; Command="mvn"; VersionCmd="mvn -v"}
    )

    foreach ($check in $envChecks) {
        if (Test-Command $check.Command) {
            $version = Invoke-Expression $check.VersionCmd 2>&1 | Select-Object -First 1
            Write-ColorOutput "✓ $($check.Name): $version" "Green"
        } else {
            Write-ColorOutput "✗ $($check.Name): 未安装或未配置到 PATH" "Red"
            Write-ColorOutput "请先安装 $($check.Name) 并确保其在系统 PATH 中" "Yellow"
            exit 1
        }
    }

    Write-Separator

    # 启动服务
    if (-not (Start-DockerServices)) {
        Write-ColorOutput "Docker 服务启动失败，请检查 Docker 安装和配置" "Red"
        exit 1
    }

    $backendJob = Start-Backend
    if (-not $backendJob) {
        Write-ColorOutput "后端服务启动失败" "Red"
        exit 1
    }

    $frontendJob = Start-Frontend
    if (-not $frontendJob) {
        Write-ColorOutput "前端服务启动失败" "Red"
        Stop-Job $backendJob
        Remove-Job $backendJob
        exit 1
    }

    # 显示服务状态
    Show-ServiceStatus

    # 监控服务状态
    try {
        while ($true) {
            # 检查作业状态
            $backendState = (Get-Job $backendJob).State
            $frontendState = (Get-Job $frontendJob).State

            if ($backendState -eq "Failed" -or $frontendState -eq "Failed") {
                Write-ColorOutput "检测到服务异常退出" "Red"
                Stop-Services
            }

            if ($backendState -eq "Stopped" -or $frontendState -eq "Stopped") {
                Write-ColorOutput "服务已停止" "Yellow"
                exit 0
            }

            # 显示服务运行状态
            $timestamp = Get-Date -Format "HH:mm:ss"
            Write-Progress -Activity "RuoYi 服务运行中" -Status "时间: $timestamp" -PercentComplete -1

            Start-Sleep -Seconds 10
        }
    }
    finally {
        Stop-Services
    }
}
catch {
    Write-ColorOutput "脚本执行出现错误: $($_.Exception.Message)" "Red"
    Write-ColorOutput "错误详情: $($_.Exception.ToString())" "Red"
    exit 1
}
finally {
    $ErrorActionPreference = $originalErrorActionPreference
}