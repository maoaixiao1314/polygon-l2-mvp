#!/bin/bash
set -e

echo "🚀 启动 Polygon zkEVM L2..."

# 1. 启动所有服务
docker compose up -d

# 2. 等待数据库健康检查通过
echo "⏳ 等待数据库启动..."
timeout 60 bash -c 'until docker compose exec -T zkevm-db pg_isready -U zkevmuser > /dev/null 2>&1; do sleep 2; done'

# 3. 初始化 Prover 表（如果不存在）
echo "📊 初始化 Prover 数据库表..."
docker compose exec -T zkevm-db psql -U zkevmuser -d zkevmdb << 'SQL'
CREATE TABLE IF NOT EXISTS state.nodes (
    hash BYTEA PRIMARY KEY,
    data BYTEA NOT NULL
);
CREATE TABLE IF NOT EXISTS state.program (
    hash BYTEA PRIMARY KEY,
    data BYTEA NOT NULL
);
SQL

# 4. 重启 Prover
echo "🔄 重启 Prover..."
docker compose restart zkevm-prover

# 5. 等待服务稳定
echo "⏳ 等待服务稳定..."
sleep 15

# 6. 显示状态
echo ""
echo "✅ 服务状态："
docker compose ps

echo ""
echo "🎉 L2 启动完成！"
echo "📍 RPC 端点: http://localhost:8123"
echo "📍 Sequencer RPC: http://localhost:8547"
echo ""
echo "🔍 查看日志："
echo "  docker compose logs -f zkevm-sequencer"
echo "  docker compose logs -f zkevm-prover"
echo "  docker compose logs -f zkevm-sync"
echo ""
echo "🧪 测试 RPC："
echo "  curl -X POST http://localhost:8123 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}'"
