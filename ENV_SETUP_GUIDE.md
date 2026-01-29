# 环境变量配置指南

## 快速开始

```bash
# 1. 复制模板文件
cp env.template .env

# 2. 编辑 .env 文件
vim .env  # 或使用你喜欢的编辑器

# 3. 验证配置
./scripts/validate-env.sh  # (可选)

# 4. 启动部署
./scripts/deploy-mvp.sh
```

---

## 必需配置项

### 1. L1 配置 (atoshi-chain)

```bash
# 你的 atoshi-chain RPC 地址
L1_RPC_URL=http://YOUR_ATOSHI_CHAIN_IP:8545

# 你的 atoshi-chain 链 ID
L1_CHAIN_ID=12345
```

**如何获取:**
- 如果 atoshi-chain 在本地: `http://localhost:8545`
- 如果在远程服务器: `http://服务器IP:8545`
- 链 ID 可以通过 RPC 查询: `curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8545`

---

### 2. L2 配置

```bash
# 自定义 L2 链 ID (不要与 L1 相同)
L2_CHAIN_ID=67890

# L2 网络名称
L2_NETWORK_NAME=Atoshi-L2-MVP
```

**注意:**
- `L2_CHAIN_ID` 必须与 `L1_CHAIN_ID` 不同
- 建议使用 5 位数以上的数字避免冲突

---

### 3. 账户私钥配置 ⚠️

```bash
# 部署者私钥 (需要 L1 上至少 10 ETH)
DEPLOYER_PRIVATE_KEY=0x...

# Sequencer 私钥 (需要 L1 上至少 5 ETH)
SEQUENCER_PRIVATE_KEY=0x...

# Aggregator 私钥 (需要 L1 上至少 5 ETH)
AGGREGATOR_PRIVATE_KEY=0x...
```

**如何生成私钥:**

```bash
# 方法 1: 使用 cast (foundry)
cast wallet new

# 方法 2: 使用 Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# 方法 3: 使用 Python
python3 -c "import secrets; print('0x' + secrets.token_hex(32))"
```

**重要提示:**
1. 这些账户需要在 L1 (atoshi-chain) 上有足够的 ETH 余额
2. 可以使用同一个私钥，但建议分开使用
3. 生产环境请使用 Keystore 文件，不要直接使用私钥
4. 私钥格式必须是 `0x` 开头的 64 位十六进制字符串

**如何给账户充值:**

```bash
# 在 atoshi-chain 上给账户转账
cast send <账户地址> --value 10ether --private-key <你的私钥> --rpc-url http://localhost:8545
```

---

### 4. 数据库配置

```bash
POSTGRES_USER=zkevmuser
POSTGRES_PASSWORD=zkevmpassword  # ⚠️ 请修改为强密码
POSTGRES_DB=zkevmdb
```

**密码建议:**
- 至少 16 位
- 包含大小写字母、数字、特殊字符
- 不要使用默认密码

---

## 可选配置项

### Prover 配置

```bash
# 根据你的服务器 CPU 核心数调整
PROVER_THREADS=4  # 4-8 核适合 MVP
```

**推荐配置:**
- 8 核 CPU: `PROVER_THREADS=4`
- 16 核 CPU: `PROVER_THREADS=8`
- 32 核 CPU: `PROVER_THREADS=16`

---

### Gas 配置

```bash
# L1 Gas Price (Gwei)
L1_GAS_PRICE=20

# L2 Gas Price (Gwei)
L2_GAS_PRICE=1
```

**说明:**
- `L1_GAS_PRICE`: 提交批次到 L1 时使用的 gas price
- `L2_GAS_PRICE`: L2 内部交易的 gas price
- 可以根据网络拥堵情况调整

---

### Sequencer 配置

```bash
# Batch 大小 (交易数)
SEQUENCER_BATCH_SIZE=100

# Batch 超时时间 (秒)
SEQUENCER_BATCH_TIMEOUT=60
```

**说明:**
- `BATCH_SIZE`: 每个批次包含的交易数
- `BATCH_TIMEOUT`: 即使未达到 BATCH_SIZE，超时后也会提交
- MVP 环境建议使用默认值

---

## 配置验证

### 1. 检查 L1 连接

```bash
curl -X POST http://YOUR_L1_RPC:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### 2. 检查账户余额

```bash
# 使用 cast (foundry)
cast balance <账户地址> --rpc-url http://YOUR_L1_RPC:8545

# 或使用 curl
curl -X POST http://YOUR_L1_RPC:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["<账户地址>","latest"],"id":1}'
```

### 3. 验证私钥格式

```bash
# 私钥应该是 66 个字符 (0x + 64 位十六进制)
echo $DEPLOYER_PRIVATE_KEY | wc -c  # 应该输出 67 (包含换行符)
```

---

## 常见问题

### Q1: 私钥格式错误

**错误信息:** `invalid private key format`

**解决方法:**
- 确保私钥以 `0x` 开头
- 确保私钥是 64 位十六进制字符串
- 不要包含空格或换行符

### Q2: 账户余额不足

**错误信息:** `insufficient funds for gas * price + value`

**解决方法:**
- 在 L1 上给账户充值至少 10 ETH
- 检查账户地址是否正确

### Q3: 无法连接 L1

**错误信息:** `connection refused` 或 `timeout`

**解决方法:**
- 检查 `L1_RPC_URL` 是否正确
- 确保 atoshi-chain 节点正在运行
- 检查防火墙设置

### Q4: 数据库连接失败

**错误信息:** `could not connect to database`

**解决方法:**
- 检查 `POSTGRES_PASSWORD` 是否正确
- 确保 Docker 容器正在运行: `docker compose ps`
- 查看数据库日志: `docker compose logs zkevm-db`

---

## 配置示例

### 本地开发环境

```bash
# L1 配置
L1_RPC_URL=http://localhost:8545
L1_CHAIN_ID=12345

# L2 配置
L2_CHAIN_ID=67890

# 账户配置 (测试私钥)
DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
SEQUENCER_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
AGGREGATOR_PRIVATE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# 数据库配置
POSTGRES_USER=zkevmuser
POSTGRES_PASSWORD=zkevmpassword
POSTGRES_DB=zkevmdb

# Prover 配置
PROVER_THREADS=4
```

### 云服务器环境

```bash
# L1 配置
L1_RPC_URL=http://10.0.1.100:8545
L1_CHAIN_ID=12345

# L2 配置
L2_CHAIN_ID=67890

# 账户配置 (使用真实私钥)
DEPLOYER_PRIVATE_KEY=0x[你的私钥]
SEQUENCER_PRIVATE_KEY=0x[你的私钥]
AGGREGATOR_PRIVATE_KEY=0x[你的私钥]

# 数据库配置
POSTGRES_USER=zkevmuser
POSTGRES_PASSWORD=[强密码]
POSTGRES_DB=zkevmdb

# Prover 配置
PROVER_THREADS=8

# Gas 配置
L1_GAS_PRICE=20
L2_GAS_PRICE=1
```

---

## 安全建议

1. **不要提交 .env 文件到 Git**
   - `.env` 文件已在 `.gitignore` 中
   - 只提交 `env.template` 模板文件

2. **使用强密码**
   - 数据库密码至少 16 位
   - 包含大小写字母、数字、特殊字符

3. **保护私钥**
   - 不要在公共场合分享私钥
   - 生产环境使用 Keystore 文件
   - 定期轮换私钥

4. **限制访问**
   - 使用防火墙限制端口访问
   - 只开放必要的端口
   - 使用 VPN 或 SSH 隧道

---

## 下一步

配置完成后，运行部署脚本:

```bash
./scripts/deploy-mvp.sh
```

查看详细部署指南:

```bash
cat MVP_DEPLOYMENT_GUIDE.md
```

