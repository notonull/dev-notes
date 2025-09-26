import{_ as i,e as n,f as a,o as e}from"./app-auXT20Bu.js";const l={};function p(t,s){return e(),n("div",null,s[0]||(s[0]=[a(`<h2 id="_1-nginx-conf" tabindex="-1"><a class="header-anchor" href="#_1-nginx-conf"><span>1.nginx.conf</span></a></h2><div class="language-markdown line-numbers-mode" data-highlighter="shiki" data-ext="markdown" style="--shiki-light:#393a34;--shiki-dark:#dbd7caee;--shiki-light-bg:#ffffff;--shiki-dark-bg:#121212;"><pre class="shiki shiki-themes vitesse-light vitesse-dark vp-code"><code><span class="line"><span style="--shiki-light:#999999;--shiki-light-font-weight:bold;--shiki-dark:#666666;--shiki-dark-font-weight:bold;">#</span><span style="--shiki-light:#1C6B48;--shiki-light-font-weight:bold;--shiki-dark:#4D9375;--shiki-dark-font-weight:bold;"> 启动 8 个工作进程，通常为 CPU 核心数的倍数，能够提高并发处理能力。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">worker_processes  8;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">events {</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 每个工作进程最多处理 102400 个连接，设置更高的值有助于提升并发性能。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    worker_connections  102400;</span></span>
<span class="line"><span style="--shiki-light:#1C6B48;--shiki-dark:#4D9375;">    </span></span>
<span class="line"><span style="--shiki-light:#1C6B48;--shiki-dark:#4D9375;">    # 启用多连接接受模式，每次工作进程可以接受多个连接，提升性能。</span></span>
<span class="line"><span style="--shiki-light:#1C6B48;--shiki-dark:#4D9375;">    multi_accept on;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">}</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">http {</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 引入 mime.types 文件，它包含文件扩展名与 MIME 类型的映射。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    include       mime.types;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 默认文件类型为 </span><span style="--shiki-light:#999999;--shiki-dark:#666666;">\`</span><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">application/octet-stream</span><span style="--shiki-light:#999999;--shiki-dark:#666666;">\`</span><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">，用于无法识别的文件类型。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    default_type  application/octet-stream;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 定义日志格式，记录请求的详细信息</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    log_format  main  &#39;$remote_addr - $remote_user </span><span style="--shiki-light:#999999;--shiki-dark:#666666;">[</span><span style="--shiki-light:#B56959;--shiki-dark:#C98A7D;">$time_local</span><span style="--shiki-light:#999999;--shiki-dark:#666666;">]</span><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;"> &quot;$request&quot; &#39;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    &#39;$status $body_bytes_sent &quot;$http_referer&quot; &#39;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    &#39;&quot;$http_user_agent&quot; &quot;$http_x_forwarded_for&quot;&#39;;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 启用 </span><span style="--shiki-light:#999999;--shiki-dark:#666666;">\`</span><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">sendfile</span><span style="--shiki-light:#999999;--shiki-dark:#666666;">\`</span><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;"> 系统调用来高效地发送文件</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    sendfile     on;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 启用 TCP_NOPUSH，配合 sendfile 可以减少系统调用次数，提高文件传输性能。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    tcp_nopush     on;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置 HTTP Keep-Alive 超时时间为 1800 秒，减少新连接的开销。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    keepalive_timeout  1800s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置最大可保持的请求次数为 2000，超过后关闭连接。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    keepalive_requests 2000;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置字符编码为 utf-8。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    charset utf-8;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 配置 server_names_hash 的桶大小，避免服务器名称冲突。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    server_names_hash_bucket_size 128;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置客户端请求头缓冲区大小，较大的头部可能需要增大该值。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    client_header_buffer_size 2k;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置最大客户端请求头的缓冲区，默认 4KB，增加此值来支持更大的请求头。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    large_client_header_buffers 4 4k;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置允许客户端上传的最大请求体大小，默认 1MB，设置为 1024MB。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    client_max_body_size  1024m;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 启用文件打开缓存，提高文件访问速度。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    open_file_cache max=102400 inactive=20s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 启用 gzip 压缩，压缩传输内容以节省带宽。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip  on;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置最小压缩文件大小为 1KB，小于该值的文件不进行压缩。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip_min_length 1k;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置 gzip 使用的缓冲区大小。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip_buffers 4 16k;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 启用 gzip 压缩，并且指定支持的最低 HTTP 协议版本。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip_http_version 1.0;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置 gzip 压缩级别为 2，压缩和性能之间的平衡。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip_comp_level 2;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 指定 gzip 压缩的 MIME 类型。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip_types text/plain application/x-javascript text/css application/xml;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 启用 gzip 变体缓存，对于不同的用户代理发送不同的内容。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    gzip_vary on;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置代理连接超时时间为 75 秒。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    proxy_connect_timeout 75s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置代理发送数据的超时时间为 75 秒。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    proxy_send_timeout 75s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置代理接收数据的超时时间为 75 秒。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    proxy_read_timeout 75s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置 FastCGI 连接的超时时间为 75 秒。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    fastcgi_connect_timeout 75s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置 FastCGI 发送数据的超时时间为 75 秒。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    fastcgi_send_timeout 75s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 设置 FastCGI 接收数据的超时时间为 75 秒。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    fastcgi_read_timeout 75s;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # 引入所有位于 /etc/nginx/conf.d/ 目录下的配置文件。</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    include /etc/nginx/conf.d/*.conf;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">}</span></span></code></pre><div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0;"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div><h2 id="_2-conf-d-conf" tabindex="-1"><a class="header-anchor" href="#_2-conf-d-conf"><span>2.conf.d/*.conf</span></a></h2><div class="language-markdown line-numbers-mode" data-highlighter="shiki" data-ext="markdown" style="--shiki-light:#393a34;--shiki-dark:#dbd7caee;--shiki-light-bg:#ffffff;--shiki-dark-bg:#121212;"><pre class="shiki shiki-themes vitesse-light vitesse-dark vp-code"><code><span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">server {</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    listen               80;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    server_name          demo.server;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    # server_name          www.server.com;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    add_header Access-Control-Allow-Methods &#39;GET,POST,OPTIONS&#39;;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    add_header Access-Control-Allow-Headers &#39;DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-	 Control,Content-Type,Authorization,token&#39;;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    location /demo/api {</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_set_header   Host $host:80;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_pass http://127.0.0.1:8998/demo/;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_set_header   X-Real-IP $remote_addr;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_set_header   X-Real-Port $remote_port;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_set_header   Upgrade $http_upgrade;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_set_header   Connection  &quot;upgrade&quot;;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_connect_timeout 300s;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_send_timeout 300s;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        proxy_read_timeout 300s;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    }</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    location /demo {</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        alias   /opt/server/project/demo/web/;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        index  index.html;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">        try_files $uri $uri/ /index.html =404;</span></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">    }</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#393A34;--shiki-dark:#DBD7CAEE;">}</span></span></code></pre><div class="line-numbers" aria-hidden="true" style="counter-reset:line-number 0;"><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div><div class="line-number"></div></div></div>`,4)]))}const r=i(l,[["render",p],["__file","index.html.vue"]]),h=JSON.parse(`{"path":"/blog/39xnr1uy/","title":"Nginx conf配置模板","lang":"zh-CN","frontmatter":{"title":"Nginx conf配置模板","copyright":"CC-BY-4.0","tags":["nginx","模板"],"createTime":"2025/04/13 15:41:43","permalink":"/blog/39xnr1uy/","description":"1.nginx.conf 2.conf.d/*.conf","head":[["meta",{"property":"og:url","content":"https://notonull.github.io/dev-notes/blog/39xnr1uy/"}],["meta",{"property":"og:site_name","content":"aGeng 's Blog"}],["meta",{"property":"og:title","content":"Nginx conf配置模板"}],["meta",{"property":"og:description","content":"1.nginx.conf 2.conf.d/*.conf"}],["meta",{"property":"og:type","content":"article"}],["meta",{"property":"og:locale","content":"zh-CN"}],["meta",{"property":"og:updated_time","content":"2025-09-26T17:22:13.000Z"}],["meta",{"property":"article:tag","content":"nginx"}],["meta",{"property":"article:tag","content":"模板"}],["meta",{"property":"article:modified_time","content":"2025-09-26T17:22:13.000Z"}],["script",{"type":"application/ld+json"},"{\\"@context\\":\\"https://schema.org\\",\\"@type\\":\\"Article\\",\\"headline\\":\\"Nginx conf配置模板\\",\\"image\\":[\\"\\"],\\"dateModified\\":\\"2025-09-26T17:22:13.000Z\\",\\"author\\":[]}"]]},"headers":[],"readingTime":{"minutes":2.54,"words":762},"git":{"updatedTime":1758907333000,"contributors":[{"name":"ronggeng.chen","username":"ronggeng.chen","email":"chen.ronggeng.email@gmail.com","commits":3,"avatar":"https://avatars.githubusercontent.com/ronggeng.chen?v=4","url":"https://github.com/ronggeng.chen"},{"name":"ops_chengeng","username":"ops_chengeng","email":"ops_chengeng@demo.com","commits":1,"avatar":"https://avatars.githubusercontent.com/ops_chengeng?v=4","url":"https://github.com/ops_chengeng"}]},"autoDesc":true,"filePathRelative":"代码模板/Nginx conf配置模板.md","categoryList":[{"id":"6d4f3e","sort":10003,"name":"代码模板"}]}`);export{r as comp,h as data};
