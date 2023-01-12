#!/bin/bash
# Info：Trojan clean
# version：1.0.2
# Author：Theon


tempDir=$(mktemp -d)
echo "当前脚本创建临时目录为:"$tempDir

cronPathList=("/etc/crontab" "/var/spool/cron/" "/etc/cron.d/" "/etc/cron.daily/" "/etc/cron.hourly/" "/etc/cron.monthly/" 
            "/etc/cron.weekly/" "/etc/init.d" "/etc/rc.d/" "/etc/rc.local")
CommonCmdList=(ps netstat top find kill pkill ls grep wget curl lsattr chattr cp tar unzip awk chmod mv)
declare -A cmdPackageNameDict
# 兼容性考虑，低版本bash不支持字典写法
cmdPackageNameDict=(
    ['ps']='procps'
    ['netstat']='net-tools'
    ['find']='findutils'
    ['kill']='util-linux'
    ['pkill']='procps'
    ['ls']='coreutils'
    ['grep']='grep'
    ['wget']='wget'
    ['curl']='curl'
    ['lsattr']='e2fsprogs'
    ['chattr']='e2fsprogs'
    ['cp']='coreutils'
    ['tar']='tar'
    ['unzip']='unzip'
)

# echo ${cmdPackageNameDict['lsattr']}


www(){
    cronKeyWordList=("xmss" )
    minerDescription="8220挖矿家族木马"
    minerFileList=("/usr/sbin/.rsyslogds" "/usr/sbin/.rsyslogds.sh" "/usr/sbin/.inis")
    
    checkMinerFileList $minerFileList 2
    if [ $? -ne 0 ]; then return 1; fi
    echo '已匹配到相关特征为：'$minerDescription
    cronCleanUp $cronKeyWordList
    killMinerProcess .rsyslogds .inis
}

teamtnt(){ 
    cronKeyWordList=("htxreceive.top" "185.117.75.175" "/usr/bin/cdz")
    minerDescription="TeamTNT家族挖矿木马"
    minerFileList=("/var/.httpd/.../" "/usr/local/bin/pnscan" "/var/tmp/.psla" "/var/tmp/.apache/" "/var/tmp/..." "/etc/.../.ice-unix/" "/etc/.httpd/"
    "/var/tmp/.system" "/root/.docker" "/usr/share/[scan]" "/vat/tmp/.share" "/usr/share/[ddns]" "/bin/ps.lanigiro" "/usr/bin/cdz"
    "/etc/systemd/system/default.target.wants/apache4.service"  "/etc/systemd/system/default.target.wants/pastebin.service" 
    "/etc/systemd/system/default.target.wants/xvf.service" "/etc/systemd/system/multi-user.target.wants/pnsd.service")
    
    checkMinerFileList $minerFileList 0
    if [ $? -ne 0 ]; then return 1; fi
    echo '已匹配到相关特征为：'$minerDescription
    cronCleanUp $cronKeyWordList
    killMinerProcess httpd pnscan masscan [ext4] [scan] [ddns]
    checkUserSshkeys pending.com
    checkUserSshkeys "puppetserver"
    checkUserSshkeys pending.com
    checkUserSshkeys root@puppetserver

    sed -i '/.ddns/d' /root/.bashrc

}


gitlabMiner(){
    cronKeyWordList=("pastebin" "oracleservice")
    minerDescription="gitlab挖矿家族木马"
    minerFileList=("/tmp/.gitlab/" "/tmp/.gitlabw" "/tmp/.shanbe/" "/tmp/juma" "/tmp/.ssh" "/tmp/system" "/tmp/bashirc" )
    
    checkMinerFileList $minerFileList -1
    if [ $? -ne 0 ]; then return 1; fi
    echo '已匹配到相关特征为：'$minerDescription
    cronCleanUp $cronKeyWordList
    killMinerProcess kthreaddw .gitlabw juma rodolf.sh bashirc system redis.sh
}



killMinerProcess(){
    for process in "$@"; do
        for pid in $(ps -ef | grep -v grep | grep -F $process|awk '{print $1}'); do
            if  kill -9 $pid  ;then #&>/dev/null
            echo '挖矿木马相关进程 '$process $pid' 清理完成！'
            fi
        done
    done
}

checkMinerFileList(){
    # 接收两个参数 
    # minerFileList 挖矿特征文件数组
    # fileMatchCounter 特征文件匹配数量，大于该值时确定为该挖矿家族
    minerFileList=$1 && fileMatchCounter=$2
    if [ ! $fileMatchCounter ]; then $fileMatchCounter=0; fi
    filesCount=0
    for file in ${minerFileList[@]}; do
        if [ -e $file ]; then 
            echo "检测存在挖矿木马特征文件："$file
            backupOrMove "br" $file
            let filesCount+=1
        fi
    done
    if [ $filesCount -gt $fileMatchCounter ]; then
        return 0
    fi 
    return 1
}



checkUserSshkeys(){
    keyWord=$1
    chattr -ai /etc/passwd /etc/shadow
    for userHomePath in $(awk -F: '$NF~"sh"{print$6}' /etc/passwd); do
        sshkeyPath=$userHomePath'/.ssh/'
        if [ -e $sshkeyPath ]; then
            # echo $(grep -irnl $keyWord $sshkeyPath)
            for file in $(grep -irnl $keyWord $sshkeyPath); do
                echo "匹配到挖矿木马ssh后门密钥"$file
                backupOrMove 'b' $file
                sed -i '/'$keyWord'/d' $file && echo $file"挖矿后门密钥清理完成"
            done
        fi
    done
}

deleteEvalUser(){
    backupOrMove "br" "/home/"$1
    userdel "$1"
}


cronCleanUp(){
    # 清理定时任务中的挖矿关键字
    cronKeyWordList=$1
    for keyWord in ${cronKeyWordList[@]}; do
        for path in ${cronPathList[@]}; do
            chattr -R -ai $path &>/dev/null
            for file in $(grep -irnF "$keyWord" $path |awk -F: '{print $1}'); do   #每次遍历一个文件名
                echo "检测到 ${file} 文件中存在恶意定时任务！"
                backupOrMove 'b' $file 
                sed -i '/'$keyWord'/d' $file && echo $file"已清除恶意定时任务！"
            done
        done
    done
}

checkDockerMiner(){
    # minerList="$@"
    if docker -v &>/dev/null; then 
        return 1
    fi
    docker ps | grep "pocosow" | awk '{print $1}' | xargs -I % docker kill %
    docker images -a | grep "slowhttp" | awk '{print $3}' | xargs -I % docker rmi -f %
}

cleanUpPreparation(){
    chattr -R -ai /etc/ &>/dev/null
    echo "清理挖矿前暂时停止定时任务"
    systemctl stop $cronNmae
    systemctl stop atd
}

checkUser(){
    if [ ! $(id -u) -eq 0 ]; then
        echo "请使用root用户权限执行脚本！"
        exit 1
    fi
}

checkOS(){
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        export ID
    fi
    if [ $ID == 'centos' ];then 
        install='yum reinstall -y -q '
        cronNmae='crond'
    else
        install='apt-get install -y -q '
        cronNmae='cron'
    fi
    export install cronNmae
}

finishWork(){
    if systemctl start $cronNmae atd; then 
        echo "定时任务重启成功！"
    else
        systemctl status $cronNmae atd
        echo "定时任务重启失败..."
    fi
}

backupOrMove(){
    # 为保证数据安全，脚本中所有的操作均不做删除操作
    # 清理行为只包括复制或移动文件路径
    action=$1 && shift
    for file in "$@"; do
        echo $file
        chattr -R -ai $file &>/dev/null
        chmod -x $file &>/dev/null
        if [ $action == "b" ]; then 
            cp -r "$@" $tempDir #&>/dev/null
        elif [ $action == "br" ];then
            mv "$@" $tempDir #&>/dev/null 
        fi
    done
}

fixMissingCmd(){
    cmd=$1
    packageName=${cmdPackageNameDict["$cmd"]}
    installCmd=$install' '$packageName
    if [ ! -n $packageName ]; then 
        echo '命令 '$cmd' 无法找到对应的包名，安装失败！'
        return 2
    elif $($installCmd) &>/dev/null; then
        echo '命令'$cmd'已重装成功！'
        return 0
    else
        echo '命令'$cmd'安装失败！'
        return 1
    fi
}

checkSystemCmd(){
    chattr -R -ai /usr/bin/
    echo "正在检测系统命令是否被替换..."
    for cmd in ${CommonCmdList[@]}; do
        # which $cmd &>/dev/null
        if ! which $cmd &>/dev/null ; then 
            echo '检测到系统命令 '$cmd' 存在缺失,正在对命令进行修复...'
            if ! fixMissingCmd $cmd ;then
                echo "检查 $cmd 命令存在异常"
            fi
        fi
        if [ $ID == 'centos' ]; then
            if ! rpm -Vf $(which $cmd) &>/dev/null ; then
                # backupOrMove 'br' $(which $cmd)
                echo '检测到系统命令 '$cmd' 被替换'
                fixMissingCmd $cmd
            fi
        fi
    done

}

killHighCPUProcess(){
    # busybox 的ps命令为阉割版，只能通过top命令获取CPU使用率
    echo "kill高cpu占用率进程"
    for pid in $(top -bn 1 | awk 'NR>4 && $8>70{print $1}'); do
        echo '检测到进程 '$pid' CPU占用率超过70%'
        chmod -x $(readlink '/proc/'$pid'exe')
        kill -9 $pid
    done
}


TraverseAllProcess(){
    # 遍历所有的进程信息
    echo "遍历所有的进程信息"
    for pid in $( ps |awk 'NR>1{print $1}'); do
        exePath="/proc/$pid/exe"
        cmdlinePath="/proc/$pid/cmdline"
        exeRealPath=$(readlink $exePath) 2>/dev/null
        chattr -ai $exeRealPath &>/dev/null
        if [[ $exeRealPath =~ '(deleted)' ]];then
            echo "检测到可疑进程："$exeRealPath
            backupOrMove "b" $exePath
            kill -9 $pid
        elif [[ $exeRealPath =~ '/tmp/' ]];then
            echo "检测到可疑tmp目录进程: "$exeRealPath
            backupOrMove "br" $exeRealPath
            chmod -x $exeRealPath
            kill -9 $pid
        elif [[ $exeRealPath =~ 'bin/bash' ]]; then
            suspectFilePath=$(strings $cmdlinePath |sed -n '2p')
            if [[ $suspectFilePath =~ 'main.sh' ]]; then
                # 匹配到脚本自己就跳过
                continue
            elif [ ! $suspectFilePath ]; then
                continue
            fi
            echo '检测到可疑进程使用bash'
            echo $suspectFilePath
            if file $suspectFilePath | grep -q script ; then
                echo '请检查 '$suspectFilePath' 是否为恶意脚本文件'
                chmod -x $suspectFilePath
                backupOrMove "b" $suspectFilePath
                kill -9 $pid
            else
                chmod -x $suspectFilePath
                kill -9 $pid
            fi
        fi
    done
}


findRecentChangedFiles(){
    # 查找最近3天内的文件变动
    echo "查找最近3天内的文件变动"
    cmd="find /etc /tmp /usr /root /var /lib  -maxdepth 3 -mtime -3 -ctime -3 -type f  -executable ! -name main.sh ! -name busybox"  # 记得修改这里！！！！！
    for executeFile in $($cmd 2>/dev/null); do
        echo $executeFile
        chattr -ia $executeFile 
        chmod -x $executeFile
        echo '正在备份3天内的可执行文件 '$executeFile
        backupOrMove "br" $executeFile
    done
}

removeTmpPathFilesXmod(){
    tmpDirs=("/tmp/" "/var/tmp/")
    for dir in ${tmpDirs[@]}; do
        echo "正在取消 "$dir" 目录下文件的可执行权限"
        chattr -R -ai $dir
        chmod -R -x $dir
    done
}



checkPreloadSo(){
    path="/etc/ld.so.preload"
    if [ -s  $path ]; then
        echo "检测到预加载加持，正在清理..."
        for file in $(cat $path | awk '{print $0}'); do
            if [ -f $file ]; then
                echo '检测到恶意预加载so文件：'$file
                chmod -x $file 
                backupOrMove "br" $file
            fi
        done
        backupOrMove "br" /etc/ld.so.preload
    fi
}


fixDnsResolv(){
    resolvFile='/etc/resolv.conf'
    chattr -ia $resolvFile
    backupOrMove 'br' $resolvFile
    echo -e "nameserver 183.60.82.98\nnameserver 183.60.83.19" >$resolvFile
    echo "DNS解析重置成功！"
}


reInstallYunJingAndMonitor(){
    if ps -ef | grep -v grep | grep -q /usr/local/qcloud/YunJing/YD; then
        echo '云镜正常运行！'
        return 0
    fi
    echo '正在重新安装云镜和云监控...'
    wget -q https://imgcache.qq.com/qcloud/csec/yunjing/static/ydeyesinst_linux64.tar.gz -O ydeyesinst_linux64.tar.gz && tar zxf ydeyesinst_linux64.tar.gz   
    bash self_cloud_install_linux64.sh &>/dev/null
    if ps -ef| grep -v grep | grep -q /usr/local/qcloud/YunJing/YD ; then
        echo "云镜安装成功！"
    fi
    wget -q http://update2.agent.tencentyun.com/update/linux_stargate_installer -O /tmp/stargate && chmod +x /tmp/stargate 
    bash /tmp/stargate &>/dev/null
    if ps ax |grep -v grep |grep -q barad_agent ; then
        rm -f /tmp/stargate
        echo "云主机监控安装成功！"
    fi
}

checkSystemdServices(){
    # 查找最近3天内的服务变动
    echo "查找最近3天内的系统服务变动"
    servicePath='/etc/systemd/system/'
    cmd="find $servicePath -mtime -3 -type f"  
    for serviceFile in $($cmd 2>/dev/null); do
        chattr -ia $serviceFile 
        echo '正在备份3天内的系统服务文件，并停止服务： '$serviceFile
        serviceName=${serviceFile##*/}
        systemctl stop $serviceName &>/dev/null
        systemctl disable $serviceName &>/dev/null
        backupOrMove "b" $serviceFile
    done
}

installBusybox(){
    busyboxMd5='53447624959128f8e0c833ddc397693f'

    if which busybox &>/dev/null ; then
        # 判断当前系统中是否存在busybox，且路径不在/usr/bin目录下
        currentBusyboxMd5=$(md5sum $(which busybox) | cut -d' ' -f1 )
        if [ $currentBusyboxMd5 != $busyboxMd5 ]; then
            backupOrMove "br" $(which busybox)
        fi
    fi

    if [[ -f $busyboxPath  && $(md5sum $busyboxPath | cut -d' ' -f1) == $busyboxMd5  ]]; then
        # 判断当前系统中/usr/bin目录下的busybox
        echo "检测到busybox已安装！"
        chmod +x $busyboxPath
    else
        backupOrMove "br" $busyboxPath &>/dev/null # 避免下载覆盖的情况
        echo "正在下载安装busybox！"
        if downloadBusybox ; then 
            if [[ -f $busyboxPath  && $(md5sum $busyboxPath | cut -d' ' -f1) == $busyboxMd5  ]]; then
                chmod +x $busyboxPath
                echo "busybox 下载安装成功！"
            else
                echo "busybox 下载失败，请从 "$busyboxUrl" 下载后上传到主机的/usr/bin/目录下"
                echo "脚本退出执行！"
                exit 1
            fi
        fi
    fi

    echo "将使用busybox代替系统命令执行"
    for cmd in ${CommonCmdList[@]}; do
        # alias $cmd='busybox '$cmd
        # echo "function $cmd(){ busybox $cmd \"\$@\"; }"
        eval "function $cmd(){ busybox $cmd \"\$@\"; }"
    done
}

downloadBusybox(){
    busyboxPath='/usr/bin/busybox'
    busyboxUrl="http://zgao.top:8000/busybox-x86_64"

    if checkDownloadCommand wget ; then
        if wget $busyboxUrl -O $busyboxPath 2>/dev/null ; then return 0; fi
    fi
    
    if checkDownloadCommand curl ; then
        if curl $busyboxUrl -o $busyboxPath 2>/dev/null ; then return 0; fi
    fi

    if checkDownloadCommand python ; then # 修改变量记得修改这里字符串的值！！！！！！
        code='import urllib2;open("/usr/bin/busybox","wb").write(urllib2.urlopen("http://zgao.top:8000/busybox-x86_64").read())'
        if python -c "$code"  ; then return 0; fi
    fi

    DOWNLOAD $busyboxUrl > $busyboxPath

}

checkDownloadCommand(){
    # 检测系统中的wget，curl，Python等可实现下载功能的命令是否可用
    checkUrl='http://zgao.top/vmess'
    case $1 in 
    wget)
        if wget -q -O - $checkUrl &>/dev/null ; then return 0 ; fi
        ;;
    curl)
        if curl $checkUrl &>/dev/null ; then return 0 ; fi
        ;;
    python)
        if python -c 'import urllib2;urllib2.urlopen("http://zgao.top/vmess").read()' &>/dev/null ; then return 0 ; fi
        ;;
    *)
        return 1
    esac
}


DOWNLOAD() {
    read proto server path <<<$(echo ${1//// })
    DOC=/${path// //}
    HOST=${server//:*}
    PORT=${server//*:}
    [[ x"${HOST}" == x"${PORT}" ]] && PORT=80

    exec 3<>/dev/tcp/${HOST}/$PORT
    echo -en "GET ${DOC} HTTP/1.0\r\nHost: ${HOST}\r\n\r\n" >&3
    (while read line; do
    [[ "$line" == $'\r' ]] && break
    done && cat) <&3
    exec 3>&-
}

cronFullCleanUp(){
    # 在处理未知挖矿样本时，清空3天内的发生变动的定时任务文件。慎用！
    for path in ${cronPathList[@]}; do
        chattr -R -ai $path &>/dev/null
        for file in $(find $path -mtime -3 -type f); do
            echo "正在备份定时任务相关文件："$file
            backupOrMove "br" $file
            touch $file 
        done
    done
}


main(){
    # 执行函数的调用顺序
    checkUser  #检测脚本执行用户
    checkOS    #检测操作系统
    installBusybox #安装busboy
    cleanUpPreparation #去除定时任务权限，并停止定时任务
    removeTmpPathFilesXmod #去除/tmp /var/tmp目录chattr和执行权限
    checkSystemdServices  #移除和停止3天内注册的系统服务器（censo7.X版本以下可能不支持）---->【可能存在风险】
    TraverseAllProcess #异常进程检测，主要检测delete、tmp带script脚本执行特征的进程，同时kill进程，移除执行的进程文件和脚本文件
    killHighCPUProcess #检测并kill -9 CPU使用率超过70的进程
    # www
    # teamtnt
    # gitlabMiner
    cronFullCleanUp   #清理近3天创建的计划任务（如云镜、云监控等组件在3天内更新过，可能计划任务也会被清除）---->【可能存在风险】
    findRecentChangedFiles #清理/etc /tmp /usr /root /var /lib目录下除busybox和main.sh清理脚本之外近3天创建的文件，---->【可能存在风险】
    TraverseAllProcess     #清理完文件后，再次检测和清理异常进程，主要检测delete、tmp带script脚本执行特征的进程，同时kill进程，移除执行的进程文件和脚本文件
    checkPreloadSo         #busybox检测动态链接库ld.so.preload
    checkSystemCmd         #检测系统命令是否缺失或者被替换，如缺失或被替换则根据操作系统，使用命令重新安装
    fixDnsResolv		   #重置DNS解析，只对腾讯云公有云私有网络有效
    killHighCPUProcess     #再次清理高CPU进程，检测并kill -9 CPU使用率超过70的进程
    reInstallYunJingAndMonitor #重装云镜，公有云私有网络
    finishWork			   #尝试恢复定时任务
}


main