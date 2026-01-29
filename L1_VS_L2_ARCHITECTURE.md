# L1 vs L2 架构对比

## 完整架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                         你的服务器                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────┐      ┌─────────────────────────┐      │
│  │   L1 (atoshi-chain)     │      │   L2 (Polygon zkEVM)    │      │
│  ├─────────────────────────┤      ├─────────────────────────┤      │
│  │ RPC:  :8545             │      │ RPC:  :8547             │      │
│  │ WS:   :8546             │      │ WS:   :8548             │      │
│  │ DB:   :5432             │      │ DB:   :5433             │      │
│  │                         │      │                         │      │
│  │ 合约:                   │      │ 合约:                   │      │
│  │ ├─ Bridge               │◄────►│ ├─ Verifier             │      │
│  │ ├─ PolygonZkEVM         │      │ └─ PrivacyPool          │      │
│  │ └─ GlobalExitRoot       │      │                         │      │
│  └─────────────────────────┘      └─────────────────────────┘      │
│           │                                 │                        │
│           │                                 │                        │
│  ┌────────▼────────────┐          ┌────────▼────────────┐          │
│  │ Blockscout L1       │          │ Blockscout L2       │          │
│  ├─────────────────────┤          ├─────────────────────┤          │
│  │ Web:  :80           │          │ Web:  :81           │          │
│  │ DB:   :7432         │          │ DB:   :7434         │          │
│  │                     │          │                     │          │
│  │ 显示:               │          │ 显示:               │          │
│  │ ├─ L1 交易          │          │ ├─ L2 交易          │          │
│  │ ├─ L1 合约          │          │ ├─ 隐私合约         │          │
│  │ └─ Bridge 操作      │          │ └─ 隐私交易         │          │
│  └─────────────────────┘          └─────────────────────┘          │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 详细对比表

| 项目 | L1 (atoshi-chain) | L2 (Polygon zkEVM) |
|------|-------------------|-------------------|
| **网络类型** | 主链 (Layer 1) | 侧链 (Layer 2) |
| **共识机制** | Tendermint PoS | zkEVM (零知识证明) |
| **RPC 端口** | 8545 | 8547 |
| **WebSocket 端口** | 8546 | 8548 |
| **数据库端口** | 5432 | 5433 |
| **Blockscout 端口** | 80 | 81 |
| **Blockscout DB** | 7432 | 7434 |
| **链 ID** | 88388 | 67890 |
| **Gas 费用** | 较高 | 极低 (批量提交) |
| **TPS** | ~100 | ~1000+ |
| **确认时间** | ~6 秒 | ~1 秒 (L2 内部) |

---

## 合约部署位置

### L1 合约 (atoshi-chain)

```
L1 合约 (部署在 atoshi-chain)
├─ PolygonZkEVM.sol
│  └─ 作用: 验证 L2 提交的批次和证明
│
├─ PolygonZkEVMBridge.sol
│  └─ 作用: L1 ↔ L2 资产跨链
│
├─ PolygonZkEVMGlobalExitRoot.sol
│  └─ 作用: 管理跨链退出根
│
└─ PolygonRollupManager.sol
   └─ 作用: 管理多个 Rollup
```

### L2 合约 (Polygon zkEVM)

```
L2 合约 (部署在 Polygon L2)
├─ Verifier.sol (Groth16Verifier)
│  └─ 作用: 验证隐私交易的零知识证明
│
└─ PrivacyPool.sol
   └─ 作用: 管理隐私资金池
```

---

## genesis.json 的作用

### 为什么需要 genesis.json？

`genesis.json` 是 L2 的"出生证明"，定义了：

1. **L1 连接信息**
   ```json
   "l1Config": {
     "chainId": 88388,                    // ← 连接到哪个 L1
     "polygonZkEVMAddress": "0x...",      // ← L1 合约地址
     "polygonZkEVMGlobalExitRootAddress": "0x..."
   }
   ```

2. **初始账户余额**
   ```json
   "genesis": [
     {
       "address": "0xYourAddress",
       "balance": "100000000000000000000000"  // ← 100,000 ETH
     }
   ]
   ```

3. **网络参数**
   ```json
   "chainID": 67890,
   "forkID": 7,
   "consensusContract": "PolygonZkEVMEtrog"
   ```

### 类比：atoshi-chain 的 genesis

atoshi-chain 的 `local_node.sh` 中也有类似的 genesis 配置：

```bash
# atoshi-chain genesis
atoshid add-genesis-account validator 100000000000000000000000000aatos
atoshid add-genesis-account dev0 1000000000000000000000aatos
```

**作用相同：** 给账户预分配初始余额，不需要挖矿或转账。

---

## 两个 Blockscout 的必要性

### 为什么不能共用一个 Blockscout？

**因为它们是两条不同的链！**

| 特性 | L1 Blockscout | L2 Blockscout |
|------|--------------|--------------|
| **连接的 RPC** | http://localhost:8545 | http://localhost:8547 |
| **链 ID** | 88388 | 67890 |
| **显示的交易** | L1 交易 | L2 交易 |
| **显示的合约** | Bridge, PolygonZkEVM | Verifier, PrivacyPool |
| **显示的区块** | L1 区块 | L2 区块 |
| **数据库** | 独立的 PostgreSQL (7432) | 独立的 PostgreSQL (7434) |

### 用户体验

```
用户想查看 L1 交易:
  → 访问 http://YOUR_IP:80 (L1 Blockscout)
  → 看到 atoshi-chain 的交易和合约

用户想查看隐私交易:
  → 访问 http://YOUR_IP:81 (L2 Blockscout)
  → 看到 Polygon L2 的隐私交易
```

---

## 部署顺序总结

```
1️⃣ 启动 L1 (atoshi-chain)
   └─ 端口: 8545, 8546

2️⃣ 部署 L1 合约
   ├─ PolygonZkEVM
   ├─ Bridge
   └─ GlobalExitRoot
   └─ 获取合约地址 ✅

3️⃣ 配置 genesis.json
   └─ 填入 L1 合约地址 ✅

4️⃣ 启动 L2 (Polygon zkEVM)
   └─ 端口: 8547, 8548, 5433

5️⃣ 部署 L2 合约
   ├─ Verifier
   └─ PrivacyPool

6️⃣ 部署 L1 Blockscout
   └─ 端口: 80, 7432

7️⃣ 部署 L2 Blockscout
   └─ 端口: 81, 7434
```

---

## 常见误区

### ❌ 误区 1: L2 可以独立运行
**错误！** L2 必须连接到 L1，通过 genesis.json 配置 L1 合约地址。

### ❌ 误区 2: 一个 Blockscout 可以显示两条链
**错误！** 每条链需要独立的 Blockscout，因为它们有不同的 RPC 和数据库。

### ❌ 误区 3: genesis.json 只是可选配置
**错误！** genesis.json 是必需的，它定义了 L2 的初始状态和 L1 连接信息。

### ❌ 误区 4: L1 部署参数应该是 L1 的信息
**错误！** L1 部署参数包含 L2 的信息（Sequencer、Aggregator、链 ID），因为 L1 合约需要知道谁有权限操作 L2。

---

## 快速检查清单

部署前确认：

- [ ] L1 (atoshi-chain) 正在运行 (端口 8545)
- [ ] 有 3 个账户私钥 (Deployer, Sequencer, Aggregator)
- [ ] 账户在 L1 上有足够 ETH (至少 20 ETH)
- [ ] 端口没有冲突 (8547, 8548, 5433, 81, 7434)
- [ ] 已准备好 deploy_parameters.json (包含 L2 信息)
- [ ] 已准备好 genesis.json 模板

部署后验证：

- [ ] L1 合约部署成功，获得地址
- [ ] genesis.json 已填入 L1 合约地址
- [ ] L2 节点启动成功 (curl http://localhost:8547)
- [ ] L2 账户有余额 (genesis 预分配)
- [ ] 隐私合约部署成功
- [ ] L1 Blockscout 显示 L1 交易
- [ ] L2 Blockscout 显示 L2 交易

