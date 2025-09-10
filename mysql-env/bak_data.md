你问的是：**如何导出容器里的数据（以上面的 MySQL 容器为例）？**

这是一个非常实用的问题 —— 无论你是想 **备份数据、迁移环境、共享数据库状态**，还是 **防止误删后能恢复**，都需要掌握“导出容器数据”的方法。

---

## 🎯 场景说明（基于你上面的 MySQL 容器）

你有一个正在运行的 MySQL 容器：

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: dev-mysql-8.0
    volumes:
      - mysql_/var/lib/mysql  # 👈 数据持久化在这里
```

你想：

✅ 导出数据库结构 + 数据（SQL 文件）  
✅ 或导出原始数据文件（用于直接复制恢复）  
✅ 或只导出某个表、某个库

---

# ✅ 方法一：使用 `mysqldump` 导出 SQL 文件（推荐！）

这是最标准、最通用、最安全的方式 —— 生成 `.sql` 文件，可在任何 MySQL 环境导入。

---

### 1️⃣ 在宿主机执行命令（无需进入容器）

```bash
docker exec dev-mysql-8.0 \
  mysqldump -u devuser -p123456 --databases myapp_dev > backup_$(date +%Y%m%d).sql
```

> 💡 说明：
> - `dev-mysql-8.0`：你的容器名
> - `-u devuser -p123456`：用户名和密码（你配置的）
> - `--databases myapp_dev`：指定要导出的数据库
> - `> backup_xxxx.sql`：导出到宿主机当前目录

✅ 执行后你会在当前目录得到类似：`backup_20250405.sql`

---

### 2️⃣ 导出所有数据库（包括系统库）

```bash
docker exec dev-mysql-8.0 \
  mysqldump -u root -p123456 --all-databases > full_backup.sql
```

---

### 3️⃣ 只导出某个表

```bash
docker exec dev-mysql-8.0 \
  mysqldump -u devuser -p123456 myapp_dev users > users_table.sql
```

> `users` 是表名

---

### 4️⃣ 导出时不包含 DROP / CREATE（只导数据）

```bash
docker exec dev-mysql-8.0 \
  mysqldump -u devuser -p123456 myapp_dev --no-create-info > data_only.sql
```

---

## ✅ 方法二：直接复制容器内数据目录（原始文件备份）

你的 `docker-compose.yml` 中挂载了命名卷：

```yaml
volumes:
  - mysql_/var/lib/mysql
```

你可以直接备份这个卷的数据文件（适用于完整物理备份，恢复快，但只能用于相同 MySQL 版本）。

---

### 1️⃣ 查看卷名

```bash
docker volume ls
```

输出类似：

```
DRIVER    VOLUME NAME
local     your-project_mysql_data
```

---

### 2️⃣ 备份整个卷（复制到宿主机）

```bash
# 创建备份目录
mkdir -p ./mysql-backup

# 使用临时容器挂载卷并复制数据
docker run --rm \
  -v your-project_mysql_data:/source \
  -v $(pwd)/mysql-backup:/backup \
  alpine tar czf /backup/mysql_data.tar.gz -C /source .
```

✅ 你会得到：`./mysql-backup/mysql_data.tar.gz`

---

### 3️⃣ 恢复数据（还原卷）

```bash
# 删除旧容器和卷（⚠️ 谨慎操作！）
docker compose down -v

# 重新创建卷（空的）
docker volume create your-project_mysql_data

# 解压备份到卷
docker run --rm \
  -v your-project_mysql_data:/target \
  -v $(pwd)/mysql-backup:/backup \
  alpine tar xzf /backup/mysql_data.tar.gz -C /target

# 重新启动服务
docker compose up -d
```

> ⚠️ 注意：物理备份要求 MySQL 版本一致，否则可能无法启动！

---

## ✅ 方法三：进入容器手动导出（适合调试）

```bash
# 进入容器
docker exec -it dev-mysql-8.0 bash

# 在容器内执行导出（文件会保存在容器内）
mysqldump -u devuser -p123456 myapp_dev > /tmp/backup.sql

# 退出容器后，从容器复制到宿主机
docker cp dev-mysql-8.0:/tmp/backup.sql ./backup.sql
```

---

## 📁 推荐项目结构

建议你项目目录结构如下，便于管理：

```
your-project/
├── docker-compose.yml
├── mysql-init/             # 初始化脚本
│   └── init-user.sql
├── mysql-backup/           # 存放导出的 SQL 或 tar.gz
│   ├── backup_20250405.sql
│   └── mysql_data.tar.gz
└── README.md
```

---

## 🔄 如何导入（恢复）数据？

### ➤ 导入 SQL 文件

```bash
# 方法1：通过 docker exec
docker exec -i dev-mysql-8.0 mysql -u devuser -p123456 myapp_dev < backup.sql

# 方法2：进入容器导入
docker exec -it dev-mysql-8.0 bash
mysql -u devuser -p123456 myapp_dev < /tmp/backup.sql
```

---

## 🧰 自动化脚本建议（bonus）

创建 `backup.sh`：

```bash
#!/bin/bash
BACKUP_DIR="./mysql-backup"
mkdir -p $BACKUP_DIR
FILENAME="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"

docker exec dev-mysql-8.0 mysqldump -u devuser -p123456 --databases myapp_dev > $FILENAME

echo "✅ Backup saved to: $FILENAME"
```

赋予执行权限：

```bash
chmod +x backup.sh
./backup.sh
```

---

## ✅ 总结对比

| 方法 | 用途 | 优点 | 缺点 |
|------|------|------|------|
| `mysqldump` 导出 SQL | 逻辑备份，通用迁移 | ✅ 可读、可编辑、跨版本兼容 | ❌ 大库慢，不能热备（需锁表） |
| 复制数据卷文件 | 物理备份，快速恢复 | ✅ 速度快，适合大库 | ❌ 必须同版本 MySQL，不能跨平台 |
| 进入容器导出 | 临时调试用 | ✅ 灵活 | ❌ 麻烦，不适合自动化 |

---

## 🎁 额外提示

- **定期备份**：可配合 `crontab` 定时执行 `backup.sh`
- **版本控制**：重要结构变更的 `.sql` 可提交到 Git
- **敏感数据脱敏**：生产数据导出前记得脱敏！

---

✅ 现在你已经掌握了如何导出容器内 MySQL 数据，无论是开发调试、团队共享、灾难恢复，都能轻松应对！

如需导出 Redis、PostgreSQL、Kafka 数据，也可以告诉我，我一并教你 👍
