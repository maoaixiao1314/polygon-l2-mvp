# L1 合约部署详细指南

## 概述

在启动 Polygon L2 之前，必须先在 L1 (atoshi-chain) 上部署一系列合约。

---

## 准备工作

### 1. 克隆 Polygon CDK 合约仓库

```bash
cd ~/atoshi
git clone https://github.com/0xPolygonHermez/zkevm-contracts.git
cd zkevm-contracts

# 切换到稳定版本
git checkout v4.0.0

# 安装依赖
npm install
```

### 2. 准备部署账户

你需要一个在 L1 上有足够 ETH 的账户：

```bash
# 检查账户余额
cast balance YOUR_DEPLOYER_ADDRESS --rpc-url http://YOUR_ATOSHI_CHAIN_IP:8545

# 至少需要 10 ETH
# 如果余额不足，从 validator 转账
```

---

## 配置部署参数

### 创建 `deploy_parameters.json`

**⚠️ 重要：文件必须放在 `deployment/v2/` 目录下！**

```bash
cd ~/zkevm-contracts/deployment/v2
vim deploy_parameters.json
```

### 完整配置示例

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

### 参数详解

| 参数 | 说明 | 示例值 |
|------|------|--------|
| `realVerifier` | 是否使用真实验证器 | `true` (生产) / `false` (测试) |
| `trustedSequencerURL` | L2 Sequencer RPC 地址 | `http://YOUR_IP:8547` |
| `networkName` | L2 网络名称 | `atoshi-l2` |
| `version` | 版本号 | `0.0.1` |
| `trustedSequencer` | Sequencer 账户地址 | `0x...` |
| `chainID` | L2 链 ID | `67890` |
| `trustedAggregator` | Aggregator 账户地址 | `0x...` |
| `trustedAggregatorTimeout` | Aggregator 超时时间 (秒) | `604800` (7天) |
| `pendingStateTimeout` | 待处理状态超时 (秒) | `604800` (7天) |
| `forkID` | zkEVM Fork ID | `7` (Etrog) |
| `admin` | 管理员地址 | `0x...` |
| `zkEVMOwner` | zkEVM 所有者地址 | `0x...` |
| `timelockAddress` | Timelock 合约地址 | `0x...` |
| `minDelayTimelock` | Timelock 最小延迟 (秒) | `3600` (1小时) |
| `salt` | CREATE2 部署盐值 | `0x00...01` |

### 关于 `salt` 参数

**什么是 salt？**

`salt` 是一个 32 字节的随机数，用于 CREATE2 部署合约。

**作用：**
1. **确定性地址**：相同的 salt + bytecode = 相同的合约地址
2. **跨链一致性**：在不同链上部署到相同地址
3. **防止碰撞**：避免地址冲突

**如何生成 salt？**

```bash
# 方式 1: 使用简单的递增值
"salt": "0x0000000000000000000000000000000000000000000000000000000000000001"

# 方式 2: 使用时间戳
cast keccak $(date +%s)

# 方式 3: 使用随机数
python3 -c "import secrets; print('0x' + secrets.token_hex(32))"

# 方式 4: 使用 OpenSSL
openssl rand -hex 32 | awk '{print "0x" $0}'
```

**示例：**
```json
{
  "salt": "0x0000000000000000000000000000000000000000000000000000000000000001"
}
```

**注意：**
- 每次部署使用不同的 salt 会得到不同的合约地址
- 如果需要在多个环境部署到相同地址，使用相同的 salt
- MVP 环境建议使用简单的值如 `0x00...01`

---

## 部署方式

### 方式 1: 使用私钥 (推荐)

```bash
cd ~/atoshi/zkevm-contracts

# 设置环境变量
export DEPLOYER_PRIVATE_KEY="0xYourPrivateKeyHere"
export L1_RPC_URL="http://YOUR_ATOSHI_CHAIN_IP:8545"

# 部署
npx hardhat run deployment/testnet/deployPolygonZkEVM.ts \
  --network localhost

# 或使用 npm script
npm run deploy:testnet:ZkEVM:localhost
```

### 方式 2: 使用助记词

```bash
# 设置环境变量
export MNEMONIC="your twelve word mnemonic phrase here"
export L1_RPC_URL="http://YOUR_ATOSHI_CHAIN_IP:8545"

# 部署
npm run deploy:testnet:ZkEVM:localhost
```

### 方式 3: 使用 Hardhat 配置

编辑 `hardhat.config.ts`:

```typescript
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  networks: {
    atoshiChain: {
      url: "http://YOUR_ATOSHI_CHAIN_IP:8545",
      accounts: [
        "0xYourDeployerPrivateKey"
      ],
      chainId: 88388
    }
  }
};

export default config;
```

然后部署：

```bash
npx hardhat run deployment/testnet/deployPolygonZkEVM.ts \
  --network atoshiChain
```

---

## 部署流程

### 1. 部署前检查

```bash
# 检查 L1 连接
curl -X POST http://YOUR_ATOSHI_CHAIN_IP:8545 \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 检查账户余额
cast balance YOUR_DEPLOYER_ADDRESS --rpc-url http://YOUR_ATOSHI_CHAIN_IP:8545

# 检查 gas price
cast gas-price --rpc-url http://YOUR_ATOSHI_CHAIN_IP:8545
```

### 2. 执行部署

```bash
cd ~/atoshi/zkevm-contracts

# 设置环境变量
export DEPLOYER_PRIVATE_KEY="0x..."
export L1_RPC_URL="http://YOUR_IP:8545"

# 开始部署
npm run deploy:testnet:ZkEVM:localhost
```

### 3. 部署输出示例

```
Deploying Polygon zkEVM contracts...

✅ PolygonZkEVMDeployer deployed to: 0x1234...
✅ PolygonZkEVMBridge deployed to: 0x5678...
✅ PolygonZkEVMGlobalExitRoot deployed to: 0x9abc...
✅ PolygonZkEVM deployed to: 0xdef0...
✅ PolygonRollupManager deployed to: 0x1111...

Deployment completed!
```

### 4. 保存合约地址

```bash
# 创建部署记录文件
cat > ~/atoshi/polygon-l2-mvp/deployed-l1-contracts.json << EOF
{
  "network": "atoshi-chain",
  "chainId": 88388,
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "contracts": {
    "PolygonZkEVMDeployer": "0x...",
    "PolygonZkEVMBridge": "0x...",
    "PolygonZkEVMGlobalExitRoot": "0x...",
    "PolygonZkEVM": "0x...",
    "PolygonRollupManager": "0x...",
    "PolygonZkEVMTimelock": "0x...",
    "ProxyAdmin": "0x..."
  },
  "deployer": "0xYourDeployerAddress",
  "sequencer": "0xYourSequencerAddress",
  "aggregator": "0xYourAggregatorAddress"
}
EOF
```

---

## 验证部署

### 1. 检查合约代码

```bash
# 获取合约代码
cast code 0xPolygonZkEVMAddress --rpc-url http://YOUR_IP:8545

# 应该返回一长串字节码，不是 0x
```

### 2. 调用合约方法

```bash
# 检查 Sequencer 地址
cast call 0xPolygonZkEVMAddress \
  "trustedSequencer()(address)" \
  --rpc-url http://YOUR_IP:8545

# 检查链 ID
cast call 0xPolygonZkEVMAddress \
  "chainID()(uint256)" \
  --rpc-url http://YOUR_IP:8545
```

### 3. 在 Blockscout 查看

访问 `http://YOUR_IP:80`，搜索合约地址，应该能看到合约详情。

---

## 更新 L2 配置

### 1. 更新 genesis.json

```bash
cd ~/atoshi/polygon-l2-mvp
vim config/genesis.json
```

填入 L1 合约地址：

```json
{
  "l1Config": {
    "chainId": 88388,
    "polygonZkEVMAddress": "0x...",
    "polygonRollupManagerAddress": "0x...",
    "polTokenAddress": "0x...",
    "polygonZkEVMGlobalExitRootAddress": "0x..."
  }
}
```

### 2. 更新 node-config.toml

```bash
vim config/node-config.toml
```

```toml
[Etherman]
URL = "http://YOUR_ATOSHI_CHAIN_IP:8545"
L1ChainID = 88388
PoEAddr = "0xPolygonZkEVMAddress"
MaticAddr = "0xPolTokenAddress"
GlobalExitRootManagerAddr = "0xGlobalExitRootAddress"
```

---

## 常见问题

### Q1: 部署失败 - insufficient funds

**原因：** 账户余额不足

**解决：**
```bash
# 从 validator 转账
atoshid tx bank send validator YOUR_DEPLOYER_ADDRESS 10000000000000000000aatos \
  --keyring-backend file \
  --home ~/.atoshid-dev \
  --chain-id atoshi_88388-1 \
  --gas-prices 1000000000aatos \
  --yes
```

### Q2: 部署失败 - nonce too low

**原因：** Nonce 不同步

**解决：**
```bash
# 重置 Hardhat 缓存
rm -rf cache/ artifacts/

# 重新部署
npm run deploy:testnet:ZkEVM:localhost
```

### Q3: 如何重新部署？

```bash
# 1. 修改 salt 值（生成新地址）
vim deploy_parameters.json
# 修改 "salt": "0x00...02"

# 2. 重新部署
npm run deploy:testnet:ZkEVM:localhost
```

### Q4: 部署后如何升级合约？

```bash
# Polygon zkEVM 使用代理模式
# 升级实现合约：
npx hardhat run scripts/upgrade-implementation.ts --network atoshiChain
```

---

## 部署检查清单

部署前：
- [ ] L1 (atoshi-chain) 正在运行
- [ ] 部署账户有足够 ETH (>10 ETH)
- [ ] Sequencer 和 Aggregator 账户已创建
- [ ] `deploy_parameters.json` 已配置
- [ ] 已安装 npm 依赖

部署后：
- [ ] 所有合约部署成功
- [ ] 合约地址已保存
- [ ] 合约代码已验证（非 0x）
- [ ] 在 Blockscout 可以查看合约
- [ ] `genesis.json` 已更新
- [ ] `node-config.toml` 已更新

---

## 下一步

部署完成后：
1. ✅ 更新 L2 配置文件
2. ⏭️ 启动 Polygon L2 节点
3. ⏭️ 部署隐私合约到 L2

---

## 参考资料

- [Polygon CDK 文档](https://docs.polygon.technology/cdk/)
- [zkEVM 合约仓库](https://github.com/0xPolygonHermez/zkevm-contracts)
- [Hardhat 文档](https://hardhat.org/docs)
- [CREATE2 详解](https://eips.ethereum.org/EIPS/eip-1014)

