#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
echo "ulimit -v 640000;" >> ~/.bashrc
source ~/.bashrc

# 增加swap空间
sudo mkdir /swap
sudo fallocate -l 24G /swap/swapfile
sudo chmod 600 /swap/swapfile
sudo mkswap /swap/swapfile
sudo swapon /swap/swapfile
echo '/swap/swapfile swap swap defaults 0 0' >> /etc/fstab

# 向/etc/sysctl.conf文件追加内容
echo -e "\n# 自定义最大接收和发送缓冲区大小" >> /etc/sysctl.conf
echo "net.core.rmem_max=600000000" >> /etc/sysctl.conf
echo "net.core.wmem_max=600000000" >> /etc/sysctl.conf

echo "配置已添加到/etc/sysctl.conf"

# 重新加载sysctl配置以应用更改
sysctl -p

echo "sysctl配置已重新加载"

# 更新并升级Ubuntu软件包
sudo apt update  

# 安装wget、screen和git等组件
sudo apt -yq install git ufw bison screen binutils gcc make bsdmainutils 
sudo apt -yq install util-linux

# 安装GVM
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
source /root/.gvm/scripts/gvm

gvm install go1.4 -B
gvm use go1.4
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.17.13
gvm use go1.17.13
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.20.2
gvm use go1.20.2

# 克隆仓库
# git clone https://github.com/quilibriumnetwork/ceremonyclient
# git clone https://source.quilibrium.com/quilibrium/ceremonyclient.git
git clone https://github.com/a3165458/ceremonyclient.git
cd ~/ceremonyclient
# 切换分支
git switch release
# 进入ceremonyclient/node目录
cd ~/ceremonyclient/node 
# 赋予执行权限
chmod +x release_autorun.sh
# 创建一个screen会话并运行命令

#------------------------计算内存/2的核数，用来运行程序------------------------
# 获取系统内存大小（单位为 KB）
total_memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# 将内存大小转换为 GB
total_memory_gb=$(echo "$total_memory_kb / 1024 / 1024" | bc)
# 计算内存的一半所需的 CPU 核数
half_memory_cores=$(echo "($total_memory_gb / 2)" | bc)
echo "全部的内存: $total_memory_gb GB"
echo "可使用的核数: $half_memory_cores"

#------------------------启动服务------------------------
screen -dmS Quili bash -c "taskset -c $half_memory_cores ./release_autorun.sh"

##同步至最新高度
# cd ~
# apt -yq install unzip
# wget http://95.216.228.91/store.zip
# unzip store.zip
# cd ~/ceremonyclient/node/.config
# rm -rf store
# cd ~
# mv store ~/ceremonyclient/node/.config
# screen -X -S Quili quit
# screen -dmS Quili bash -c './poor_mans_cd.sh'

##删除此文件
cd ~
rm -f start.sh
