# RuoYi Project Deployment Guide

## Project Overview

**RuoYi v3.9.0** - A Java rapid development framework based on Spring Boot + Vue front-end/back-end separation.

- **Backend:** Spring Boot 2.5.15, Spring Security, Redis & JWT
- **Frontend:** Vue 2, Element UI
- **Database:** MySQL 8.0
- **Cache:** Redis 7 (Alpine)

---

## Environment Information

### System Requirements
- **Java:** OpenJDK 21.0.8
- **Maven:** Apache Maven 3.8.7
- **Node.js:** v22.18.0
- **npm:** 10.9.3
- **Docker:** 28.5.1
- **Docker Compose:** v2.40.0

### Platform
- **OS:** Linux 6.8.0-1040-raspi (Ubuntu/Debian based)
- **Architecture:** ARM64 (Raspberry Pi compatible)

---

## Deployment Steps

### Step 1: Start MySQL Database

MySQL is running in a Docker container:

```bash
cd /root/ruoyi-light-quick/mysql-env
docker compose up -d
```

**Database Configuration:**
- Container Name: `dev-mysql-8.0-ruoyi-vue3`
- Image: `mysql:8.0`
- Port: `3306`
- Database: `ruoyi-vue3-data`
- Root Password: `123456`
- User: `devuser` / Password: `123456`

**Database Tables Initialized:**
- sys_config, sys_dept, sys_dict_data, sys_dict_type
- sys_job, sys_job_log, sys_logininfor, sys_menu
- sys_notice, sys_oper_log, sys_post, sys_role
- sys_role_dept, sys_role_menu, sys_user
- sys_user_post, sys_user_role
- gen_table, gen_table_column
- Quartz tables (QRTZ_*)

---

### Step 2: Start Redis Cache

Redis is running in a Docker container:

```bash
cd /root/ruoyi-light-quick/redis-dev
docker compose up -d
```

**Redis Configuration:**
- Container Name: `dev-redis-7-ruoyi-vue3`
- Image: `redis:7-alpine`
- Port: `6379`
- Password: `123456`

---

### Step 3: Build Backend with Maven

```bash
cd /root/ruoyi-light-quick
mvn clean package -DskipTests
```

**Build Output:**
- JAR Location: `/root/ruoyi-light-quick/ruoyi-admin/target/ruoyi-admin.jar`
- Build Time: ~2 minutes
- Build Status: SUCCESS

**Modules Built:**
1. ruoyi-common (3.9.0)
2. ruoyi-system (3.9.0)
3. ruoyi-framework (3.9.0)
4. ruoyi-quartz (3.9.0)
5. ruoyi-generator (3.9.0)
6. ruoyi-admin (3.9.0)

---

### Step 4: Start Backend Server

```bash
cd /root/ruoyi-light-quick
mkdir -p logs
cp ruoyi-admin/target/ruoyi-admin.jar .
nohup java -jar ruoyi-admin.jar > logs/backend.log 2>&1 &
```

**Backend Configuration:**
- Server Port: `9999`
- Context Path: `/`
- Process ID: 6090
- Startup Time: ~92 seconds

**Application Configuration Files:**
- `application.yml` - Main configuration
- `application-druid.yml` - Database connection configuration

**Database Connection:**
```yaml
url: jdbc:mysql://localhost:3306/ruoyi-vue3-data
username: root
password: 123456
```

**Redis Connection:**
```yaml
host: localhost
port: 6379
password: 123456
```

---

### Step 5: Start Frontend Development Server

```bash
cd /root/ruoyi-light-quick/ruoyi-ui
npm run dev > /tmp/ruoyi-frontend.log 2>&1 &
```

**Frontend Configuration:**
- Framework: Vue 2 + Element UI
- Build Tool: Vue CLI Service (Webpack)
- Port: `81`
- Process ID: 6926
- Compile Time: ~78 seconds

**Access URLs:**
- Local: http://localhost:81/
- Network: http://192.168.1.213:81/

---

## Service Status Verification

### Check All Services

```bash
# Backend Process
ps aux | grep ruoyi-admin.jar

# Frontend Process
ps aux | grep vue-cli-service

# MySQL Container
docker ps | grep mysql

# Redis Container
docker ps | grep redis
```

### HTTP Connectivity Test

```bash
# Backend API
curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost:9999/

# Frontend
curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost:81/
```

### Database Connectivity Test

```bash
# MySQL
docker exec dev-mysql-8.0-ruoyi-vue3 mysql -uroot -p123456 -e "SELECT 'MySQL OK' as status;"

# Redis
docker exec dev-redis-7-ruoyi-vue3 redis-cli -a 123456 ping
```

---

## Access Information

### Default Login Credentials

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `admin123` |

### URL Summary

| Service | URL | Status |
|---------|-----|--------|
| Frontend | http://localhost:81/ | ✅ Running |
| Backend API | http://localhost:9999/ | ✅ Running |
| MySQL | localhost:3306 | ✅ Running |
| Redis | localhost:6379 | ✅ Running |

---

## Management Commands

### Stop Services

```bash
# Stop Backend
kill $(ps aux | grep ruoyi-admin.jar | grep -v grep | awk '{print $2}')

# Stop Frontend
kill $(ps aux | grep vue-cli-service | grep -v grep | awk '{print $2}')

# Stop MySQL
docker compose -f mysql-env/docker-compose.yml down

# Stop Redis
docker compose -f redis-dev/docker-compose.yml down
```

### View Logs

```bash
# Backend Logs
tail -f /root/ruoyi-light-quick/logs/backend.log

# Frontend Logs
tail -f /tmp/ruoyi-frontend.log

# MySQL Logs
docker logs dev-mysql-8.0-ruoyi-vue3

# Redis Logs
docker logs dev-redis-7-ruoyi-vue3
```

### Restart Services

```bash
# Restart Backend
cd /root/ruoyi-light-quick
kill $(ps aux | grep ruoyi-admin.jar | grep -v grep | awk '{print $2}')
nohup java -jar ruoyi-admin.jar > logs/backend.log 2>&1 &

# Restart Frontend
cd /root/ruoyi-light-quick/ruoyi-ui
kill $(ps aux | grep vue-cli-service | grep -v grep | awk '{print $2}')
npm run dev > /tmp/ruoyi-frontend.log 2>&1 &
```

---

## Project Structure

```
ruoyi-light-quick/
├── ruoyi-admin/          # Backend main module (Spring Boot entry)
├── ruoyi-common/         # Common utilities module
├── ruoyi-system/         # System management module
├── ruoyi-framework/      # Framework core module
├── ruoyi-quartz/         # Scheduled tasks module
├── ruoyi-generator/      # Code generator module
├── ruoyi-ui/             # Frontend Vue project
├── mysql-env/            # MySQL Docker configuration
├── redis-dev/            # Redis Docker configuration
├── sql/                  # Database initialization scripts
├── logs/                 # Backend logs directory
├── ruoyi-admin.jar       # Compiled backend JAR
├── pom.xml               # Maven configuration
├── ry.sh                 # Backend startup script
└── DEPLOYMENT_GUIDE.md   # This document
```

---

## Troubleshooting

### Backend Fails to Start

1. Check MySQL connection:
   ```bash
   docker exec dev-mysql-8.0-ruoyi-vue3 mysql -uroot -p123456 -e "SHOW DATABASES;"
   ```

2. Check Redis connection:
   ```bash
   docker exec dev-redis-7-ruoyi-vue3 redis-cli -a 123456 ping
   ```

3. Check backend logs:
   ```bash
   tail -f /root/ruoyi-light-quick/logs/backend.log
   ```

### Frontend Fails to Start

1. Check Node.js version:
   ```bash
   node -v  # Should be v22.18.0
   ```

2. Clear node_modules and reinstall:
   ```bash
   cd /root/ruoyi-light-quick/ruoyi-ui
   rm -rf node_modules
   npm install
   ```

3. Check frontend logs:
   ```bash
   tail -f /tmp/ruoyi-frontend.log
   ```

### Port Conflicts

- Backend uses port `9999`
- Frontend uses port `81`
- MySQL uses port `3306`
- Redis uses port `6379`

Check if ports are in use:
```bash
netstat -tlnp | grep -E "9999|81|3306|6379"
```

---

## Built-in Features

1. User Management - System user configuration
2. Department Management - Organization structure (tree view)
3. Position Management - User positions
4. Menu Management - System menus, permissions, button permissions
5. Role Management - Role menu permissions, data scope permissions
6. Dictionary Management - Fixed system data maintenance
7. Parameter Management - Dynamic system parameters
8. Notification Announcements - System notifications
9. Operation Logs - Normal and exception log records
10. Login Logs - System login records including exceptions
11. Online Users - Active user status monitoring
12. Scheduled Tasks - Online task scheduling with execution logs
13. Code Generator - Frontend/backend code generation (Java, HTML, XML, SQL)
14. System API - API interface documentation auto-generation
15. Service Monitoring - CPU, memory, disk, stack monitoring
16. Cache Monitoring - Redis cache information and command statistics
17. Online Builder - Drag form elements to generate HTML
18. Connection Pool Monitoring - Database connection pool status and SQL analysis

---

## Additional Resources

- **Official Demo:** http://vue.ruoyi.vip
- **Documentation:** http://doc.ruoyi.vip
- **GitHub:** https://github.com/yangzongzhuan/RuoYi-Vue
- **Gitee:** https://gitee.com/y_project/RuoYi-Vue

---

**Document Version:** 1.0
**Last Updated:** 2026-02-26
**Deployed by:** Claude Code Assistant
