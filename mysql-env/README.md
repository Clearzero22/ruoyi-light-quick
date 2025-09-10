你希望在 **MySQL 容器首次启动时自动配置好用户认证方式为 `mysql_native_password`**，避免后续连接报错 `Public Key Retrieval is not allowed`。

✅ **最佳实践**：利用 MySQL 官方镜像的 **初始化脚本机制** —— 任何放在 `/docker-entrypoint-initdb.d/` 目录下的 `.sql`, `.sql.gz`, `.sh` 文件，都会在数据库初始化时（即首次启动、`/var/lib/mysql` 为空时）自动执行。

---

## ✅ 最终目标

启动容器 → 自动创建数据库、用户 → 并设置用户使用 `mysql_native_password` 插件 → 一劳永逸解决连接问题。

---

## 🛠️ 实现步骤

### 1️⃣ 创建初始化 SQL 脚本

在你的项目目录下创建文件：

```bash
mkdir -p ./mysql-init
touch ./mysql-init/init-user.sql
```

编辑 `./mysql-init/init-user.sql`：

```sql
-- 设置 root 用户（可选，如需要）
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '123456';

-- 设置普通用户 devuser（推荐）
ALTER USER 'devuser'@'%' IDENTIFIED WITH mysql_native_password BY '123456';

-- 刷新权限
FLUSH PRIVILEGES;

-- 可选：验证是否修改成功（日志中可查看）
SELECT user, host, plugin FROM mysql.user WHERE user IN ('root', 'devuser');
```

> 💡 注意：`'devuser'@'%'` 中的 `%` 表示允许任意主机连接（开发环境 OK，生产环境应限制 IP）。

---

### 2️⃣ 修改 `docker-compose.yml`，挂载初始化脚本

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: dev-mysql-8.0
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: myapp_dev
      MYSQL_USER: devuser
      MYSQL_PASSWORD: 123456
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql-init:/docker-entrypoint-initdb.d  # 👈 挂载初始化目录
    restart: unless-stopped

volumes:
  mysql_data:
```

---

## 🚀 启动 & 验证

### 第一次启动（会执行初始化脚本）

```bash
# 停止并删除旧容器和卷（⚠️ 数据会丢失！仅首次或重置时执行）
docker compose down -v

# 启动
docker compose up -d

# 查看日志，确认脚本执行
docker compose logs mysql
```

你应该在日志中看到类似：

```
... init-user.sql ...
... Query OK, 0 rows affected ...
... SELECT user, host, plugin ...
```

### 验证用户插件是否修改成功

进入容器：

```bash
docker exec -it dev-mysql-8.0 mysql -u root -p
# 输入密码：123456
```

执行：

```sql
SELECT user, host, plugin FROM mysql.user WHERE user = 'devuser';
```

✅ 期望输出：

```
+---------+------+-----------------------+
| user    | host | plugin                |
+---------+------+-----------------------+
| devuser | %    | mysql_native_password |
+---------+------+-----------------------+
```

---

## 🔄 后续启动

- 只要 `mysql_data` 卷存在（即不是首次启动），`/docker-entrypoint-initdb.d` 中的脚本**不会再次执行**，所以不会重复修改或报错。
- 数据和配置都会持久化保留。

---

## ✅ 优势总结

| 方案 | 优点 |
|------|------|
| 挂载初始化脚本 | ✅ 自动化配置，无需手动登录 MySQL<br>✅ 适合团队共享、CI/CD、一键部署<br>✅ 只在首次执行，安全无副作用 |

---

## 💡 额外建议（可选）

### 设置时区（避免 Java 时区警告）

在 `environment` 中添加：

```yaml
environment:
  TZ: Asia/Shanghai
  MYSQL_ROOT_PASSWORD: 123456
  MYSQL_DATABASE: myapp_dev
  MYSQL_USER: devuser
  MYSQL_PASSWORD: 123456
```

### 自定义 MySQL 配置（如解决 ONLY_FULL_GROUP_BY 等）

创建 `./mysql-init/custom.cnf`：

```ini
[mysqld]
sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
default-time-zone='+8:00'
```

然后挂载：

```yaml
volumes:
  - mysql_data:/var/lib/mysql
  - ./mysql-init:/docker-entrypoint-initdb.d
  - ./mysql-init/custom.cnf:/etc/mysql/conf.d/custom.cnf
```

---

## 🧹 重置环境（如需重新初始化）

```bash
docker compose down -v   # 删除容器 + 卷
docker compose up -d     # 重新创建，触发初始化脚本
```

---

✅ 现在你的 MySQL 容器在启动时就会自动配置好兼容性更强的认证方式，Spring Boot、DBeaver、Navicat 等客户端都能直接连接，无需再手动处理 `Public Key Retrieval is not allowed`！

如有其他中间件（Redis/Kafka/PostgreSQL）也需要初始化脚本，我也可以帮你配置 👍
