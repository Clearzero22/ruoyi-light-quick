当然可以！以下是基于你前面 MySQL 的风格，为你编写的 **Redis 开发环境 `docker-compose.yml` 配置**，包含：

✅ 持久化数据卷  
✅ 自定义容器名  
✅ 端口映射（宿主机 6379）  
✅ 密码设置（可选）  
✅ 启动时自动加载配置（如需要）  
✅ 重启策略  
✅ 兼容新版 Docker Compose（无 `version` 字段）

---

## ✅ Redis `docker-compose.yml` 完整配置

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: dev-redis-7
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data                # 持久化数据（RDB/AOF）
      - ./redis.conf:/usr/local/etc/redis/redis.conf:ro  # 自定义配置（可选）
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]  # 使用自定义配置启动
    environment:
      - REDIS_PASSWORD=your_redis_password  # 设置密码（可选）
    restart: unless-stopped

volumes:
  redis_data:
```

---

## 📁 项目结构建议

```
redis-env/
├── docker-compose.yml
├── redis.conf             # Redis 配置文件（可选）
└── README.md
```

---

## 🔧 可选：创建自定义 `redis.conf`

如果你需要自定义配置（比如开启 AOF、设置最大内存、绑定 IP 等），创建 `./redis.conf`：

```bash
touch ./redis.conf
```

内容示例（开发环境推荐）：

```ini
# redis.conf

# 绑定所有 IP（允许远程连接，开发用）
bind 0.0.0.0

# 关闭保护模式（配合密码使用）
protected-mode no

# 设置端口
port 6379

# 设置密码（取消注释并修改）
requirepass your_redis_password

# 持久化：每秒保存一次（兼顾性能与安全）
save 900 1
save 300 10
save 60 10000

# 开启 AOF（更安全，推荐开发开启）
appendonly yes
appendfsync everysec

# 最大内存（可选，防止吃满内存）
# maxmemory 256mb
# maxmemory-policy allkeys-lru

# 数据目录（默认 /data，已挂载卷）
dir /data
```

> ⚠️ 如果你不想设密码或自定义配置，可以删掉 `volumes` 中挂载 `redis.conf` 的那行，以及 `command` 和 `environment`。

---

## 🚀 启动 Redis

```bash
docker compose up -d
```

---

## 🔍 连接测试

### 1. 使用 `redis-cli` 连接（带密码）

```bash
redis-cli -h 127.0.0.1 -p 6379 -a your_redis_password
```

或进入后认证：

```bash
redis-cli
> AUTH your_redis_password
> PING
PONG
```

### 2. 不设密码（开发快速测试）

如果你不想设密码，从配置中删除：

- `environment: REDIS_PASSWORD=...`
- `requirepass ...`（在 redis.conf 中）
- `protected-mode no` 可改为 `yes`

然后直接连接：

```bash
redis-cli
> PING
PONG
```

---

## 💾 数据持久化说明

- Redis 默认使用 **RDB 快照**（你配置了 `save` 规则）
- 你挂载了 `redis_/data`，所以：
  - RDB 文件 `dump.rdb`
  - AOF 文件 `appendonly.aof`（如果开启）
  - 都会保存在 Docker 卷中，容器删除也不丢失

---

## 🧹 备份 Redis 数据

### 方法一：复制卷文件（物理备份）

```bash
# 查看卷名
docker volume ls

# 备份（假设卷名为 yourproject_redis_data）
docker run --rm \
  -v yourproject_redis_/source \
  -v $(pwd)/redis-backup:/backup \
  alpine tar czf /backup/redis_data.tar.gz -C /source .
```

### 方法二：使用 `SAVE` 或 `BGSAVE` 命令（逻辑触发持久化）

```bash
redis-cli -a your_redis_password BGSAVE
```

然后去卷里复制 `dump.rdb` 文件即可。

---

## 📌 无配置简化版（适合快速开发）

如果你只是临时用，不需要配置文件和密码：

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: dev-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_/data
    restart: unless-stopped

volumes:
  redis_
```

一行命令启动：

```bash
docker compose up -d
```

---

## ✅ 总结

| 功能 | 是否支持 |
|------|----------|
| 数据持久化 | ✅ 通过 `redis_/data` 卷 |
| 自定义配置 | ✅ 挂载 `redis.conf` |
| 密码保护 | ✅ 通过 `requirepass` + `REDIS_PASSWORD` |
| 远程连接 | ✅ `bind 0.0.0.0` + `protected-mode no` |
| 自动重启 | ✅ `unless-stopped` |
| 兼容新 Compose | ✅ 无 `version` 字段 |

---

✅ 现在你可以一键启动一个功能完整、可持久化、安全可控的 Redis 开发环境！

如需和 MySQL、PostgreSQL、Kafka 一起编排，只需把 `redis` 服务加到你之前的 `docker-compose.yml` 里即可 👍

需要我帮你整合成完整多服务环境，也可以告诉我！
