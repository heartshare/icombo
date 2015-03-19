# iCombo: 类似于Minify，可以合并CSS、JS文件、减少连接数
iCombo提供比Minify、concat模块更好的并发性能，iCombo，你值得拥有！    
iCombo已经在百万PV的网站正常使用，你值得试试！  
同时欢迎你提出宝贵建议。 

## 特性
* 兼容minify的 f 参数，如 ?f=1.css,2.css,3.css  
* 可以将图片的相对路径，替换为域名的方式   
* 压缩CSS的代码（删除注释、换行、精简颜色等）  
* 一键删除服务器的所有缓存文件  
* 错误日志记录

## 环境要求
Nginx + ngx_lua + LuaJIT  

## 安装lua posix库:  
```bash
# wget http://git.alpinelinux.org/cgit/luaposix/snapshot/luaposix-5.1.8.tar.bz2
# tar jxvf luaposix-5.1.8.tar.bz2
# cd luaposix-5.1.8
# vi Makefile
  LUAINC=         $(PREFIX)/include/luajit-2.0
# make CC=gcc
# make install CC=gcc
```

## 配置nginx：  
1. 将icombo目录，放至/usr/local/nginx/conf/目录  
2. 修改配置文件：  
```bash
 http {
    location = / {
        set $cache_dir "/dev/shm/icombo/";
        set $css_trim "on";
        set $max_files 20;
        set $admin_ip "192.168.8.63,192.168.8.181";
        content_by_lua_file /usr/local/nginx/conf/icombo/icombo.lua;
    }
    location /icombo_sub/ {
        alias /dev/shm/icombo/;
        internal;
    }
 }
```
## 访问URL：  
http://x.x.x.x/?f=static/index/header.css,static/index/footer.css

## 常用功能  
* 自定义CSS、JS目录（默认在当前目录）
```bash
set $css_dir "include/css/";
set $js_dir  "include/javascript/";
```
* 多个图片路径替换：  
采用 | 分隔，替换多个路径：  
```bash
set $css_replace "../../../images,http://images.xxx.com|../../../ck,http://images.xxx.com";
```
* 开启清除CSS注释功能：
```bash
set $css_trim "on";
```
* 根据CSS目录，自动替换图片相对路径：
```bash
set $css_path_auto "images/";
```
* 设置合并的最大文件数：
```bash
set $max_files 20;
```
* 删除服务器的所有缓存文件（慎用）：  
配置$admin_ip：
```bash
set $admin_ip "192.168.8.63,192.168.8.181";  
```
链接增加&c=1即可，页面内容显示sucess即成功：  
http://x.x.x.x/?f=static/index/header.css,static/index/footer.css&c=1

## 感谢 
感谢Nginx   http://nginx.org  
感谢LuaJIT  http://luajit.org/  
感谢春哥    http://www.weibo.com/agentzh
