# Prompt
ChatGPT can you help create an nginx.conf file that performs the following requirements? 
1. It is production grade secure
2. the upstream server is at ip 10.100.2.175
3. http calls are redirected to https
4. http and https calls to dirks-nz.mel.cloudlets.com.au are redirected to dirks.nz (using the same request_uri)
5. the ssl certificate is available in /var/lib/jelastic/SSL, folder, files jelastic.chain and jelastic.key

# Response

Certainly! Here's a production-grade `nginx.conf` that meets all your specified requirements.

```nginx
# NGINX Configuration

user  nginx;
worker_processes  auto;

# Error log and PID file
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

# Events Block
events {
    worker_connections  1024;
}

# HTTP Block for configuration
http {
    # Security headers for production
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Hide Nginx version for security reasons
    server_tokens off;

    # Set upstream server
    upstream backend {
        server 10.100.2.175:80;
    }

    # Redirect all HTTP traffic to HTTPS
    server {
        listen 80;
        server_name dirks-nz.mel.cloudlets.com.au dirks.nz;

        # Redirect http to https
        return 301 https://$host$request_uri;
    }

    # HTTPS Server Block
    server {
        listen 443 ssl;
        server_name dirks-nz.mel.cloudlets.com.au dirks.nz;

        # SSL Configuration
        ssl_certificate     /var/lib/jelastic/SSL/jelastic.chain;
        ssl_certificate_key /var/lib/jelastic/SSL/jelastic.key;
        ssl_protocols       TLSv1.2 TLSv1.3; # Only allow secure TLS versions
        ssl_prefer_server_ciphers on;
        ssl_ciphers         "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256";
        ssl_session_cache   shared:SSL:10m;
        ssl_session_timeout 1h;

        # Redirect dirks-nz.mel.cloudlets.com.au to dirks.nz
        if ($host = 'dirks-nz.mel.cloudlets.com.au') {
            return 301 https://dirks.nz$request_uri;
        }

        # Proxy pass to upstream server
        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Security: Disable unwanted methods
        if ($request_method !~ ^(GET|POST|HEAD)$ ) {
            return 405;
        }

        # Deny access to sensitive files
        location ~ /\.ht {
            deny all;
        }
    }

    # gzip compression for performance
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_proxied any;
    gzip_vary on;
}
```

### Key Points:
1. **Security Enhancements**:
   - Security headers such as `X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security` for secure production.
   - `ssl_protocols` set to only secure TLS versions (TLS 1.2 and 1.3).
   - Strong `ssl_ciphers` for secure connections.
   - `server_tokens off` to hide the Nginx version.
   
2. **HTTP to HTTPS redirection**:
   - All traffic on port 80 is redirected to HTTPS using a `301` redirect.

3. **Host Redirection**:
   - Requests to `dirks-nz.mel.cloudlets.com.au` are redirected to `dirks.nz` while keeping the same `request_uri`.

4. **SSL Configuration**:
   - The SSL certificate and key are loaded from the specified directory.

5. **Upstream**:
   - Requests are proxied to the upstream server at `10.100.2.175`.

This configuration is secure, handles HTTPS redirection, and meets all your requirements for a production environment. Let me know if you need any adjustments! ✔️