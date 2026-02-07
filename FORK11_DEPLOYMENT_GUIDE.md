# Polygon zkEVM Fork ID 11 部署指南

## 📋 概述

本指南将帮助你使用 **Fork ID 11** 重新部署 Polygon zkEVM L1 合约和 L2 节点。

**为什么使用 Fork 11？**
- ✅ hermeznetwork/zkevm-node 最高支持到 Fork 11
- ✅ Fork 11 已经成熟稳定
- ✅ 有官方 Docker 镜像：`hermeznetwork/zkevm-node:v0.7.0-fork11`
- ✅ 对隐私合约功能没有影响

---

## 🚀 部署步骤

### 步骤 1：准备环境变量

在云服务器上设置：

```bash
# 部署者私钥（确保有足够的 ETH）
export DEPLOYER_PRIVATE_KEY="your_private_key_here"

# L1 RPC URL（默认使用 atoshi-chain）
export L1_RPC_URL="http://54.169.30.130:8545"
```

**检查余额：**
```bash
cast wallet address --private-key "$DEPLOYER_PRIVATE_KEY"
cast balance $(cast wallet address --private-key "$DEPLOYER_PRIVATE_KEY") --rpc-url "$L1_RPC_URL"
```

确保至少有 **1 ETH** 用于部署。

---

### 步骤 2：运行 L1 部署脚本

```bash
cd ~/polygon-l2-mvp

# 添加执行权限
chmod +x deploy-l1-fork11.sh

# 运行部署脚本
./deploy-l1-fork11.sh
```

**部署过程：**
1. 克隆 `zkevm-contracts v7.0.0-fork.11`
2. 安装依赖
3. 生成随机 salt
4. 创建部署参数（fork ID 11）
5. 部署所有 L1 合约（5-10 分钟）
6. 保存部署输出到 `l1-deployment-output-fork11.json`

---

### 步骤 3：生成 genesis.json

部署完成后，使用部署输出生成 genesis.json：

```bash
cd ~/polygon-l1-deployment-fork11/zkevm-contracts

# 生成 genesis.json
npm run gen:genesis

# 复制到 polygon-l2-mvp
cp deployment/v2/genesis.json ~/polygon-l2-mvp/config/genesis.json
```

**验证 genesis.json：**
```bash
cat ~/polygon-l2-mvp/config/genesis.json | jq '.l1Config'
```

应该看到：
- `polygonZkEVMAddress`
- `polygonRollupManagerAddress`
- `maticTokenAddress`
- `polygonZkEVMGlobalExitRootAddress`

---

### 步骤 4：更新并启动 L2 节点

```bash
cd ~/polygon-l2-mvp

# 拉取最新配置（包含 fork11 镜像）
git pull origin main

# 停止旧服务
docker compose down

# 清理旧数据（重要！）
sudo rm -rf data/postgres/*

# 拉取新镜像
docker compose pull

# 启动服务
docker compose up -d

# 等待 60 秒
sleep 60

# 检查状态
docker compose ps

# 查看日志
docker compose logs zkevm-sync --tail 50
docker compose logs zkevm-sequencer --tail 50
```

---

## 🔍 验证部署

### 1. 检查 L2 节点状态

```bash
# 所有服务应该是 Up 状态
docker compose ps

# Sync 应该没有 "fork" 相关错误
docker compose logs zkevm-sync --tail 20 | grep -i "fork\|error\|fatal"

# Sequencer 应该在等待同步完成
docker compose logs zkevm-sequencer --tail 20 | grep -i "sync\|error\|fatal"
```

### 2. 测试 L2 RPC

```bash
# 检查 L2 RPC 是否响应
curl -X POST http://54.169.30.130:8547 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 检查 chain ID
curl -X POST http://54.169.30.130:8547 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

应该返回 `0x3e9`（1001）。

---

## 📊 部署参数对比

| 参数 | Fork 12 (旧) | Fork 11 (新) |
|------|-------------|-------------|
| zkevm-contracts | v8.0.0-fork.12 | v7.0.0-fork.11 |
| zkevm-node | ❌ 不支持 | ✅ v0.7.0-fork11 |
| Docker 镜像 | 无 | hermeznetwork/zkevm-node:v0.7.0-fork11 |
| 稳定性 | 未知 | ✅ 成熟稳定 |

---

## 🐛 常见问题

### Q1: 部署脚本报错 "insufficient funds"

**解决：** 确保部署者地址有足够的 ETH：
```bash
cast balance $(cast wallet address --private-key "$DEPLOYER_PRIVATE_KEY") --rpc-url "$L1_RPC_URL"
```

### Q2: npm install 失败

**解决：** 检查 Node.js 版本：
```bash
node --version  # 应该是 v16 或更高
npm --version
```

### Q3: Sync 还是报 fork 错误

**解决：** 确认镜像版本：
```bash
docker compose ps | grep zkevm-sync
# 应该显示 hermeznetwork/zkevm-node:v0.7.0-fork11
```

### Q4: genesis.json 生成失败

**解决：** 手动运行：
```bash
cd ~/polygon-l1-deployment-fork11/zkevm-contracts
npx hardhat run deployment/v2/3_createGenesis.ts --network goerli
```

---

## 📝 重要文件位置

| 文件 | 位置 |
|------|------|
| L1 部署脚本 | `~/polygon-l2-mvp/deploy-l1-fork11.sh` |
| L1 部署输出 | `~/polygon-l2-mvp/l1-deployment-output-fork11.json` |
| L1 合约源码 | `~/polygon-l1-deployment-fork11/zkevm-contracts/` |
| genesis.json | `~/polygon-l2-mvp/config/genesis.json` |
| docker-compose.yml | `~/polygon-l2-mvp/docker-compose.yml` |

---

## 🎯 下一步

部署成功后：

1. ✅ **部署隐私合约到 L2**
   ```bash
   # L2 RPC: http://54.169.30.130:8547
   # Chain ID: 1001
   ```

2. ✅ **配置 L2 Blockscout**
   - 端口：81
   - 数据库端口：7434

3. ✅ **测试 L1 ↔ L2 桥接**
   - Bridge 合约地址在 `l1-deployment-output-fork11.json`

---

## 📞 需要帮助？

如果遇到问题：
1. 检查日志：`docker compose logs -f`
2. 查看部署输出：`cat l1-deployment-output-fork11.json`
3. 验证 genesis.json：`cat config/genesis.json | jq`

**祝部署顺利！🚀**

