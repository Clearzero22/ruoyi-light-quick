# RuoYi 跨平台快速启动指南

## 概述

本文档提供了在 Windows、Linux 和 macOS 系统上快速启动 RuoYi 项目的完整流程，包括一键启动脚本的使用方法。

## 系统要求

### 所有平台通用要求
- **Java**: JDK 1.8+
- **Node.js**: 8.9+
- **Maven**: 3.6+
- **Docker**: 推荐使用，用于快速启动 MySQL 和 Redis

### 平台特定要求
- **Windows**: Windows 10/11, PowerShell 5.0+
- **Linux**: Ubuntu 18.04+, CentOS 7+, 或其他主流发行版
- **macOS**: macOS 10.14+ (Mojave)

## 快速启动方法

### 方法一：使用一键启动脚本（推荐）

#### Windows 平台
```powershell
# 以管理员身份运行 PowerShell
cd doc/quick_start_project
./start-ruoyi-windows.ps1
```

#### Linux/macOS 平台
```bash
cd doc/quick_start_project
chmod +x start-ruoyi-linux.sh
./start-ruoyi-linux.sh
```

### 方法二：手动分步启动

#### 1. 启动基础服务（Docker 方式）

**所有平台通用命令：**
```bash
# 启动 MySQL
cd mysql-env
docker-compose up -d

# 启动 Redis
cd ../redis-dev
docker-compose up -d

# 返回项目根目录
cd ../..
```

#### 2. 启动后端服务

**所有平台通用命令：**
```bash
# 编译项目
mvn clean install -DskipTests

# 启动后端
cd ruoyi-admin
mvn spring-boot:run
```

#### 3. 启动前端服务

**所有平台通用命令：**
```bash
# 新开终端窗口
cd ruoyi-ui

# 安装依赖（首次运行）
npm install

# 启动前端开发服务器
npm run dev
```

## 一键启动脚本功能

### 脚本特性
- ✅ 自动检测系统环境
- ✅ 智能检查 Docker 是否安装和运行
- ✅ 自动启动 MySQL 和 Redis 容器
- ✅ 并行启动后端和前端服务
- ✅ 实时显示启动日志
- ✅ 错误检测和友好提示
- ✅ 支持优雅停止（Ctrl+C）

### 脚本执行流程

1. **环境检查**
   - 检查 Java 环境
   - 检查 Node.js 环境
   - 检查 Maven 环境
   - 检查 Docker 环境（可选）

2. **服务启动**
   - 启动 MySQL 和 Redis 容器
   - 等待数据库服务就绪
   - 编译后端项目
   - 启动后端服务
   - 安装前端依赖（如需要）
   - 启动前端服务

3. **状态监控**
   - 显示服务启动状态
   - 提供访问地址
   - 监控运行状态

## 访问地址

启动成功后，可以通过以下地址访问：

- **前端界面**: http://localhost:80
- **后端 API**: http://localhost:8080
- **API 文档**: http://localhost:8080/swagger-ui/
- **数据库监控**: http://localhost:8080/druid/

## 默认账号

- **用户名**: admin
- **密码**: admin123

## 常见问题解决

### Docker 相关问题

#### Windows Docker Desktop 未启动
```powershell
# 启动 Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

#### Linux Docker 服务未启动
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

#### macOS Docker Desktop 未启动
```bash
open /Applications/Docker.app
```

### 端口占用问题

#### 检查端口占用
```bash
# Windows (PowerShell)
netstat -ano | findstr ":8080"
netstat -ano | findstr ":80"

# Linux/macOS
lsof -i :8080
lsof -i :80
```

#### 停止占用端口的进程
```bash
# Windows
taskkill /PID <PID> /F

# Linux/macOS
kill -9 <PID>
```

### 服务启动失败

#### 后端启动失败
1. 检查 Java 版本：`java -version`
2. 检查 Maven 配置：`mvn -v`
3. 清理 Maven 缓存：`mvn clean`
4. 重新编译：`mvn compile`

#### 前端启动失败
1. 检查 Node.js 版本：`node -v`
2. 清理 npm 缓存：`npm cache clean --force`
3. 删除 node_modules：`rm -rf node_modules`
4. 重新安装：`npm install`

### 数据库连接问题

#### 检查 MySQL 容器状态
```bash
docker ps | grep mysql
```

#### 查看 MySQL 容器日志
```bash
docker logs dev-mysql-8.0-ruoyi-vue3
```

#### 重启 MySQL 容器
```bash
cd mysql-env
docker-compose restart
```

## 高级配置

### 修改端口配置

#### 前端端口修改
编辑 `ruoyi-ui/vue.config.js`:
```javascript
module.exports = {
  devServer: {
    port: 8081, // 修改为你想要的端口
    // ...
  }
}
```

#### 后端端口修改
编辑 `ruoyi-admin/src/main/resources/application.yml`:
```yaml
server:
  port: 8081 # 修改为你想要的端口
```

### 修改数据库连接

编辑 `ruoyi-admin/src/main/resources/application-druid.yml`:
```yaml
spring:
    datasource:
        druid:
            master:
                url: jdbc:mysql://localhost:3306/ruoyi-vue3-data?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
                username: root
                password: your_password # 修改密码
```

### 修改 Redis 连接

编辑 `ruoyi-admin/src/main/resources/application.yml`:
```yaml
spring:
  redis:
    host: localhost
    port: 6379
    password: your_password # 修改密码
```

## 开发环境配置

### IDE 配置

#### IntelliJ IDEA
1. 导入项目：`File -> Open -> 选择项目根目录的 pom.xml`
2. 设置 JDK：`File -> Project Structure -> Project Settings -> Project -> Project SDK`
3. 配置 Maven：`File -> Settings -> Build Tools -> Maven`

#### VS Code
1. 安装 Java 扩展包
2. 安装 Vue 扩展包
3. 配置工作区设置

### 环境变量配置

#### Windows
```powershell
# 设置环境变量（临时）
$env:JAVA_HOME = "C:\Program Files\Java\jdk1.8.0_XXX"
$env:MAVEN_HOME = "C:\Program Files\Apache\maven-3.8.X"
```

#### Linux/macOS
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
export MAVEN_HOME=/opt/maven
export PATH=$PATH:$JAVA_HOME/bin:$MAVEN_HOME/bin
```

## 生产环境部署

### Docker Compose 部署

创建 `docker-compose.prod.yml`:
```yaml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
    volumes:
      - mysql_data:/var/lib/mysql
    restart: always

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    restart: always

  backend:
    build: ./ruoyi-admin
    depends_on:
      - mysql
      - redis
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/${MYSQL_DATABASE}
      SPRING_REDIS_HOST: redis
    ports:
      - "8080:8080"
    restart: always

  frontend:
    build: ./ruoyi-ui
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: always

volumes:
  mysql_data:
  redis_data:
```

## 性能优化建议

### 后端优化
- 配置数据库连接池
- 启用 Redis 缓存
- 配置 JVM 参数
- 使用生产环境配置

### 前端优化
- 启用 Gzip 压缩
- 配置 CDN
- 代码分割和懒加载
- 生产环境构建优化

## 监控和日志

### 应用监控
- Spring Boot Actuator
- Prometheus + Grafana
- ELK Stack

### 日志配置
- Logback 配置
- 日志级别设置
- 日志轮转配置

## 脚本使用技巧

### Windows PowerShell
```powershell
# 绕过执行策略限制
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser

# 查看执行策略
Get-ExecutionPolicy
```

### Linux/macOS Shell
```bash
# 查看脚本权限
ls -la start-ruoyi-linux.sh

# 添加执行权限
chmod +x start-ruoyi-linux.sh

# 查看系统信息
uname -a
```

## 技术支持

如果遇到问题，可以：
1. 查看项目日志文件
2. 检查系统环境配置
3. 参考官方文档
4. 提交 Issue 到项目仓库

---

*最后更新：2025-11-20*