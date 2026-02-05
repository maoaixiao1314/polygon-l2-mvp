# Polygon L2 MVP 完整部署流程

## 前置条件检查

- ✅ atoshi-chain (L1) 正在运行
- ✅ L1 上有账户且有足够 ETH (至少 20 ETH)
- ✅ 服务器配置: 8核+ / 32GB+ RAM
- ✅ Docker 和 Docker Compose 已安装

---

## 阶段 1: 准备工作

### 1.1 生成账户私钥

如果还没有私钥，生成三个账户：

```bash
# 方法 1: 使用 cast (foundry)
cast wallet new  # 运行 3 次，分别用于 Deployer, Sequencer, Aggregator

# 方法 2: 使用 Node.js
node -e "console.log('0x' + require('crypto').randomBytes(32).toString('hex'))"

# 方法 3: 使用 Python
python3 -c "import secrets; print('0x' + secrets.token_hex(32))"
```

**保存这三个私钥：**
- Deployer: 用于部署 L1 合约
- Sequencer: 用于 L2 排序交易
- Aggregator: 用于 L2 聚合证明

### 1.2 给账户充值 (L1)

在 atoshi-chain 上给这三个账户转账：

```bash
# 使用 atoshi-chain 的 validator 账户转账
atoshid tx bank send validator <DEPLOYER_ADDRESS> 10000000000000000000aatos \
  --keyring-backend file \
  --home ~/.atoshid-dev \
  --chain-id atoshi_88388-1 \
  --gas-prices 1000000000aatos \
  --yes

# 同样给 Sequencer 和 Aggregator 转账
```

### 1.3 配置环境变量

```bash
cd ~/atoshi/polygon-l2-mvp

# 复制模板
cp env.template .env

# 编辑 .env 文件
vim .env
```

**必填项：**
```bash
# L1 配置
L1_RPC_URL=http://YOUR_ATOSHI_CHAIN_IP:8545
L1_CHAIN_ID=88388

# L2 配置
L2_CHAIN_ID=67890

# 账户私钥
DEPLOYER_PRIVATE_KEY=0x...
SEQUENCER_PRIVATE_KEY=0x...
AGGREGATOR_PRIVATE_KEY=0x...

# 数据库配置
POSTGRES_PASSWORD=your_strong_password
```

---

## 阶段 2: 部署 L1 合约

### 2.1 克隆 Polygon CDK 部署工具

```bash
cd ~/atoshi
git clone https://github.com/0xPolygonHermez/zkevm-contracts.git
cd zkevm-contracts
npm install
```

### 2.2 配置 L1 部署参数

**⚠️ 重要：配置文件必须放在 `deployment/v2/` 目录下！**

需要创建两个配置文件：

#### 文件 1: deploy_parameters.json

```bash
cd ~/zkevm-contracts/deployment/v2
vim deploy_parameters.json
```

```json
{
  "realVerifier": true,
  "trustedSequencerURL": "http://YOUR_SERVER_IP:8547",
  "networkName": "atoshi-l2",
  "version": "0.0.1",
  "trustedSequencer": "0xYourSequencerAddress",
  "chainID": 67890,
  "trustedAggregator": "0xYourAggregatorAddress",
  "trustedAggregatorTimeout": 604800,
  "pendingStateTimeout": 604800,
  "forkID": 7,
  "admin": "0xYourDeployerAddress",
  "zkEVMOwner": "0xYourDeployerAddress",
  "timelockAddress": "0xYourDeployerAddress",
  "minDelayTimelock": 3600,
  "salt": "0x0000000000000000000000000000000000000000000000000000000000000001",
  "initialZkEVMDeployerOwner": "0xYourDeployerAddress",
  "maticTokenAddress": "",
  "zkEVMDeployerAddress": "",
  "deployerPvtKey": "",
  "maxFeePerGas": "",
  "maxPriorityFeePerGas": "",
  "multiplierGas": ""
}
```

**参数说明：**
- `salt`: CREATE2 部署盐值，用于生成确定性地址，使用 `0x00...01` 即可
- `trustedSequencerURL`: 注意端口是 8547（避免与 L1 的 8545 冲突）

#### 文件 2: create_rollup_parameters.json

```bash
cd ~/zkevm-contracts/deployment/v2
vim create_rollup_parameters.json
```

```json
{
  "realVerifier": true,
  "chainID": 67890,
  "trustedSequencer": "0xYourSequencerAddress",
  "trustedSequencerURL": "http://YOUR_SERVER_IP:8547",
  "networkName": "atoshi-l2",
  "forkID": 7,
  "consensusContract": "PolygonZkEVMEtrog",
  "description": "Atoshi L2 - Privacy-focused zkEVM Rollup",
  "gasTokenAddress": "",
  "gasTokenNetwork": 0
}
```

**⚠️ 确保两个文件中的以下参数一致：**
- `trustedSequencer` 地址
- `chainID`
- `trustedSequencerURL`

#### 快速创建脚本

```bash
cd ~/zkevm-contracts/deployment/v2

# 设置变量（替换为你的实际值）
SEQUENCER_ADDR="0xYourSequencerAddress"
AGGREGATOR_ADDR="0xYourAggregatorAddress"
DEPLOYER_ADDR="0xYourDeployerAddress"
SERVER_IP=$(curl -s ifconfig.me)

# 创建 deploy_parameters.json
cat > deploy_parameters.json << EOF
{
  "realVerifier": true,
  "trustedSequencerURL": "http://${SERVER_IP}:8547",
  "networkName": "atoshi-l2",
  "version": "0.0.1",
  "trustedSequencer": "${SEQUENCER_ADDR}",
  "chainID": 67890,
  "trustedAggregator": "${AGGREGATOR_ADDR}",
  "trustedAggregatorTimeout": 604800,
  "pendingStateTimeout": 604800,
  "forkID": 7,
  "admin": "${DEPLOYER_ADDR}",
  "zkEVMOwner": "${DEPLOYER_ADDR}",
  "timelockAddress": "${DEPLOYER_ADDR}",
  "minDelayTimelock": 3600,
  "salt": "0x0000000000000000000000000000000000000000000000000000000000000001",
  "initialZkEVMDeployerOwner": "${DEPLOYER_ADDR}",
  "maticTokenAddress": "",
  "zkEVMDeployerAddress": "",
  "deployerPvtKey": "",
  "maxFeePerGas": "",
  "maxPriorityFeePerGas": "",
  "multiplierGas": ""
}
EOF

# 创建 create_rollup_parameters.json
cat > create_rollup_parameters.json << EOF
{
  "realVerifier": true,
  "chainID": 67890,
  "trustedSequencer": "${SEQUENCER_ADDR}",
  "trustedSequencerURL": "http://${SERVER_IP}:8547",
  "networkName": "atoshi-l2",
  "forkID": 7,
  "consensusContract": "PolygonZkEVMEtrog",
  "description": "Atoshi L2 - Privacy-focused zkEVM Rollup",
  "gasTokenAddress": "",
  "gasTokenNetwork": 0
}
EOF

# 验证
ls -l *.json
```

### 2.3 部署 L1 合约

```bash
# 方式 1: 使用私钥 (推荐)
export DEPLOYER_PRIVATE_KEY="0xYourPrivateKeyHere"
export L1_RPC_URL="http://YOUR_ATOSHI_CHAIN_IP:8545"

# 方式 2: 使用助记词
# export MNEMONIC="your twelve word mnemonic phrase here"
# export L1_RPC_URL="http://YOUR_ATOSHI_CHAIN_IP:8545"

# 部署
npm run deploy:testnet:ZkEVM:localhost

# 部署完成后，记录合约地址
```

**重要：保存这些合约地址！**
- PolygonZkEVMGlobalExitRoot
- PolygonZkEVMBridge
- PolygonZkEVM
- PolygonZkEVMDeployer

---

## 阶段 3: 配置 L2 节点

### 3.1 更新 genesis.json

编辑 `~/atoshi/polygon-l2-mvp/config/genesis.json`:

```json
{
  "l1Config": {
    "chainId": 88388,
    "polygonZkEVMAddress": "L1_POLYGON_ZKEVM_ADDRESS",
    "polygonRollupManagerAddress": "L1_ROLLUP_MANAGER_ADDRESS",
    "polTokenAddress": "L1_POL_TOKEN_ADDRESS",
    "polygonZkEVMGlobalExitRootAddress": "L1_GLOBAL_EXIT_ROOT_ADDRESS"
  },
  "root": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "genesis": [
    {
      "balance": "100000000000000000000000",
      "nonce": "0",
      "address": "YOUR_DEPLOYER_ADDRESS",
      "pvtKey": "YOUR_DEPLOYER_PRIVATE_KEY"
    },
    {
      "balance": "10000000000000000000000",
      "nonce": "0",
      "address": "YOUR_SEQUENCER_ADDRESS",
      "pvtKey": "YOUR_SEQUENCER_PRIVATE_KEY"
    },
    {
      "balance": "10000000000000000000000",
      "nonce": "0",
      "address": "YOUR_AGGREGATOR_ADDRESS",
      "pvtKey": "YOUR_AGGREGATOR_PRIVATE_KEY"
    }
  ]
}
```

### 3.2 更新 node-config.toml

编辑 `~/atoshi/polygon-l2-mvp/config/node-config.toml`:

```toml
[Etherman]
URL = "http://YOUR_ATOSHI_CHAIN_IP:8545"
L1ChainID = 88388
PoEAddr = "L1_POLYGON_ZKEVM_ADDRESS"
MaticAddr = "L1_POL_TOKEN_ADDRESS"
GlobalExitRootManagerAddr = "L1_GLOBAL_EXIT_ROOT_ADDRESS"

[Sequencer]
WaitPeriodPoolIsEmpty = "1s"
WaitPeriodSendSequence = "15s"
LastBatchVirtualizationTimeMaxWaitPeriod = "10s"
MaxTxsPerBatch = 150
MaxBatchBytesSize = 129848
BlocksAmountForTxsToBeDeleted = 100
FrequencyToCheckTxsForDelete = "12h"
MaxAllowedFailedCounter = 3
PrivateKey = {Path = "/pk/sequencer.keystore", Password = ""}

[Aggregator]
PrivateKey = {Path = "/pk/aggregator.keystore", Password = ""}
```

---

## 阶段 4: 启动 L2 节点

### 4.1 启动服务

```bash
cd ~/atoshi/polygon-l2-mvp

# 启动所有服务
docker compose up -d

# 查看日志
docker compose logs -f
```

### 4.2 验证服务状态

```bash
# 检查容器状态
docker compose ps

# 测试 RPC
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 检查账户余额
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBalance","params":["YOUR_DEPLOYER_ADDRESS","latest"],"id":1}'
```

---

## 阶段 5: 部署隐私合约到 L2

### 5.1 准备合约部署脚本

```bash
cd ~/atoshi/privacy-contracts  # 你的隐私合约目录

# 配置 L2 网络
cat > hardhat.config.js << EOF
module.exports = {
  networks: {
    polygonL2: {
      url: "http://localhost:8545",
      accounts: ["YOUR_DEPLOYER_PRIVATE_KEY"],
      chainId: 67890
    }
  }
};
EOF
```

### 5.2 部署 Verifier 合约

```bash
# 部署 Groth16 Verifier
npx hardhat run scripts/deploy-verifier.js --network polygonL2

# 记录合约地址
VERIFIER_ADDRESS=0x...
```

### 5.3 部署 PrivacyPool 合约

```bash
# 部署 Privacy Pool
npx hardhat run scripts/deploy-privacy-pool.js --network polygonL2

# 记录合约地址
PRIVACY_POOL_ADDRESS=0x...
```

### 5.4 更新配置

将合约地址更新到 `.env`:

```bash
# 编辑 .env
VERIFIER_CONTRACT_ADDRESS=0x...
PRIVACY_POOL_CONTRACT_ADDRESS=0x...
```

---

## 阶段 6: 配置 Blockscout

### 6.1 添加 L2 网络到 Blockscout

编辑 Blockscout 配置，添加 L2 RPC：

```bash
# 在 Blockscout 的 docker-compose 中添加环境变量
ETHEREUM_JSONRPC_HTTP_URL=http://YOUR_SERVER_IP:8545
CHAIN_ID=67890
```

### 6.2 重启 Blockscout

```bash
cd ~/blockscout/docker
make restart
```

---

## 阶段 7: 测试隐私交易

### 7.1 测试存款 (Deposit)

```javascript
// 使用 SDK 测试
const { PrivacySDK } = require('./privacy-sdk');

const sdk = new PrivacySDK({
  l2RpcUrl: 'http://localhost:8545',
  privacyPoolAddress: 'YOUR_PRIVACY_POOL_ADDRESS',
  verifierAddress: 'YOUR_VERIFIER_ADDRESS'
});

// 存款 1 ETH
await sdk.deposit('1.0');
```

### 7.2 测试隐私转账

```javascript
// 生成证明并转账
await sdk.transfer(recipientAddress, '0.5');
```

### 7.3 测试提款

```javascript
// 提款到指定地址
await sdk.withdraw(yourAddress, '0.5');
```

---

## 故障排除

### 问题 1: L2 节点无法连接 L1

**检查：**
```bash
# 测试 L1 连接
curl http://YOUR_ATOSHI_CHAIN_IP:8545

# 检查防火墙
sudo ufw status
```

### 问题 2: Prover 内存不足

**解决：**
```bash
# 减少 Prover 线程数
# 编辑 .env
PROVER_THREADS=2
```

### 问题 3: 合约部署失败

**检查：**
```bash
# 检查账户余额
cast balance YOUR_DEPLOYER_ADDRESS --rpc-url http://localhost:8545

# 检查 gas price
cast gas-price --rpc-url http://localhost:8545
```

---

## 端口占用总结

| 服务 | 端口 | 说明 |
|------|------|------|
| atoshi-chain RPC | 8545 | L1 RPC |
| atoshi-chain WS | 8546 | L1 WebSocket |
| Polygon L2 RPC | 8547 | L2 RPC (避免与 L1 冲突) |
| Polygon L2 WS | 8548 | L2 WebSocket (避免与 L1 冲突) |
| Polygon L2 DB | 5433 | PostgreSQL (避免冲突) |
| Blockscout L1 DB | 7432 | PostgreSQL (L1) |
| Blockscout L1 Web | 80 | L1 区块浏览器 |
| Blockscout L2 DB | 7434 | PostgreSQL (L2，待部署) |
| Blockscout L2 Web | 81 | L2 区块浏览器（待部署） |
| Prover MT | 50061 | Merkle Tree 服务 |
| Prover Executor | 50071 | 执行器服务 |

**注意：** 
- L1 和 L2 需要各自独立的 Blockscout 实例
- 确保 `.env` 文件已添加到 `.gitignore`，避免提交敏感信息

---

## 下一步

1. ✅ 完成 L2 部署
2. ✅ 部署隐私合约
3. ⏭️ 集成前端 SDK
4. ⏭️ 配置电路参数
5. ⏭️ 性能测试和优化

---

## 参考资料

- [Polygon CDK 文档](https://docs.polygon.technology/cdk/)
- [zkEVM 节点配置](https://github.com/0xPolygonHermez/zkevm-node)
- [隐私交易流程](./PRIVACY_TRANSACTION_FLOWS.md)
- [MVP 部署指南](./MVP_DEPLOYMENT_GUIDE.md)

