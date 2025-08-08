#!/bin/bash

# 哪吒面板一键添加虚假服务器脚本
# 适用版本：v1
# 功能：批量创建虚假服务器并伪造在线状态
# 警告：仅用于测试环境，生产环境请勿使用

# 配置区域（根据实际情况修改）
NEZHA_DB="/opt/nezha/dashboard/data/sqlite.db"  # 哪吒面板数据库路径
FAKE_SERVER_COUNT=10                            # 要创建的虚假服务器数量
SERVER_PREFIX="Fake-Server"                     # 服务器名称前缀

# 检查sqlite3是否安装
if ! command -v sqlite3 &> /dev/null; then
    echo "错误：sqlite3 未安装，请先执行 apt install sqlite3"
    exit 1
fi

# 备份数据库
backup_db() {
    echo "[1] 备份数据库..."
    cp "$NEZHA_DB" "${NEZHA_DB}.bak-$(date +%s)"
    echo "    备份已保存至: ${NEZHA_DB}.bak-*"
}

# 添加虚假服务器
add_fake_servers() {
    echo "[2] 正在添加 $FAKE_SERVER_COUNT 个虚假服务器..."
    
    for ((i=1; i<=FAKE_SERVER_COUNT; i++)); do
        server_name="${SERVER_PREFIX}-${i}"
        fake_ip="192.168.$((RANDOM % 256)).$((RANDOM % 256))"
        
        # 插入数据库记录
        sqlite3 "$NEZHA_DB" <<EOF
INSERT INTO server (
    name, type, ip, location, status, 
    hostname, created_at, updated_at
) VALUES (
    '$server_name', 'vm', '$fake_ip', 'unknown', 'online',
    '$server_name', datetime('now'), datetime('now')
);
EOF
        echo "    已添加: $server_name"
    done
}

# 伪造服务器数据
generate_fake_data() {
    echo "[3] 正在伪造服务器监控数据..."
    
    # 伪造CPU和内存数据
    sqlite3 "$NEZHA_DB" <<EOF
UPDATE server SET 
    cpu_usage = CAST(ABS(RANDOM() % 30) AS REAL) + 10.0,
    memory_usage = CAST(ABS(RANDOM() % 40) AS REAL) + 30.0,
    disk_usage = CAST(ABS(RANDOM() % 20) AS REAL) + 40.0,
    transfer_in = ABS(RANDOM() % 1000000000),
    transfer_out = ABS(RANDOM() % 2000000000),
    last_active = datetime('now', '-' || (ABS(RANDOM() % 60) || ' minutes'))
WHERE name LIKE '${SERVER_PREFIX}%';
EOF
}

# 设置虚假服务器在线状态
set_online_status() {
    echo "[4] 设置所有虚假服务器为在线状态..."
    sqlite3 "$NEZHA_DB" "UPDATE server SET status = 'online' WHERE name LIKE '${SERVER_PREFIX}%';"
}

# 重启哪吒面板服务（可选）
restart_service() {
    read -p "[?] 是否重启哪吒面板服务使更改生效？(y/n) " choice
    if [[ $choice =~ ^[Yy]$ ]]; then
        echo "[5] 正在重启哪吒面板服务..."
        systemctl restart nezha-dashboard || docker-compose -f /opt/nezha/docker-compose.yaml restart
        echo "    服务已重启，请刷新面板查看"
    else
        echo "[!] 请稍后手动重启哪吒面板服务以使更改生效"
    fi
}

# 主执行流程
main() {
    echo "哪吒面板虚假服务器一键生成脚本"
    echo
