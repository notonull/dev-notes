---
title: Nginx conf配置模板
copyright: CC-BY-4.0
tags:
  - nginx
  - 模板
createTime: 2025/04/13 15:41:43
permalink: /blog/39xnr1uy/
---


## 1.nginx.conf

```markdown
# 启动 8 个工作进程，通常为 CPU 核心数的倍数，能够提高并发处理能力。
worker_processes  8;

events {
    # 每个工作进程最多处理 102400 个连接，设置更高的值有助于提升并发性能。
    worker_connections  102400;
    
    # 启用多连接接受模式，每次工作进程可以接受多个连接，提升性能。
    multi_accept on;
}

http {
    # 引入 mime.types 文件，它包含文件扩展名与 MIME 类型的映射。
    include       mime.types;

    # 默认文件类型为 `application/octet-stream`，用于无法识别的文件类型。
    default_type  application/octet-stream;

    # 定义日志格式，记录请求的详细信息
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    '$status $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';

    # 启用 `sendfile` 系统调用来高效地发送文件
    sendfile     on;

    # 启用 TCP_NOPUSH，配合 sendfile 可以减少系统调用次数，提高文件传输性能。
    tcp_nopush     on;

    # 设置 HTTP Keep-Alive 超时时间为 1800 秒，减少新连接的开销。
    keepalive_timeout  1800s;

    # 设置最大可保持的请求次数为 2000，超过后关闭连接。
    keepalive_requests 2000;

    # 设置字符编码为 utf-8。
    charset utf-8;

    # 配置 server_names_hash 的桶大小，避免服务器名称冲突。
    server_names_hash_bucket_size 128;

    # 设置客户端请求头缓冲区大小，较大的头部可能需要增大该值。
    client_header_buffer_size 2k;

    # 设置最大客户端请求头的缓冲区，默认 4KB，增加此值来支持更大的请求头。
    large_client_header_buffers 4 4k;

    # 设置允许客户端上传的最大请求体大小，默认 1MB，设置为 1024MB。
    client_max_body_size  1024m;

    # 启用文件打开缓存，提高文件访问速度。
    open_file_cache max=102400 inactive=20s;

    # 启用 gzip 压缩，压缩传输内容以节省带宽。
    gzip  on;

    # 设置最小压缩文件大小为 1KB，小于该值的文件不进行压缩。
    gzip_min_length 1k;

    # 设置 gzip 使用的缓冲区大小。
    gzip_buffers 4 16k;

    # 启用 gzip 压缩，并且指定支持的最低 HTTP 协议版本。
    gzip_http_version 1.0;

    # 设置 gzip 压缩级别为 2，压缩和性能之间的平衡。
    gzip_comp_level 2;

    # 指定 gzip 压缩的 MIME 类型。
    gzip_types text/plain application/x-javascript text/css application/xml;

    # 启用 gzip 变体缓存，对于不同的用户代理发送不同的内容。
    gzip_vary on;

    # 设置代理连接超时时间为 75 秒。
    proxy_connect_timeout 75s;

    # 设置代理发送数据的超时时间为 75 秒。
    proxy_send_timeout 75s;

    # 设置代理接收数据的超时时间为 75 秒。
    proxy_read_timeout 75s;

    # 设置 FastCGI 连接的超时时间为 75 秒。
    fastcgi_connect_timeout 75s;

    # 设置 FastCGI 发送数据的超时时间为 75 秒。
    fastcgi_send_timeout 75s;

    # 设置 FastCGI 接收数据的超时时间为 75 秒。
    fastcgi_read_timeout 75s;

    # 引入所有位于 /etc/nginx/conf.d/ 目录下的配置文件。
    include /etc/nginx/conf.d/*.conf;
}

```

## 2.conf.d/*.conf

```markdown
server {
    listen               80;
    server_name          demo.server;
    # server_name          www.server.com;
    add_header Access-Control-Allow-Methods 'GET,POST,OPTIONS';
    add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-	 Control,Content-Type,Authorization,token';

    location /demo/api {
        proxy_set_header   Host $host:80;
        proxy_pass http://127.0.0.1:8998/demo/;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Real-Port $remote_port;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection  "upgrade";
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /demo {
        alias   /opt/server/project/demo/web/;
        index  index.html;
        try_files $uri $uri/ /index.html =404;
    }

}
```

