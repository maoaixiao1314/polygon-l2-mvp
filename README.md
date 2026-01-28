# 🚀 Polygon L2 MVP 部署

## 📁 文件结构

```
polygon-l2-mvp/
├── MVP_DEPLOYMENT_GUIDE.md      # 📖 详细部署指南
├── README.md                    # 📝 本文件（快速开始）
├── .env.example                 # 🔧 环境变量模板
├── docker-compose.yml           # 🐳 Docker 配置
├── config/
│   ├── node-config.toml         # ⚙️ 节点配置（MVP 优化）
│   ├── prover-config.json       # ⚙️ Prover 配置
│   └── genesis.json             # 🌱 创世配置（需要生成）
├── scripts/
│   └── deploy-mvp.sh            # 🚀 一键部署脚本
└── data/                        # 💾 数据目录（自动创建）
```

---

## ⚡ 快速开始（5 分钟）

### 1. 配置环境变量

```bash
# 复制模板
cp .env.example .env

# 编辑配置
vim .env

# 填写以下内容：
# - L1_RPC_URL: 你的 atoshi-chain RPC
# - DEPLOYER_PRIVATE_KEY: 部署者私钥
# - SEQUENCER_PRIVATE_KEY: Sequencer 私钥
# - AGGREGATOR_PRIVATE_KEY: Aggregator 私钥
```

### 2. 一键部署

```bash
# 给脚本执行权限
chmod +x scripts/deploy-mvp.sh

# 运行部署
./scripts/deploy-mvp.sh
```

### 3. 验证部署

```bash
# 测试 RPC
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

---

## 💻 服务器要求

### 推荐配置（舒适）

```
CPU:     16 核
内存:    64 GB
硬盘:    500 GB SSD
带宽:    100 Mbps
系统:    Ubuntu 22.04 LTS

成本:    约 $500/月
```

### 最低配置（紧张）

```
CPU:     8 核
内存:    32 GB
硬盘:    250 GB SSD
带宽:    50 Mbps
系统:    Ubuntu 22.04 LTS

成本:    约 $250/月
```

---

## 📊 MVP vs 生产环境

| 项目 | MVP | 生产环境 |
|------|-----|---------|
| **服务器** | 1 台 | 5 台 |
| **Prover** | 8核 16GB | 32核 256GB |
| **成本** | $250-500/月 | $3,000-6,750/月 |
| **TPS** | 10-50 | 1000+ |
| **证明时间** | 2-5 分钟 | 30-60 秒 |

---

## 🔧 常用命令

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 查看日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f zkevm-sequencer

# 查看资源使用
docker stats

# 清理数据（危险！）
docker compose down -v
rm -rf data/
```

---

## 📝 下一步

### 1. 部署隐私合约

```bash
cd /path/to/atoshi-privacy-contracts

# 修改 hardhat.config.js
# 添加 mvpL2 网络配置

# 部署
npx hardhat run scripts/deploy.js --network mvpL2
```

### 2. 更新 SDK

```typescript
const config = {
  l2RpcUrl: 'http://YOUR_SERVER_IP:8545',
  l2ChainId: 67890,
  shieldContract: '0x...',  // 部署后的地址
};
```

### 3. 测试

```bash
npm run test:e2e
```

---

## ⚠️ 重要提示

### MVP 限制

- ✅ 适合：测试、演示、开发
- ❌ 不适合：生产环境、高并发

### 升级到生产

当满足以下条件时升级：
- [ ] 日交易量 > 1,000 笔
- [ ] 用户数 > 100
- [ ] 需要 99.9% 可用性

---

## 📞 获取帮助

- **详细文档**: `cat MVP_DEPLOYMENT_GUIDE.md`
- **Polygon 文档**: https://docs.polygon.technology/zkEVM/
- **Discord**: https://discord.gg/polygon

---

## ✅ 检查清单

### 部署前
- [ ] 准备服务器（16核 64GB 推荐）
- [ ] 安装 Docker 和 Docker Compose
- [ ] 配置 .env 文件
- [ ] 准备账户私钥

### 部署后
- [ ] 服务全部启动
- [ ] RPC 可访问
- [ ] 可以查询区块
- [ ] 可以提交交易

---

## 🎉 成功！

如果你看到这个，说明 MVP 已经部署成功！

**下一步**: 部署隐私合约并开始测试隐私交易。

查看详细指南: `cat MVP_DEPLOYMENT_GUIDE.md`

