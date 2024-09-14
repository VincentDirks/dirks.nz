# dirks.nz - Repo
Responsible for deploying dirks.nz online resources using (docker-)compose.yml file for deploying a node.js image to a node on my account with app.cloudlets.com.au

This readme aims to document all steps needed to deploy to new environment, as well as details for upgrading parts of the environment. 

And if the cloudlet is up and running you can access it below 
* https://dirks-nz.mel.cloudlets.com.au or
* https://dirks.nz

## Instructions
1. Navigate and log into https://cloudlets.com.au/ (I have 2FA turned on). This should take you to the cloudlets dashboard. 
1. Navigate to `+ NEW ENVIRONMENT` &DoubleRightArrow; `Custom` &DoubleRightArrow; click `▼` &DoubleRightArrow; `Docker Engine`
   1. Select `Deploy containers from compose.yml`
   1. Enter `Compose Repo` field with the repo that contains the `compose.yml` file (probably this repo)
   1. Accept or update the `Environment` field (this is the URL via the Cloudlets Shared Load Balancer - SLB)
   1. Click `Install` &DoubleRightArrow; this will take a moment to complete.
   * Notes:
        1. The `Compose Repo` setting is only availble and shown when creating a new environment
        1. The repo also should have the files `docker-compose.service` and `setupServiceDaemon.sh`
        1. The application should also be in the repo

1. Hover of the `[environment]` &DoubleRightArrow; click `Change Environment Topology` (icon with gear over 3 blocks) &DoubleRightArrow; to configure the environment
   * `SSL` 
      * `Built-In SSL` &DoubleRightArrow; turn ON
      * `Custom SSL` &DoubleRightArrow; ENABLE (dismiss info popup)
   * `N` (nginx Load Balancer)
      * set `Scaling Limit` to 1
   * `Docker Engine` 
      * set `Scaling Limit` to 1
      * turn `Access via SLB` to OFF
      * set `Public IPv4` to 0

1. Verify `docker` and `docker compose` are installed<br>
   * Web SSH to the Docker Engine Node
      * Expand the `[Environment]`
      * Hover over the `Engine Node`
      * Click `Web SSH` (terminal window icon)
      * execute
         ```
         docker -v
         docker compose version
         ```
1. Configure a service to start the Docker Engine Node using docker compose
   * Setup the `docker-compose.service` by running
      ```
      /root/application/setupServiceDaemon.sh
      ```
      After this you can use `systemctl start docker-compose` etc... <br>
      Note: If you get a permissions eror, try setting execute privildge <br>
      ```
      chmod=+x /root/application/setupServiceDaemon.sh
      /* or on the repo use (in the repo root directory) */
      git update-index --chmod=+x setupServiceDaemon.sh`
      ```
1. Keep the service configured when redeploying
   * `Engine Node` &DoubleRightArrow; `Config` (spanner icon)
      * Open `redeploy.conf`
      * below the `# CUSTOM FILES AND FOLDERS` paragraph, add 
         ```
         /etc/systemd/system/docker-compose.service
         ```

1. Configure start command
   * `Engine Node` &DoubleRightArrow; gear icon &DoubleRightArrow; `CMD/Entry Point`
      * set `Run Command` to `systemctl start docker-compose`
      * click `Apply`
1. Verify the environment is up
   1. Expand `Load Balancer` &DoubleRightArrow; expand `Node ID: nnnn` &DoubleRightArrow; copy the `IPv4` ip address. Eg `203.143.90.231`<br>
      *You will need this when configuring Crazy Domains below*
   2.  Paste the IP Address into browser (make sure it uses `http`, not `https`)<br>
      *This should load the application, with a warning to say it is not secure*

1. Configure DNS on [Crazy Domains](https://www.crazydomains.co.nz/members/login/) 
      1. Login (this has 2FA enabled)
      1. Open `dirks.nz` &DoubleRightArrow; click `MANAGE` &DoubleRightArrow; scroll down to `A Records`
      1. Open &equiv; menu &DoubleRightArrow; `Add Record`
      1. Check dropdown shows `A Record` &DoubleRightArrow; click `Add`
      1. For the last record in the list, 
         * enter a value in the `Sub Domain` field. Eg `test`
         * enter the `IP Address` field with value copied earlier
      1. Click `Update(1)` &DoubleRightArrow; *Note: it will take some time (minutes, possibly 10's of minutes) before the DNS update is available everywhere.*
      1. Verify the DNS has been updated
         * Expand `Load Balancer` &DoubleRightArrow; `Web SSH` (terminal icon) &DoubleRightArrow; Execute command `ping test.dirks.nz`<br>
            *wait until the ping command shows the IP address*

1. Configure SSL on nginx Load Balancer
   * Hover over `Load Balancer` &DoubleRightArrow; `Add-Ons` (coloured hexagon wheel icon)
      * `Let's Encrypt Free SSL` &DoubleRightArrow; `Install`
      * In the `External Domain(s)` field enter the `[*].dirks.nz` and `[*].mel.cloudlets.com.au` names. <br>
        Eg. `test.dirks.nz,test-dirks-nz.mel.cloudlets.com.au`
      * Click `Install` &DoubleRightArrow; *Note: it will take some time to complete this step.* 
   * Verify `https://[*].mel.cloudlets.com.au`
      * Click the link below the `[environment]` name <br>
      *this should load into a new browser tab with `https:[*].mel.cloudlets.com.au` address*
   * Verify `https://[*].dirks.nz`
      * Open a new browser tab and type the address<br>
      *this should load at `https://[*].dirks.nz` address*
      * It is possible/likely that DNS may not have populated for New Zealand as yet *(it can take an hour or more?)*, an alternative check is 
         * from `Load Balancer` &DoubleRightArrow; `Web SSH` &DoubleRightArrow; Execute command `curl -iL test.dirks.nz`<br>
           *which should respond with the content programmed in the application*

1. Copy nginx.conf to correct location
   * `Load Balancer` &DoubleRightArrow; `Web SSH` (terminal window icon)
   * Execute
   ```
   cp /root/application/CloudletsEnvironment/LoadBalancer/chatGPT/nginx.conf /etc/nginx/nginx.conf
   ```
-rw-rw-r--+  1 root root 2618 Sep 11 20:02 nginx.conf

   * `Load Balancer` &DoubleRightArrow; `Config` (spanner icon)
   * Open `nginx` folder &DoubleRightArrow; file `nginx.conf`
   * Copy contents
   1. redirect http (port 80) to https (port 443)
      * locate the server {...} node that listens to port 80. Eg. 
         ```
            server {
                     listen *:80;
                     listen [::]:80;
                     server_name  _;
                     ...
            }
         ```
      * just before the closing } add (replacing [*] )
         ```
         return 301 https://[*].dirks.nz$request_uri;
         ```
         *This will direct all http call to https, and where needed redirect calls to `[*].dirks.nz` domain*
   1. Redirect `https://[*].mel.cloudlets.com.au` to `https://[*].dirks.nz` <br>
      Add a new server {...} node (just above the previous one)
      ```
         server {
               listen 443 ssl;
               server_name [*]-dirks-nz.mel.cloudlets.com.au;
               ssl_certificate      /var/lib/jelastic/SSL/jelastic.chain;
               ssl_certificate_key  /var/lib/jelastic/SSL/jelastic.key;
               # Check if the request is already for [*].dirks.nz to avoid redirect loop
               if ($host = [*]-dirks-nz.mel.cloudlets.com.au) {
                  return 301 https://[*].dirks.nz$request_uri;
               }
         }
      ```
   1. Enable `ngx_http_modsecurity_module` by finding & uncommenting the two lines below
      ```
      #Please ensure that the load_module directive for ngx_http_modsecurity_module is uncommented in the /etc/nginx/nginx.conf
      modsecurity  on;
      modsecurity_rules_file /etc/nginx/conf.d/modsecurity/modsec_includes.conf;
      ```
      and in file file `nginx.conf` finding & uncommenting the line below
      ```
      load_module modules/ngx_http_modsecurity_module.so;
      ```
---

## Links
### Cloudlets Documentation
* [Main cloudlets web site](https://cloudlets.com.au/)
* [Creating a docker engine node](https://www.virtuozzo.com/application-platform-docs/docker-engine-deployment)

### Official Node.js Docker Image Documentation
* [GitHub docker-node repo README](https://github.com/nodejs/docker-node/blob/main/README.md)

---
## License
[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)