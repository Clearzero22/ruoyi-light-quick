-- 设置 root 用户（可选，如需要）
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '123456';

-- 设置普通用户 devuser（推荐）
ALTER USER 'devuser'@'%' IDENTIFIED WITH mysql_native_password BY '123456';

-- 刷新权限
FLUSH PRIVILEGES;

-- 可选：验证是否修改成功（日志中可查看）
SELECT user, host, plugin FROM mysql.user WHERE user IN ('root', 'devuser');
