你问的是：“**配置到那个文件里面**”，结合你的上下文（`data.sql`、`application.yml`、`application-druid.yml`），我来为你详细解答。

---

## ✅ 正确答案：**`application.yml`**

### 🔹 为什么是 `application.yml`？

在 Spring Boot 项目中，**所有核心配置（如数据库、Redis、端口、日志等）都应放在 `application.yml` 文件中**。

你提到的几个文件：

| 文件名 | 用途 | 是否用于主配置 |
|--------|------|----------------|
| `application.yml` ✅ | **主配置文件**，Spring Boot 启动时读取 | ✅ 是，必须放在这里 |
| `application-druid.yml` | Druid 数据库连接池的额外配置（可选） | ❌ 不是主配置，仅补充 |
| `data.sql` | 数据库初始化脚本（非配置） | ❌ 是 SQL 脚本，不是配置 |

---

## 📂 项目结构示例

```
ruoyi-admin
└── src
    └── main
        ├── resources
            ├── application.yml          <-- ✅ 主配置文件
            ├── application-druid.yml    <-- ⚠️ 可选，Druid 配置
            ├── data.sql                 <-- ✅ 数据库初始化脚本
            └── sql/
                  └── init-user.sql      <-- ✅ 可选，其他 SQL 脚本
```

> ✅ 所有需要“配置”的内容（比如数据库地址、端口、密码等）都要写在 `application.yml` 中。

---

## ✅ 如何正确配置数据库？

### 示例：`application.yml` 中配置 MySQL

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/ruoyi-vue3-data?useSSL=false&serverTimezone=UTC&characterEncoding=utf8
    username: devuser
    password: 123456
    driver-class-name: com.mysql.cj.jdbc.Driver

  # 启用 SQL 脚本自动执行（开发时推荐）
  sql:
    init:
      mode: always
      location: classpath:data.sql
```

> ✅ 这样配置后，每次启动应用都会自动执行 `data.sql`。

---

## 🧩 为什么不能只放 `application-druid.yml`？

- `application-druid.yml` 是一个 **profile 特定配置文件**，通常用于激活某个 profile（如 `druid`）。
- 它不会被默认加载，除非你在 `application.yml` 中设置了：
  ```yaml
  spring:
    profiles:
      active: druid
  ```
- 所以，**数据库连接信息仍然要放在 `application.yml` 中**，否则无法连接数据库。

---

## ✅ 总结

| 问题 | 答案 |
|------|------|
| **配置写在哪里？** | ✅ `application.yml` |
| **能不能写在 `application-druid.yml`？** | ❌ 不能，它是辅助配置，不包含主配置 |
| **SQL 脚本放哪里？** | ✅ 放在 `resources/` 目录下，如 `data.sql` |
| **如何让 Spring Boot 自动执行 SQL？** | 在 `application.yml` 中添加 `spring.sql.init.location` |

---

## 🚀 最终建议

将你的数据库配置写入 `application.yml`，例如：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/ruoyi-vue3-data?useSSL=false&serverTimezone=UTC&characterEncoding=utf8
    username: devuser
    password: 123456
    driver-class-name: com.mysql.cj.jdbc.Driver
  sql:
    init:
      mode: always
      location: classpath:data.sql
```

然后运行：

```bash
mvn spring-boot:run
```

✅ 项目启动时会自动连接数据库并执行 `data.sql`！

如有更多配置需求，我可以帮你生成完整的 `application.yml` 模板。