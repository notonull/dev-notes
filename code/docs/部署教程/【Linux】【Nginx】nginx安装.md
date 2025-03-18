---
title: Linux Nginx Install
copyright: CC-BY-4.0
toc: true
tags:
  - linux
  - nginx
createTime: 2025/03/18 09:00:00
permalink: /blog/iwbpu2lv/
---

### Linux Nginx Install

**How to install and deploy the official package**

##### 1.Official URL
**Official Web:**
http://nginx.org

**Official Download:**
http://nginx.org/en/download.html

**Official Docs**
http://nginx.org/en/docs/

##### 2.Preparation

```shell 
## insetall gcc
yum install gcc-c++
 
## install PCRE pcre-devel
yum install -y pcre pcre-devel
 
## install zlib
yum install -y zlib zlib-devel
 
## instal Open SSL
yum install -y openssl openssl-devel

## or cmd
yum -y install gcc gcc-c++ make libtool zlib zlib-devel openssl openssl-devel pcre pcre-devel
```

##### 3.Upload Package 

 ```shell
## Optional：upload package
cd /opt/plugin/package
rz
## Optional: weget 
 ```
##### 4.Compile And Install

 ```shell
## Optional: compile
## Default Path: /usr/local/nginx
## It is not recommended to change the path;
./configure
## Optional: Change the path;
./configure --prefix=/opt/plugin/nginx
## Optional: Detailed instructions
## reference documentation
## http://nginx.org/en/docs/configure.html
## ./configure --user=nginx --group=nginx--prefix=/usr --with-http_stub_status_module --without-http-cache --with-http_ssl_module --with-http_gzip_static_module --with-ipv6
## install
make install
 ```
##### 5.Common cmd

 ```shell
## cd to installation directory
cd /usr/local/nginx

## To start nginx, run the executable file. Once nginx is started, it can be controlled by invoking the executable with the -s parameter. Use the following syntax:

## start nginx
./nginx 
## fast shutdown
./nginx -s stop
## graceful shutdown
./nginx -s quit
## reloading the configuration file
./nginx -s reload
## reopening the log files
./nginx -s reopen

## nginx master to the nginx.pid in the directory /usr/local/nginx/logs or /var/run.
## For getting the list of all running nginx processes, the ps utility may be used, for example, in the following way:
kill -s QUIT 1628
 ```

##### 4.conf配置推荐

###### 4.1.nginx.conf

```shell
worker_processes  8;
#worker_cpu_affinity 00000001 00000010 000000100 00001000 00010000 00100000 01000000 10000000;

error_log logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

pid        logs/nginx.pid;


events {
    worker_connections  102400;
    #worker_rlimit_nofile 65535;
    multi_accept on;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;
	
    sendfile     on;
    tcp_nopush     on;
    keepalive_timeout  1800s;
    keepalive_requests 2000;
    charset utf-8;
    server_names_hash_bucket_size 128;
    client_header_buffer_size 2k;
    large_client_header_buffers 4 4k;
    client_max_body_size  1024m;
    open_file_cache max=102400 inactive=20s;

    gzip  on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml;
    gzip_vary on;

 # proxy_connect_timeout 75s; 
 # proxy_send_timeout 75s;
 # proxy_read_timeout 75s;
 # fastcgi_connect_timeout 75s;
 # fastcgi_send_timeout 75s; 
 # fastcgi_read_timeout 75s; 
  

  include sites/proxy.conf;
}

```

###### 4.1.2 proxy.conf

```shell

## upstream总入口
include sites/header-upstream.conf;

## 
server {
  listen               80;
  server_name          ceshi.server;
  access_log logs/80.access.log main; 
  ## setting cross
  add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS';
  add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization,token';

    ## web
   location /ceshi/web {
        proxy_pass http://192.168.0.3:8090/;
		proxy_hide_header Server;
		#proxy_set_header        Host $host:8090;
		proxy_set_header X-Real-IP      $remote_addr;
		proxy_set_header X-Forwarded-For $remote_addr;
		
   }
   ## api
   location /ceshi/server/ {
        proxy_pass http://192.168.0.3:8088/;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For     $proxy_add_x_forwarded_for;

   }
# location ~ .*\.(js|css|jpg|jpeg|gif|png|ico|pdf|txt)$ {
#                     proxy_pass http://192.168.0.3:8090;
#					}
   
}

```

###### 4.1.3 header-upstream.conf

```shell
## Optional: Load Balancer Options 

## sso
upstream ceshi_server{ 
     server  192.168.0.3; 
}
```

