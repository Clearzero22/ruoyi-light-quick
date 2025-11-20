# RuoYi Quick Start Guide

## Project Overview

RuoYi is a front-end and back-end separated permission management system based on Spring Boot + Vue, supporting MySQL and Redis databases.

## Environment Requirements

### Basic Environment
- **Java**: JDK 1.8+
- **Node.js**: 8.9+ (latest stable version recommended)
- **Maven**: 3.6+
- **Docker**: (optional, for quick database and Redis deployment)

### Database Environment
- **MySQL**: 8.0+
- **Redis**: 6.0+

## Quick Start Steps

### Step 1: Start Basic Services (using Docker - Recommended)

If Docker is installed, this is the fastest startup method:

```bash
# Start MySQL database
cd mysql-env
docker-compose up -d

# Start Redis
cd ../redis-dev
docker-compose up -d
```

### Step 2: Manual Database Installation (without Docker)

If not using Docker, manual installation and configuration is required:

#### MySQL Configuration
1. Install MySQL 8.0+
2. Create database:
   ```sql
   CREATE DATABASE `ruoyi-vue3-data` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
   ```
3. Import initialization data:
   - Execute `sql/ry_20250522.sql`
   - Execute `sql/quartz.sql`

#### Redis Configuration
1. Install Redis 6.0+
2. Modify Redis configuration file, set password to `123456`
3. Start Redis service

### Step 3: Configure Database Connection

Check and modify `ruoyi-admin/src/main/resources/application-druid.yml` file:

```yaml
spring:
    datasource:
        druid:
            master:
                url: jdbc:mysql://localhost:3306/ruoyi-vue3-data?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=GMT%2B8
                username: root
                password: 123456  # Modify according to your MySQL password
```

### Step 4: Configure Redis Connection

Check and modify `ruoyi-admin/src/main/resources/application.yml` file:

```yaml
spring:
  redis:
    host: localhost
    port: 6379
    password: 123456  # Modify according to your Redis password
```

### Step 5: Start Backend Service

```bash
# Execute in project root directory
mvn clean install

# Start backend application
cd ruoyi-admin
mvn spring-boot:run
```

Backend service will start at `http://localhost:8080`

### Step 6: Start Frontend Service

```bash
# Enter frontend directory
cd ruoyi-ui

# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend service will start at `http://localhost:80`

## Verify Startup

1. **Backend Verification**: Visit `http://localhost:8080`, seeing Swagger documentation page indicates successful backend startup
2. **Frontend Verification**: Visit `http://localhost:80`, seeing login page indicates successful frontend startup

## Default Account

- **Admin Account**: admin
- **Admin Password**: admin123

## Common Issues Troubleshooting

### 1. Database Connection Failed
- Confirm MySQL service is started
- Check database connection configuration
- Confirm database `ruoyi-vue3-data` is created
- Confirm initialization SQL scripts are executed

### 2. Redis Connection Failed
- Confirm Redis service is started
- Check Redis connection configuration
- Confirm Redis password is set correctly

### 3. Frontend Startup Failed
- Confirm Node.js version meets requirements
- Delete `node_modules` and `package-lock.json`, re-execute `npm install`
- Check if port 80 is occupied

### 4. Backend Startup Failed
- Confirm Java version is 1.8+
- Check Maven dependencies are downloaded correctly
- View log files to troubleshoot specific errors

## Quick Start Command Summary

```bash
# 1. Start basic services (Docker)
cd mysql-env && docker-compose up -d
cd ../redis-dev && docker-compose up -d

# 2. Start backend
cd ../..
mvn clean install
cd ruoyi-admin && mvn spring-boot:run

# 3. Start frontend (open new terminal)
cd ruoyi-ui
npm install
npm run dev
```

## Project Structure

```
ruoyi-light-quick/
ruoyi-admin/          # Admin backend module (startup entry)
ruoyi-common/         # Common utility module
ruoyi-framework/      # Framework core module
ruoyi-generator/      # Code generation module
ruoyi-quartz/         # Scheduled task module
ruoyi-system/         # System management module
ruoyi-ui/             # Frontend Vue project
sql/                  # Database initialization scripts
mysql-env/            # MySQL Docker configuration
redis-dev/            # Redis Docker configuration
```

## Next Steps

After successful startup, you can:
1. Browse system functional modules
2. View API documentation (`http://localhost:8080/swagger-ui/`)
3. Start custom development
4. Refer to official documentation for more features

## Technical Stack Details

### Backend Stack
- **Framework**: Spring Boot 2.5.15
- **Security**: Spring Security 5.7.14
- **Database**: MySQL 8.0 with Druid connection pool
- **Cache**: Redis 7
- **ORM**: MyBatis with PageHelper pagination
- **Build Tool**: Maven
- **Java Version**: 1.8

### Frontend Stack
- **Framework**: Vue 2.6.12
- **UI Library**: Element UI 2.15.14
- **Build Tool**: Vue CLI 4.4.6
- **HTTP Client**: Axios 0.28.1
- **State Management**: Vuex 3.6.0
- **Routing**: Vue Router 3.4.9

### Additional Features
- **API Documentation**: Swagger 3.0
- **Authentication**: JWT Token
- **Scheduled Tasks**: Quartz
- **Code Generation**: Built-in code generator
- **File Upload**: Support for multiple file formats
- **Excel Export**: Apache POI integration