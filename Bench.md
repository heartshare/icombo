Test Environment:  
Centos 5.9 i386, 2core cpu, 1G memory  
nginx/1.6.2  

===== icombo =====
```bash
ab -c 1000 -n 10000 http://x.x.x.x/icombo?f=static/index/header.css,static/index/footer.css,static/index/reset.css
Requests per second:    1668.94 [#/sec] (mean)
Time per request:       599.182 [ms] (mean)
Time per request:       0.599 [ms] (mean, across all concurrent requests)

```

===== http_concat_module =====
```bash
ab -c 1000 -n 10000 http://x.x.x.x/??static/index/header.css,static/index/footer.css,static/index/reset.css
Requests per second:    1292.88 [#/sec] (mean)
Time per request:       773.468 [ms] (mean)
Time per request:       0.773 [ms] (mean, across all concurrent requests)

```

===== php minify =====
```bash
ab -c 1000 -n 10000 http://x.x.x.x/min/?f=static/index/header.css,static/index/footer.css,static/index/reset.css
Requests per second:    1114.32 [#/sec] (mean)
Time per request:       897.405 [ms] (mean)
Time per request:       0.897 [ms] (mean, across all concurrent requests)

```