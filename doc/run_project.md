# 运行后端项目

你遇到的错误：

```
[ERROR] No plugin found for prefix 'spring-boot' in the current project and in the plugin groups [...]
```

说明 Maven **找不到 `spring-boot` 插件的前缀映射**，也就是说，它不知道 `spring-boot:run` 这个命令对应的是哪个插件。

---

## ❗ 根本原因

在你的根 `pom.xml` 中，**没有声明 `spring-boot-maven-plugin`，也没有在 `<pluginManagement>` 或 `<build><plugins>` 中配置它**，同时子模块 `ruoyi-admin` 的 `pom.xml` 可能也没有正确继承或声明该插件。

Maven 的 `spring-boot:run` 是一个“目标前缀（goal prefix）”，它需要插件在 `pom.xml` 中被声明或在本地仓库中有缓存的元数据（metadata），否则 Maven 无法解析。

虽然你配置了阿里云和中央仓库，但插件元数据下载成功 ≠ 插件本身被项目声明。

---

## ✅ 解决方案

### ✅ 方法一：进入 `ruoyi-admin` 目录单独运行（最简单可靠）

因为 `ruoyi-admin` 是真正的 Spring Boot 启动模块，它的 `pom.xml` 里**应该**配置了 `spring-boot-maven-plugin`。

运行这个成功
```bash
cd ruoyi-admin
mvn spring-boot:run -DskipTests
```

> ⚠️ 如果提示找不到依赖（如 `ruoyi-common`），请先回到根目录执行：
> ```bash
> mvn clean install -DskipTests
> ```
> 然后再进入 `ruoyi-admin` 运行。

---

### ✅ 方法二：在根目录强制指定插件的完整 GAV（Group-Artifact-Version）

在根目录执行：

```bash
mvn org.springframework.boot:spring-boot-maven-plugin:2.5.15:run -pl ruoyi-admin -am -DskipTests
```

> 🔢 注意：`2.5.15` 是你 `pom.xml` 中定义的 `${spring-boot.version}`，请确保版本一致。

这个命令直接指定了插件的完整坐标，绕过了“前缀解析”问题。

---

### ✅ 方法三：修复根 POM 或 ruoyi-admin POM（一劳永逸）

#### 步骤 1：检查 `ruoyi-admin/pom.xml`

打开 `ruoyi-admin/pom.xml`，确认里面有类似配置：

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <version>${spring-boot.version}</version>
            <executions>
                <execution>
                    <goals>
                        <goal>repackage</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

如果没有，请**手动添加**。

#### 步骤 2（可选）：在根 POM 的 `<pluginManagement>` 中声明插件

在根 `pom.xml` 的 `<build>` 标签下添加：

```xml
<build>
    <pluginManagement>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <version>${spring-boot.version}</version>
            </plugin>
        </plugins>
    </pluginManagement>
</build>
```

这样所有子模块都可以继承这个插件配置。

---

## 🌐 关于阿里云仓库报错的补充说明

你看到的日志：

```
Downloading from public: https://maven.aliyun.com/repository/public/...
```

虽然能下载 `maven-metadata.xml`，但**阿里云仓库目前对某些请求返回错误页面**（如你知识库中的 "Sorry for the inconvenience"），这可能导致插件下载不稳定。

### 🛠️ 建议：临时替换为华为云镜像

编辑你的 `~/.m2/settings.xml`（或项目根目录下的 `pom.xml`），添加或替换仓库：

```xml
<repositories>
    <repository>
        <id>huaweicloud</id>
        <name>Huawei Cloud</name>
        <url>https://repo.huaweicloud.com/repository/maven/</url>
        <releases><enabled>true</enabled></releases>
        <snapshots><enabled>false</enabled></snapshots>
    </repository>
</repositories>

<pluginRepositories>
    <pluginRepository>
        <id>huaweicloud</id>
        <name>Huawei Cloud</name>
        <url>https://repo.huaweicloud.com/repository/maven/</url>
        <releases><enabled>true</enabled></releases>
        <snapshots><enabled>false</enabled></snapshots>
    </pluginRepository>
</pluginRepositories>
```

然后删除本地仓库中可能损坏的缓存：

```bash
rm -rf ~/.m2/repository/org/springframework/boot/spring-boot-maven-plugin/
```

再重新运行命令。

---

## 🚀 推荐操作流程（一步到位）

```bash
# 1. 进入项目根目录
cd ~/github_projects/java_project/RuoYi-Vue

# 2. 清理并安装所有模块到本地仓库（跳过测试）
mvn clean install -DskipTests

# 3. 进入 admin 模块启动（最稳定方式）
cd ruoyi-admin
mvn spring-boot:run -DskipTests
```

---

## ✅ 总结

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| `No plugin found for prefix 'spring-boot'` | 项目未声明 `spring-boot-maven-plugin` 插件 | 1. 进入 `ruoyi-admin` 目录运行<br>2. 使用完整 GAV 命令<br>3. 在 POM 中添加插件声明 |
| 阿里云仓库不稳定 | 返回错误页面，影响依赖下载 | 替换为华为云镜像 |

---

你现在就可以执行：

```bash
cd ruoyi-admin && mvn spring-boot:run -DskipTests
```

不出意外，项目就能成功启动了！🎉