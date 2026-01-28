#!/bin/bash

# ============================================
# Polygon L2 MVP 一键部署脚本
# ============================================

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        🚀 Polygon L2 MVP 一键部署                              ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============ 1. 检查环境 ============
echo "📋 Step 1/6: 检查环境..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    echo "请先安装 Docker: curl -fsSL https://get.docker.com | sh"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker 已安装"

# 检查 Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker Compose 已安装"

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env 文件不存在，创建模板...${NC}"
    cat > .env << 'EOF'
# L1 配置 (atoshi-chain)
L1_RPC_URL=http://YOUR_ATOSHI_CHAIN_RPC:8545
L1_CHAIN_ID=12345

# L2 配置
L2_CHAIN_ID=67890

# 账户配置 (请填写实际私钥)
DEPLOYER_PRIVATE_KEY=0x...
SEQUENCER_PRIVATE_KEY=0x...
AGGREGATOR_PRIVATE_KEY=0x...

# 数据库配置
POSTGRES_USER=zkevmuser
POSTGRES_PASSWORD=zkevmpassword
POSTGRES_DB=zkevmdb

# Prover 配置
PROVER_THREADS=4
EOF
    echo -e "${YELLOW}⚠️  请编辑 .env 文件填写配置，然后重新运行此脚本${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} .env 文件存在"

# ============ 2. 创建目录 ============
echo ""
echo "📁 Step 2/6: 创建数据目录..."

mkdir -p data/postgres
mkdir -p data/prover
mkdir -p logs

echo -e "${GREEN}✓${NC} 目录创建完成"

# ============ 3. 检查配置文件 ============
echo ""
echo "📝 Step 3/6: 检查配置文件..."

if [ ! -f "config/node-config.toml" ]; then
    echo -e "${RED}❌ config/node-config.toml 不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} node-config.toml 存在"

if [ ! -f "config/prover-config.json" ]; then
    echo -e "${RED}❌ config/prover-config.json 不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} prover-config.json 存在"

# ============ 4. 启动服务 ============
echo ""
echo "🐳 Step 4/6: 启动 Docker 服务..."

docker compose up -d

echo -e "${GREEN}✓${NC} Docker 服务已启动"

# ============ 5. 等待服务就绪 ============
echo ""
echo "⏳ Step 5/6: 等待服务启动 (约 30 秒)..."

# 等待数据库
echo "  等待数据库..."
for i in {1..30}; do
    if docker compose exec -T zkevm-db pg_isready -U zkevmuser > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} 数据库已就绪"
        break
    fi
    sleep 1
done

# 等待 Prover
echo "  等待 Prover..."
sleep 10
echo -e "  ${GREEN}✓${NC} Prover 已启动"

# 等待 Sequencer
echo "  等待 Sequencer..."
for i in {1..30}; do
    if curl -s -X POST http://localhost:8545 \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Sequencer 已就绪"
        break
    fi
    sleep 2
done

# ============ 6. 验证部署 ============
echo ""
echo "✅ Step 6/6: 验证部署..."

# 测试 RPC
BLOCK_NUMBER=$(curl -s -X POST http://localhost:8545 \
    -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    | jq -r '.result' 2>/dev/null || echo "null")

if [ "$BLOCK_NUMBER" != "null" ] && [ "$BLOCK_NUMBER" != "" ]; then
    BLOCK_DEC=$((16#${BLOCK_NUMBER:2}))
    echo -e "${GREEN}✓${NC} RPC 正常，当前区块: $BLOCK_DEC"
else
    echo -e "${YELLOW}⚠️  RPC 响应异常，请检查日志${NC}"
fi

# 检查服务状态
echo ""
echo "📊 服务状态:"
docker compose ps

# ============ 完成 ============
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        🎉 Polygon L2 MVP 部署完成！                            ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 服务端点:"
echo "  • RPC:        http://localhost:8545"
echo "  • WebSocket:  ws://localhost:8546"
echo "  • Metrics:    http://localhost:9091"
echo ""
echo "📋 常用命令:"
echo "  • 查看日志:   docker compose logs -f"
echo "  • 查看状态:   docker compose ps"
echo "  • 停止服务:   docker compose down"
echo "  • 重启服务:   docker compose restart"
echo ""
echo "📖 下一步:"
echo "  1. 部署隐私合约到 L2"
echo "  2. 更新 SDK 配置"
echo "  3. 测试隐私交易"
echo ""
echo "💡 提示:"
echo "  • 查看详细文档: cat MVP_DEPLOYMENT_GUIDE.md"
echo "  • 监控资源使用: docker stats"
echo ""

