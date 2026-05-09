#!/bin/sh

# 读取自定义环境变量
if [ -r /data/env ]; then
    echo "Reading env file"
    cp /data/env /etc/profile.d/custom_env.sh
    chmod +x /etc/profile.d/custom_env.sh
fi

# 读取代理配置
if [ -r /data/proxy.txt ]; then
    proxy_url=$(head -n1 /data/proxy.txt)
    export HTTP_PROXY=$proxy_url
    export HTTPS_PROXY=$proxy_url
    export no_proxy="*.aliyundrive.com"
fi

# 创建日志目录
if [ ! -d /opt/atv/log ]; then
    mkdir -p /opt/atv/log
fi

# 创建数据目录
if [ ! -d /opt/atv/data ]; then
    mkdir -p /opt/atv/data
fi

echo "Starting alist-tvbox standalone mode..."
echo "OpenList URL: ${ALIST_URL:-http://127.0.0.1:5244}"

# 启动 Spring Boot 应用
exec java -jar /opt/atv/app.jar "$@"