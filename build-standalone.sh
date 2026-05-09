#!/bin/bash
set -e

PORT=4567
BUILD=true
DATA=/opt/atv/data
LOG=/opt/atv/log
OPENLIST_URL=http://openlist:5244
OPENLIST_CONTAINER=openlist
NETWORK=atv-net

while getopts ":p:u:c:n:r" arg; do
    case "${arg}" in
        p)
            PORT=${OPTARG}
            ;;
        u)
            OPENLIST_URL=${OPTARG}
            ;;
        c)
            OPENLIST_CONTAINER=${OPTARG}
            ;;
        n)
            NETWORK=${OPTARG}
            ;;
        r)
            BUILD=false
            ;;
        *)
            ;;
    esac
done

shift $((OPTIND-1))

if [ $# -gt 0 ]; then
    OPENLIST_URL=$1
fi

if [ "$BUILD" = "true" ]; then
    mvn clean package -DskipTests || exit 1
fi

[ -d data ] || mkdir data
export TZ=Asia/Shanghai
echo $((($(date +%Y) - 2023) * 366 + $(date +%j | sed 's/^0*//'))).$(date +%H%M) > data/version

echo -e "\e[36m端口映射：\e[0m $PORT:4567"
echo -e "\e[36mOpenList地址：\e[0m $OPENLIST_URL"

docker build -f Dockerfile.standalone --tag=alist-tvbox-standalone:latest . || exit 1

# 创建网络（已存在则跳过）
docker network inspect $NETWORK > /dev/null 2>&1 || docker network create $NETWORK

# 将 OpenList 容器加入网络
docker network connect $NETWORK $OPENLIST_CONTAINER 2>/dev/null || true

docker rm -f alist-tvbox 2>/dev/null || true

docker run -d \
    --name=alist-tvbox \
    --network=$NETWORK \
    --restart=unless-stopped \
    -p $PORT:4567 \
    -v "$DATA":/opt/atv/data \
    -v "$LOG":/opt/atv/log \
    -e ALIST_URL=$OPENLIST_URL \
    alist-tvbox-standalone:latest \
    --spring.profiles.active=standalone

sleep 1

IP=$(ip a | grep -F '192.168.' | awk '{print $2}' | awk -F/ '{print $1}' | head -1)
if [ -n "$IP" ]; then
    echo ""
    echo -e "\e[32m请用以下地址访问：\e[0m"
    echo -e "    \e[32m管理界面\e[0m： http://$IP:$PORT/"
else
    IP=$(ip a | grep -F '10.' | awk '{print $2}' | awk -F/ '{print $1}' | grep -E '\b10\.' | head -1)
    if [ -n "$IP" ]; then
        echo ""
        echo -e "\e[32m请用以下地址访问：\e[0m"
        echo -e "    \e[32m管理界面\e[0m： http://$IP:$PORT/"
    fi
    echo -e "\e[32m云服务器请用公网IP访问\e[0m"
fi
echo ""

docker logs -f alist-tvbox