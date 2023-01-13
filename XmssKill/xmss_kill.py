#! -*- coding: utf-8 -*-
#Info: kill xmss
#Author: Theon
#Version: 1.2.1
import subprocess
import os
import shutil
import time
from itertools import chain

class main_fun(object): 
    def __init__(self):
        self.cront_path=["/var/spool/cron/root","/var/spool/cron/crontabs/root","/etc/cron.d/apache","/etc/cron.d/nginx","/etc/cron.d/root","/etc/cron.hourly/oanacroner1"]
        self.init_path=["/etc/init.d/down","/etc/ld.so.preload"]
        self.init_config=["/etc/rc.d/rc.local"]
        self.bin_path=["/usr/sbin/.libs","/usr/sbin/.inis","/usr/sbin/.inid","/tmp/.inis","/tmp/.libs","/usr/sbin/.ini","/tmp/.libd","/usr/sbin/.libd"]
        self.sysctl_path=["/etc/sysctl.conf"]
        self.proc=[".inis",".libs"]
    
    #Star其它
    def infos(self):
        print("\033[1;33;40m 正在为您清理xmss挖矿木马，请稍后... \033[0m")
        time.sleep(3)
        
    #End其它
    def infos_end(self):
        print("\033[1;33;40m 已为您清理完成xmss，请您验证系统资源是否正常！ \033[0m")
        time.sleep(3)
    
    #base网络限制
    def iptables_ban(self):
        try:
            subprocess.call('/usr/sbin/iptables -I OUTPUT -p tcp -m string --string "apacheorg.top" --algo bm -j DROP',shell=True)
            subprocess.call('/usr/sbin/iptables -I OUTPUT -d 107.172.214.23 -j DROP',shell=True)
            subprocess.call('/usr/sbin/iptables -I OUTPUT -d 198.46.202.146 -j DROP',shell=True)
            print("\033[1;32;40m 木马网络已限制 \033[0m")
        except Exception as err:
            pass       
            
    #长期网络限制
    def iptables_input(self):
        with open(self.init_config[0],'a') as file_os:
            file_os.write('/usr/sbin/iptables -I OUTPUT -p tcp -m string --string "apacheorg.top" --algo bm -j DROP \n')  
            file_os.write('/usr/sbin/iptables -I OUTPUT -d 107.172.214.23 -j DROP \n')  
            file_os.write('/usr/sbin/iptables -I OUTPUT -d 198.46.202.146 -j DROP \n')  
    
    #base暂停进程
    def pause_proc(self,poc):
        try:
            subprocess.Popen("ps aux|grep %s|grep -v grep |awk '{print $2}'|xargs kill -STOP" % poc,shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            print("\033[1;32;40m %s \033[0m进程已暂停" % poc) 
        except Exception as err:
            pass
            
    #base停止进程
    def stop_proc(self,poc):
        try:
            subprocess.Popen("ps aux|grep %s|grep -v grep |awk '{print $2}'|xargs kill -9" % poc,shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            print("\033[1;32;40m %s \033[0m进程已停止" % poc) 
        except Exception as err:
            pass
    
    #base降权功能
    def chattr(self,path):  
        try:
            #subprocess.call('/usr/bin/chattr -ia %s' % path,shell=True)
            subprocess.Popen('/usr/bin/chattr -ia %s' % path,shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
            print("\033[1;32;40m %s \033[0m成功去除chattr权限" % path) 
        except Exception as err:
            pass
            
    #base清空文件内容
    def ftruncate(self,path):
        try:
            with open(path,'w') as file_os:
                file_os.write(" ")
            print("\033[1;32;40m %s \033[0m恶意内容已清除" % path)
        except Exception as err:
            pass        
              
    #计划任务降权
    def cron_chattr(self):
        for task in self.cront_path:
            if os.path.exists(task):
                self.chattr(task)
        
    #配置文件降权
    def init_chattr(self):
        for file in self.init_path:
            if os.path.exists(file):                
                self.chattr(file)
        
    #木马文件降权
    def bin_chattr(self):
        for task in self.bin_path:
            if os.path.exists(task):
                self.chattr(task)
            
    #清空恶意文件内容
    def truncate_torjan(self):
        clean_list=[self.cront_path,self.init_path,self.bin_path]
        clean_list=list(chain(*clean_list))
        #print(clean_list)
        for task in clean_list:
            if os.path.exists(task):
                self.ftruncate(task)
            
    #暂停挖矿进程
    def pause_trojan(self):
        for task in self.proc:
            self.pause_proc(task)
            
    #停止挖矿进程
    def stop_trojan(self):
        for task in self.proc:
            self.stop_proc(task)
            
    #恢复sysctl.conf配置
    def restore_sysctl(self):
        for file in self.sysctl_path:
            try:
                bak_file="%s.bak" % file
                shutil.move(file,bak_file)
                with open(bak_file,"r") as src,open(file,"w") as dst:
                    for i in src:
                        if i.count("vm.nr_hugepages") or i.count("kernel.nmi_watchdog"):
                            pass
                        else:
                            #print(i)
                            dst.write(i)
                print("\033[1;32;40m %s \033[0m已恢复" % file)
            except Exception as err:
                print(err)  
            
    #主执行
    def Killing_time(self):
        self.infos()
        self.iptables_ban()    #限制访问挖矿木马下载网站
        self.iptables_input()  #长时间限制访问挖矿木马下载网站
        self.pause_trojan()    #暂停挖矿进程
        self.cron_chattr()     #计划任务降权
        self.init_chattr()     #配置文件降权
        self.bin_chattr()      #木马文件降权
        self.truncate_torjan() #清理恶意文件
        self.stop_trojan()     #结束挖矿进程
        self.restore_sysctl()  #恢复sysctl.conf配置
        self.infos_end()

if __name__ == '__main__':
    version = "1.2.1"
    progam = u'''
 __   __                    _  ___ _ _           
 \ \ / /                   | |/ (_) | |          
  \ V / _ __ ___  ___ ___  | ' / _| | | ___ _ __ 
   > < | '_ ` _ \/ __/ __| |  < | | | |/ _ \ '__|   {Version:%s}
  / . \| | | | | \__ \__ \ | . \| | | |  __/ |      {Author:Theon}
 /_/ \_\_| |_| |_|___/___/ |_|\_\_|_|_|\___|_| 
 
    ''' % version
    print("\033[1;34;40m %s \033[0m" % progam)
    killer=main_fun()
    killer.Killing_time()
    #ps aux|grep .libs|grep -v grep |awk '{print $2}'|xargs kill -STOP
    #vm.nr_hugepages
    #kernel.nmi_watchdog
    