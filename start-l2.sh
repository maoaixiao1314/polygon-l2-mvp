#!/bin/bash

# Polygon L2 MVP 启动脚本
# 用于在服务器上启动 L2 节点

set -e

echo "=========================================="
echo "Polygon L2 MVP - 启动脚本"
echo "=========================================="

# 检查 .env 文件
if [ ! -f .env ]; then
    echo "❌ 错误: .env 文件不存在"
    echo "请先创建 .env 文件"
    exit 1
fi

# 检查 genesis.json
if [ ! -f config/genesis.json ]; then
    echo "❌ 错误: config/genesis.json 不存在"
    echo "请从 zkevm-contracts 复制 genesis.json:"
    echo "cp ~/zkevm-contracts/deployment/v2/genesis.json ~/polygon-l2-mvp/config/genesis.json"
    exit 1
fi

# 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data/postgres data/prover
chmod -R 777 data/

# 停止旧容器
echo "🛑 停止旧容器..."
docker compose down

# 启动数据库
echo "🗄️  启动 PostgreSQL 数据库..."
docker compose up -d zkevm-db

# 等待数据库就绪
echo "⏳ 等待数据库启动 (15秒)..."
sleep 15

# 检查数据库健康状态
echo "🔍 检查数据库状态..."
docker compose ps zkevm-db

# 启动 Prover (暂时跳过 - MVP 测试不需要)
# echo "🔐 启动 Prover..."
# docker compose up -d zkevm-prover
# echo "⏳ 等待 Prover 启动 (10秒)..."
# sleep 10

# 启动 Synchronizer
echo "🔄 启动 Synchronizer..."
docker compose up -d zkevm-sync

# 等待 Synchronizer 同步
echo "⏳ 等待 Synchronizer 初始化 (10秒)..."
sleep 10

# 启动 Sequencer
echo "📦 启动 Sequencer..."
docker compose up -d zkevm-sequencer

# 等待 Sequencer 启动
echo "⏳ 等待 Sequencer 启动 (10秒)..."
sleep 10

# 启动 Aggregator
echo "🔗 启动 Aggregator..."
docker compose up -d zkevm-aggregator

echo ""
echo "=========================================="
echo "✅ 所有服务已启动！"
echo "=========================================="
echo ""
echo "📊 查看服务状态:"
echo "   docker compose ps"
echo ""
echo "📝 查看日志:"
echo "   docker compose logs -f"
echo ""
echo "🔍 查看特定服务日志:"
echo "   docker compose logs -f zkevm-sequencer"
echo "   docker compose logs -f zkevm-sync"
echo "   docker compose logs -f zkevm-aggregator"
echo ""
echo "🌐 L2 RPC 端点:"
echo "   http://localhost:8547"
echo ""
echo "🛑 停止所有服务:"
echo "   docker compose down"
echo ""
echo "=========================================="

