#!/bin/bash

# 初始化 Polygon L2 数据库

set -e

echo "=========================================="
echo "初始化 Polygon L2 数据库"
echo "=========================================="

# 等待数据库启动
echo "⏳ 等待数据库启动..."
sleep 5

# 创建数据库
echo "📊 创建数据库..."
docker compose exec -T zkevm-db psql -U zkevmuser -d postgres << EOF
-- 创建所需的数据库
CREATE DATABASE zkevmdb;
CREATE DATABASE state_db;
CREATE DATABASE pool_db;
CREATE DATABASE event_db;
CREATE DATABASE prover_db;

-- 列出所有数据库
\l
EOF

echo ""
echo "=========================================="
echo "✅ 数据库初始化完成！"
echo "=========================================="

