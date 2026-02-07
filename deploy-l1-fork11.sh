#!/bin/bash

# ============================================
# Polygon zkEVM L1 合约部署脚本 (Fork ID 11)
# 使用 zkevm-contracts v7.0.0-fork.11
# ============================================

set -e

echo "=========================================="
echo "Polygon zkEVM L1 合约部署 (Fork ID 11)"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查必需的环境变量
if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo -e "${RED}错误: 请设置 DEPLOYER_PRIVATE_KEY 环境变量${NC}"
    echo "export DEPLOYER_PRIVATE_KEY=your_private_key"
    exit 1
fi

if [ -z "$L1_RPC_URL" ]; then
    echo -e "${YELLOW}警告: L1_RPC_URL 未设置，使用默认值${NC}"
    export L1_RPC_URL="http://54.169.30.130:8545"
fi

echo -e "${GREEN}✓ 环境变量检查通过${NC}"
echo "L1 RPC: $L1_RPC_URL"

# 创建工作目录
WORK_DIR="$HOME/polygon-l1-deployment-fork11"
echo -e "\n${GREEN}创建工作目录: $WORK_DIR${NC}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# 克隆 zkevm-contracts (fork 11)
if [ ! -d "zkevm-contracts" ]; then
    echo -e "\n${GREEN}克隆 zkevm-contracts v7.0.0-fork.11...${NC}"
    git clone --branch v7.0.0-fork.11 https://github.com/0xPolygonHermez/zkevm-contracts.git
else
    echo -e "\n${YELLOW}zkevm-contracts 已存在，跳过克隆${NC}"
fi

cd zkevm-contracts

# 安装依赖
echo -e "\n${GREEN}安装依赖...${NC}"
npm install

# 生成随机 salt (32 字节)
SALT=$(openssl rand -hex 32)
echo -e "\n${GREEN}生成的 Salt: $SALT${NC}"

# 获取部署者地址
DEPLOYER_ADDRESS=$(cast wallet address --private-key "$DEPLOYER_PRIVATE_KEY")
echo -e "${GREEN}部署者地址: $DEPLOYER_ADDRESS${NC}"

# 检查余额
BALANCE=$(cast balance "$DEPLOYER_ADDRESS" --rpc-url "$L1_RPC_URL")
echo -e "${GREEN}部署者余额: $BALANCE wei${NC}"

# 创建部署参数文件
echo -e "\n${GREEN}创建部署参数文件...${NC}"
cat > deployment/v2/deploy_parameters.json << EOF
{
  "realVerifier": true,
  "trustedSequencerURL": "http://54.169.30.130:8547",
  "networkName": "atoshi-zkevm",
  "version": "0.0.1",
  "trustedSequencer": "$DEPLOYER_ADDRESS",
  "chainID": 1001,
  "trustedAggregator": "$DEPLOYER_ADDRESS",
  "trustedAggregatorTimeout": 604800,
  "pendingStateTimeout": 604800,
  "forkID": 11,
  "admin": "$DEPLOYER_ADDRESS",
  "zkEVMOwner": "$DEPLOYER_ADDRESS",
  "timelockAddress": "$DEPLOYER_ADDRESS",
  "minDelayTimelock": 3600,
  "salt": "0x$SALT",
  "initialZkEVMDeployerOwner": "$DEPLOYER_ADDRESS",
  "maticTokenAddress": "",
  "zkEVMDeployerAddress": "",
  "deployerPvtKey": "",
  "maxFeePerGas": "",
  "maxPriorityFeePerGas": "",
  "multiplierGas": ""
}
EOF

echo -e "${GREEN}部署参数文件已创建${NC}"
cat deployment/v2/deploy_parameters.json

# 部署合约
echo -e "\n${GREEN}开始部署 L1 合约...${NC}"
echo -e "${YELLOW}这可能需要 5-10 分钟，请耐心等待...${NC}"

npm run deploy:deployer:ZkEVM:goerli || {
    echo -e "${RED}部署失败！${NC}"
    exit 1
}

# 检查部署输出
DEPLOY_OUTPUT="deployment/v2/deploy_output.json"
if [ -f "$DEPLOY_OUTPUT" ]; then
    echo -e "\n${GREEN}✓ 部署成功！${NC}"
    echo -e "${GREEN}部署输出保存在: $DEPLOY_OUTPUT${NC}"
    
    # 提取关键地址
    echo -e "\n${GREEN}========== 部署的合约地址 ==========${NC}"
    cat "$DEPLOY_OUTPUT" | jq -r '
        "PolygonZkEVM: " + .polygonZkEVMAddress,
        "PolygonZkEVMBridge: " + .polygonZkEVMBridgeAddress,
        "PolygonZkEVMGlobalExitRoot: " + .polygonZkEVMGlobalExitRootAddress,
        "RollupManager: " + .polygonRollupManagerAddress,
        "MaticToken: " + .maticTokenAddress
    '
    
    # 复制到 polygon-l2-mvp 目录
    echo -e "\n${GREEN}复制部署输出到 polygon-l2-mvp...${NC}"
    cp "$DEPLOY_OUTPUT" "$HOME/polygon-l2-mvp/l1-deployment-output-fork11.json"
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ L1 合约部署完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\n${YELLOW}下一步：${NC}"
    echo "1. 使用部署的合约地址生成 genesis.json"
    echo "2. 更新 polygon-l2-mvp/config/genesis.json"
    echo "3. 启动 L2 节点"
else
    echo -e "\n${RED}错误: 未找到部署输出文件${NC}"
    exit 1
fi

