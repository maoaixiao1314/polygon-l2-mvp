# .env 文件使用说明

## ⚠️ 重要提示

**`.env` 文件包含敏感信息（私钥、密码），永远不要提交到 Git！**

---

## 快速开始

### 1. 创建 .env 文件

```bash
cd ~/atoshi/polygon-l2-mvp

# 复制模板
cp env.template .env

# 编辑配置
vim .env
```

### 2. 必填配置项

```bash
# L1 配置
L1_RPC_URL=http://YOUR_SERVER_IP:8545
L1_CHAIN_ID=88388

# L2 配置
L2_CHAIN_ID=67890
L2_RPC_PORT=8547
L2_WS_PORT=8548

# 账户私钥 (⚠️ 敏感信息)
DEPLOYER_PRIVATE_KEY=0x...
SEQUENCER_PRIVATE_KEY=0x...
AGGREGATOR_PRIVATE_KEY=0x...

# 数据库密码 (⚠️ 敏感信息)
POSTGRES_PASSWORD=your_strong_password
```

### 3. 验证配置

```bash
# 检查 .env 文件是否存在
ls -la .env

# 检查 .env 是否在 .gitignore 中
grep ".env" .gitignore

# 确认 .env 不会被 Git 追踪
git status
# 应该看不到 .env 文件
```

---

## Git 管理策略

### ✅ 应该提交到 Git

- `env.template` - 配置模板（不含敏感信息）
- `.gitignore` - 忽略规则
- `README.md` - 文档

### ❌ 不应该提交到 Git

- `.env` - 实际配置（包含敏感信息）
- `*.keystore` - 私钥文件
- `data/` - 数据目录

---

## 多环境配置

### 开发环境

```bash
# .env.development
L1_RPC_URL=http://localhost:8545
DEBUG_MODE=true
LOG_LEVEL=debug
```

### 生产环境

```bash
# .env.production
L1_RPC_URL=http://YOUR_PRODUCTION_IP:8545
DEBUG_MODE=false
LOG_LEVEL=info
POSTGRES_PASSWORD=very_strong_password_here
```

### 使用不同环境

```bash
# 开发环境
cp .env.development .env
docker compose up -d

# 生产环境
cp .env.production .env
docker compose up -d
```

---

## 云服务器更新代码

### 问题：.env 文件冲突

当你在云服务器上创建了 `.env` 文件后，更新代码时可能遇到冲突。

### 解决方案 1: 使用 .gitignore (推荐)

```bash
# 1. 确认 .gitignore 已配置
cat .gitignore | grep ".env"

# 2. 更新代码
git pull

# 3. .env 文件不会被覆盖，因为它不在 Git 中
```

### 解决方案 2: 备份和恢复

```bash
# 更新前备份
cp .env .env.backup

# 更新代码
git pull

# 如果 .env 被覆盖，恢复备份
cp .env.backup .env
```

### 解决方案 3: 使用 git stash

```bash
# 暂存本地更改
git stash

# 更新代码
git pull

# 恢复本地更改
git stash pop
```

---

## 安全最佳实践

### 1. 使用强密码

```bash
# 生成随机密码
openssl rand -base64 32

# 在 .env 中使用
POSTGRES_PASSWORD=生成的随机密码
```

### 2. 限制文件权限

```bash
# 只有所有者可以读写
chmod 600 .env

# 验证权限
ls -l .env
# 应该显示: -rw------- 1 user user
```

### 3. 不要在日志中打印 .env

```bash
# ❌ 错误
cat .env

# ✅ 正确
# 只在需要时查看特定配置
grep "L1_RPC_URL" .env
```

### 4. 定期轮换密钥

```bash
# 每 3-6 个月更换一次
# 1. 生成新私钥
# 2. 更新 .env
# 3. 重启服务
```

---

## 常见问题

### Q1: 我不小心提交了 .env 怎么办？

```bash
# 1. 从 Git 历史中删除
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# 2. 强制推送
git push origin --force --all

# 3. 立即更换所有私钥和密码！
```

### Q2: 如何在团队中共享配置？

```bash
# ❌ 不要直接共享 .env 文件

# ✅ 使用密钥管理工具
# - AWS Secrets Manager
# - HashiCorp Vault
# - 1Password
# - 或通过安全渠道单独发送
```

### Q3: 云服务器上 .env 文件丢失了？

```bash
# 1. 从备份恢复
cp .env.backup .env

# 2. 或从模板重新创建
cp env.template .env
vim .env  # 重新填写配置
```

### Q4: 如何验证 .env 配置正确？

```bash
# 创建验证脚本
cat > verify-env.sh << 'EOF'
#!/bin/bash

echo "验证 .env 配置..."

# 检查文件存在
if [ ! -f .env ]; then
    echo "❌ .env 文件不存在"
    exit 1
fi

# 检查必填项
required_vars=(
    "L1_RPC_URL"
    "L1_CHAIN_ID"
    "L2_CHAIN_ID"
    "DEPLOYER_PRIVATE_KEY"
    "SEQUENCER_PRIVATE_KEY"
    "AGGREGATOR_PRIVATE_KEY"
    "POSTGRES_PASSWORD"
)

for var in "${required_vars[@]}"; do
    if ! grep -q "^${var}=" .env; then
        echo "❌ 缺少配置: $var"
        exit 1
    fi
    
    value=$(grep "^${var}=" .env | cut -d'=' -f2)
    if [ -z "$value" ] || [ "$value" = "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
        echo "❌ $var 未配置或使用默认值"
        exit 1
    fi
done

echo "✅ .env 配置验证通过"
EOF

chmod +x verify-env.sh
./verify-env.sh
```

---

## 配置模板对比

### env.template (提交到 Git)

```bash
# 包含所有配置项
# 使用占位符或默认值
# 包含详细注释
DEPLOYER_PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000000
```

### .env (不提交到 Git)

```bash
# 包含实际配置
# 使用真实的私钥和密码
# 可以删除注释
DEPLOYER_PRIVATE_KEY=0xabcdef1234567890...
```

---

## 更新流程

### 本地开发

```bash
# 1. 更新代码
git pull

# 2. 检查 env.template 是否有新配置项
diff env.template .env

# 3. 如果有新配置，手动添加到 .env
vim .env

# 4. 重启服务
docker compose restart
```

### 云服务器

```bash
# 1. 备份当前配置
cp .env .env.backup.$(date +%Y%m%d)

# 2. 更新代码
cd ~/atoshi/polygon-l2-mvp
git pull

# 3. 对比模板和当前配置
diff env.template .env

# 4. 如果有新配置项，添加到 .env
vim .env

# 5. 验证配置
./verify-env.sh

# 6. 重启服务
docker compose restart
```

---

## 总结

✅ **正确做法:**
- 使用 `env.template` 作为模板
- 创建 `.env` 文件存放实际配置
- 将 `.env` 添加到 `.gitignore`
- 定期备份 `.env` 文件
- 使用强密码和定期轮换

❌ **错误做法:**
- 将 `.env` 提交到 Git
- 在公开渠道分享 `.env`
- 使用弱密码或默认密码
- 不备份 `.env` 文件
- 在日志中打印敏感信息

🔒 **安全提醒:**
- `.env` 文件包含私钥，泄露后果严重
- 定期检查 Git 历史，确保没有误提交
- 使用 `chmod 600 .env` 限制文件权限
- 生产环境使用密钥管理服务

