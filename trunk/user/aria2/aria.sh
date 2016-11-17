#!/bin/sh

#######################################################################
# (1) run process from superuser root (less security)
# (0) run process from unprivileged user "nobody" (more security)
SVC_ROOT=0

# process priority (0-normal, 19-lowest)
SVC_PRIORITY=3
#######################################################################

SVC_NAME="Aria2"
SVC_PATH="/usr/bin/aria2c"
DIR_LINK="/mnt/aria"

func_start()
{
	# Make sure already running
	if [ -n "`pidof aria2c`" ] ; then
		return 0
	fi

	echo -n "Starting $SVC_NAME:."

	if [ ! -d "${DIR_LINK}" ] ; then
		echo "[FAILED]"
		logger -t "$SVC_NAME" "Cannot start: unable to find target dir!"
		return 1
	fi

	DIR_CFG="${DIR_LINK}/config"
	DIR_DL1="${DIR_LINK}/downloads"

	[ ! -d "$DIR_CFG" ] && mkdir -p "$DIR_CFG"

	FILE_CONF="$DIR_CFG/aria2.conf"
	FILE_LIST="$DIR_CFG/incomplete.lst"
	FILE_WEB_CONF="$DIR_CFG/configuration.js"

	touch "$FILE_LIST"

	aria_pport=`nvram get aria_pport`
	aria_rport=`nvram get aria_rport`
	aria_user=`nvram get http_username`
	aria_pass=`nvram get http_passwd`
	lan_ipaddr=`nvram get lan_ipaddr_t`

	[ -z "$aria_rport" ] && aria_rport="6800"
	[ -z "$aria_pport" ] && aria_pport="16888"

	if [ ! -f "$FILE_CONF" ] ; then
		[ ! -d "$DIR_DL1" ] && mkdir -p "$DIR_DL1"
		chmod -R 777 "$DIR_DL1"
		cat > "$FILE_CONF" <<EOF
## '#'开头为注释内容, 选项都有相应的注释说明, 根据需要修改 ##
## 被注释的选项填写的是默认值, 建议在需要修改时再取消注释  ##
## RPC相关设置 ##

# 启用RPC, 默认:false
enable-rpc=true
# 允许所有来源, 默认:false
rpc-allow-origin-all=true
# 允许非外部访问, 默认:false
rpc-listen-all=true
# 事件轮询方式, 取值:[epoll, kqueue, port, poll, select], 不同系统默认值不同
#event-poll=select
# RPC监听端口, 端口被占用时可以修改, 默认:6800
#rpc-listen-port=$aria_rport
# 设置的RPC授权令牌, v1.18.4新增功能, 取代 --rpc-user 和 --rpc-passwd 选项
#rpc-secret=<TOKEN>
# 设置的RPC访问用户名, 此选项新版已废弃, 建议改用 --rpc-secret 选项
#rpc-user=<USER>
# 设置的RPC访问密码, 此选项新版已废弃, 建议改用 --rpc-secret 选项
#rpc-passwd=<PASSWD>
## 文件保存相关 ##

# 文件的保存路径(可使用绝对路径或相对路径), 默认: 当前启动位置
dir=$DIR_DL1
# 启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M
#disk-cache=32M
# 文件预分配方式, 能有效降低磁盘碎片, 默认:prealloc
# 预分配所需时间: none < falloc ? trunc < prealloc
# falloc和trunc则需要文件系统和内核支持
# NTFS建议使用falloc, EXT3/4建议trunc, MAC 下需要注释此项
file-allocation=none
#无文件分配限制
no-file-allocation-limit=10M
#允许覆盖
allow-overwrite=false
#自动文件重命名
auto-file-renaming=true
# 断点续传
continue=true

## 下载连接相关 ##
# 较新的版本开启后会在任务完成后依然保留.aria2文件
ftp-pasv=true
#设置FTP传输类型。类型是二进制或ASCII
ftp-type=binary
#设置超时时间
timeout=120
#连接超时时间, 超过60秒还没成功的,就算连接失败
connect-timeout=60
# 最大同时下载任务数, 运行时可修改, 默认:5
max-concurrent-downloads=1
# 同一服务器连接数, 添加时可指定, 默认:1
max-connection-per-server=15
# 最小文件分片大小, 添加时可指定, 取值范围1M -1024M, 默认:20M
# 假定size=10M, 文件为20MiB 则使用两个来源下载; 文件为15MiB 则使用一个来源下载
min-split-size=10M
# 单个任务最大线程数, 添加时可指定, 默认:5
split=15
# 整体下载速度限制, 运行时可修改, 默认:0
max-overall-download-limit=0
# 单个任务下载速度限制, 默认:0
max-download-limit=0
# 整体上传速度限制, 运行时可修改, 默认:5M
max-overall-upload-limit=0
# 单个任务上传速度限制, 默认:0
max-upload-limit=0
# 禁用IPv6, 默认:false
disable-ipv6=true

## 进度保存相关 ##

# 从会话文件中读取下载任务
input-file=$DIR_CFG/aria2.session
# 在Aria2退出时保存`错误/未完成`的下载任务到会话文件
save-session=$DIR_CFG/aria2.session
# 定时保存会话, 0为退出时才保存, 需1.16.1以上版本, 默认:0
save-session-interval=60


## BT/PT下载相关 ##

# 当下载的是一个种子(以.torrent结尾)时, 自动开始BT任务, 默认:true
#follow-torrent=true
# BT监听端口, 当端口被屏蔽时使用, 默认:6881-6999
#listen-port=$aria_pport
# 单个种子最大连接数, 默认:55
bt-max-peers=55
bt-max-open-files=100
# 打开DHT功能, PT需要禁用, 默认:true
enable-dht=true
# 打开IPv6 DHT功能, PT需要禁用
#enable-dht6=false
# DHT网络监听端口, 默认:6881-6999
#dht-listen-port=$aria_pport
# 本地节点查找, PT需要禁用, 默认:false
bt-enable-lpd=false
# 种子交换, PT需要禁用, 默认:true
enable-peer-exchange=false
# 每个种子限速, 对少种的PT很有用, 默认:50K
bt-request-peer-speed-limit=50K
#设置超时时间,没有速度后一段时间任务就自动停止
bt-stop-timeout=0
# 客户端伪装, PT需要
peer-id-prefix=-TR2770-
user-agent=Transmission/2.77
# 当种子的分享率达到这个数时, 自动停止做种, 0为一直做种, 默认:1.0
seed-ratio=1
# 强制保存会话, 即使任务已经完成, 默认:false
# 较新的版本开启后会在任务完成后依然保留.aria2文件
#force-save=false
# BT校验相关, 默认:true
#bt-hash-check-seed=true
# 继续之前的BT任务时, 无需再次校验, 默认:false
bt-seed-unverified=true
# 保存磁力链接元数据为种子文件(.torrent文件), 默认:false
bt-save-metadata=true


### Log
log=$DIR_CFG/aria2.log
log-level=notice

EOF
	fi

	if [ ! -f "$FILE_WEB_CONF" ] ; then
		cat > "$FILE_WEB_CONF" <<EOF
angular
.module('webui.services.configuration',  [])
.constant('\$name', 'Aria2 WebUI')
.constant('\$titlePattern', 'DL: {download_speed} - UL: {upload_speed}')
.constant('\$pageSize', 11)
.constant('\$authconf', {
  host: '$lan_ipaddr',
  path: '/jsonrpc',
  port: '$aria_rport',
  encrypt: false,
  auth: {
  //token: 'admin',
  user: '$aria_user',
  pass: '$aria_pass',
  },
  directURL: ''
})
.constant('\$enable', {
  torrent: true,
  metalink: true,
  sidebar: {
    show: true,
    stats: true,
    filters: true,
    starredProps: true,
  }
})
.constant('\$starredProps', [
  'dir', 'auto-file-renaming', 'max-connection-per-server'
])
.constant('\$downloadProps', [
  'pause', 'dir', 'max-connection-per-server'
])
.constant('\$globalTimeout', 1000)
;

EOF
	else
		old_host=`grep 'host:' $FILE_WEB_CONF | awk -F \' '{print $2}'`
		old_port=`grep 'port:' $FILE_WEB_CONF | awk -F \' '{print $2}'`
		[ "$old_host" != "$lan_ipaddr" ] && sed -i "s/\(host:\).*/\1\ \'$lan_ipaddr\'\,/" $FILE_WEB_CONF
		[ "$old_port" != "$aria_rport" ] && sed -i "s/\(port:\).*/\1\ \'$aria_rport\'\,/" $FILE_WEB_CONF
	fi

	# aria2 needed home dir
	export HOME="$DIR_CFG"

	svc_user=""

	if [ $SVC_ROOT -eq 0 ] ; then
		chmod 777 "${DIR_LINK}"
		chown -R nobody "$DIR_CFG"
		svc_user=" -c nobody"
	fi

	start-stop-daemon -S -N $SVC_PRIORITY$svc_user -x $SVC_PATH -- \
		-D --enable-rpc=true --conf-path="$FILE_CONF" --input-file="$FILE_LIST" --save-session="$FILE_LIST" \
		--rpc-listen-port="$aria_rport" --listen-port="$aria_pport" --dht-listen-port="$aria_pport"

	if [ $? -eq 0 ] ; then
		echo "[  OK  ]"
		logger -t "$SVC_NAME" "daemon is started"
	else
		echo "[FAILED]"
	fi
}

func_stop()
{
	# Make sure not running
	if [ -z "`pidof aria2c`" ] ; then
		return 0
	fi

	echo -n "Stopping $SVC_NAME:."

	# stop daemon
	killall -q aria2c

	# gracefully wait max 15 seconds while aria2c stopped
	i=0
	while [ -n "`pidof aria2c`" ] && [ $i -le 15 ] ; do
		echo -n "."
		i=$(( $i + 1 ))
		sleep 1
	done

	aria_pid=`pidof aria2c`
	if [ -n "$aria_pid" ] ; then
		# force kill (hungup?)
		kill -9 "$aria_pid"
		sleep 1
		echo "[KILLED]"
		logger -t "$SVC_NAME" "Cannot stop: Timeout reached! Force killed."
	else
		echo "[  OK  ]"
	fi
}

func_reload()
{
	aria_pid=`pidof aria2c`
	if [ -n "$aria_pid" ] ; then
		echo -n "Reload $SVC_NAME config:."
		kill -1 "$aria_pid"
		echo "[  OK  ]"
	else
		echo "Error: $SVC_NAME is not started!"
	fi
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
reload)
	func_reload
	;;
restart)
	func_stop
	func_start
	;;
*)
	echo "Usage: $0 {start|stop|reload|restart}"
	exit 1
	;;
esac
