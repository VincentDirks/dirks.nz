# dirks.nz - Repo

Responsible for deploying dirks.nz online resources using (docker-)compose.yml file for deploying a node.js image to a node on my account with app.cloudlets.com.au

This readme aims to document all steps needed to deploy to new environment, as well as details for upgrading parts of the environment.

And if the cloudlet is up and running you can access

| Environment | URL                   |
| ----------- | --------------------- |
| Production  | https://dirks.nz      |
| Test        | https://test.dirks.nz |

The VPS cloudlets urls are

- https://dirks-nz.mel.cloudlets.com.au
- https://test-dirks-nz.mel.cloudlets.com.au

But nginx should be configured to redirect these back to the \*.dirks.nz equivalents.

## Instructions

1. Navigate and log into https://cloudlets.com.au/ (I have 2FA turned on). This should take you to the cloudlets dashboard.
1. Navigate to `+ NEW ENVIRONMENT` &DoubleRightArrow; `Custom` &DoubleRightArrow; click `▼` &DoubleRightArrow; `Docker Engine`

   1. Select `Deploy containers from compose.yml`
   1. Enter `Compose Repo` field with the repo that contains the `compose.yml` file (probably this repo)
   1. Accept or update the `Environment` field (this is the URL via the Cloudlets Shared Load Balancer - SLB)
   1. Click `Install` &DoubleRightArrow; this will take a moment to complete.

   - Notes:
     1. The `Compose Repo` setting is only availble and shown when creating a new environment
     1. The repo also should have the files `docker-compose.service` and `setupServiceDaemon.sh`
     1. The application should also be in the repo

1. Hover of the `[environment]` &DoubleRightArrow; click `Change Environment Topology` (icon with gear over 3 blocks) &DoubleRightArrow; to configure the environment

   - `SSL`
     - `Built-In SSL` &DoubleRightArrow; turn ON
     - `Custom SSL` &DoubleRightArrow; ENABLE (dismiss info popup)
   - `N` (nginx Load Balancer)
     - set `Scaling Limit` to 1
   - `Docker Engine`
     - set `Scaling Limit` to 1
     - turn `Access via SLB` to OFF
     - set `Public IPv4` to 0

1. Verify `docker` and `docker compose` are installed<br>
   - Web SSH to the Docker Engine Node
     - Expand the `[Environment]`
     - Hover over the `Engine Node`
     - Click `Web SSH` (terminal window icon)
     - execute
       ```
       docker -v
       docker compose version
       ```
1. Configure a service to start the Docker Engine Node using docker compose
   - Setup the `docker-compose.service` by running
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

   - `Engine Node` &DoubleRightArrow; `Config` (spanner icon)
     - Open `redeploy.conf`
     - below the `# CUSTOM FILES AND FOLDERS` paragraph, add
       ```
       /etc/systemd/system/docker-compose.service
       ```

1. Configure start command
   - `Engine Node` &DoubleRightArrow; gear icon &DoubleRightArrow; `CMD/Entry Point`
     - set `Run Command` to `systemctl start docker-compose`
     - click `Apply`
1. Verify the environment is up

   1. Expand `Load Balancer` &DoubleRightArrow; expand `Node ID: nnnn` &DoubleRightArrow; copy the `IPv4` ip address. Eg `203.143.90.231`<br>
      _You will need this when configuring Crazy Domains below_
   2. Paste the IP Address into browser (make sure it uses `http`, not `https`)<br>
      _This should load the application, with a warning to say it is not secure_

1. Configure DNS on [Crazy Domains](https://www.crazydomains.co.nz/members/login/)

   1. Login (this has 2FA enabled)
   1. Open `dirks.nz` &DoubleRightArrow; click `MANAGE` &DoubleRightArrow; scroll down to `A Records`
   1. Open &equiv; menu &DoubleRightArrow; `Add Record`
   1. Check dropdown shows `A Record` &DoubleRightArrow; click `Add`
   1. For the last record in the list,
      - enter a value in the `Sub Domain` field. Eg `test`
      - enter the `IP Address` field with value copied earlier
   1. Click `Update(1)` &DoubleRightArrow; _Note: it will take some time (minutes, possibly 10's of minutes) before the DNS update is available everywhere._
   1. Verify the DNS has been updated
      - Expand `Load Balancer` &DoubleRightArrow; `Web SSH` (terminal icon) &DoubleRightArrow; Execute command `ping test.dirks.nz`<br>
        _wait until the ping command shows the IP address_

1. Configure SSL on nginx Load Balancer

   - Hover over `Load Balancer` &DoubleRightArrow; `Add-Ons` (coloured hexagon wheel icon)
     - `Let's Encrypt Free SSL` &DoubleRightArrow; `Install`
     - In the `External Domain(s)` field enter the `[*].dirks.nz` and `[*].mel.cloudlets.com.au` names. <br>
       Eg. `test.dirks.nz,test-dirks-nz.mel.cloudlets.com.au`
     - Click `Install` &DoubleRightArrow; _Note: it will take some time to complete this step._
   - Verify `https://[*].mel.cloudlets.com.au`
     - Click the link below the `[environment]` name <br>
       _this should load into a new browser tab with `https:[_].mel.cloudlets.com.au` address\*
   - Verify `https://[*].dirks.nz`
     - Open a new browser tab and type the address<br>
       _this should load at `https://[_].dirks.nz` address\*
     - It is possible/likely that DNS may not have populated for New Zealand as yet _(it can take an hour or more?)_, an alternative check is
       - from `Load Balancer` &DoubleRightArrow; `Web SSH` &DoubleRightArrow; Execute command `curl -iL test.dirks.nz`<br>
         _which should respond with the content programmed in the application_

1. nginx configuration

   - In VS Code, or on GitHub, open file [/CloudletsEnvironment/LoadBalancer/chatGPT/[test.]dirks.nz.nginx.conf](), select all content and copy
   - In cloudlets dashboard go to `Load Balancer` &DoubleRightArrow; `Config` (spanner icon)
   - Open `nginx` folder &DoubleRightArrow; file `nginx.conf`
   - replace content with copied content
   - `Load Balancer` &DoubleRightArrow; `Restart Nodes` (clockwise arrow icon)

1. Test Redirections

- **Production**
  | URL                                   | Description              | Destination      |
  |---------------------------------------|--------------------------|------------------|
  | https://dirks.nz                      | Production               | https://dirks.nz |
  | http://dirks.nz                       | SSL redirect             | https://dirks.nz |
  | https://dirks-nz.mel.cloudlets.com.au | Redirect cloudlets       | https://dirks.nz |
  | http://dirks-nz.mel.cloudlets.com.au  | Redirect cloudlets & SSL | https://dirks.nz |

- **Test**
  | URL                                        | Description              | Destination           |
  |--------------------------------------------|--------------------------|-----------------------|
  | https://test.dirks.nz                      | Production               | https://test.dirks.nz |
  | http://test.dirks.nz                       | SSL redirect             | https://test.dirks.nz |
  | https://test-dirks-nz.mel.cloudlets.com.au | Redirect cloudlets       | https://test.dirks.nz |
  | http://test-dirks-nz.mel.cloudlets.com.au  | Redirect cloudlets & SSL | https://test.dirks.nz |

All links end up in the same place (https://test.dirks.nz or https://dirks.nz), and all should load quickly, and have correct valid certificate. 

---

## Links

### Cloudlets Documentation

- [VPS cloudlets web site](https://cloudlets.com.au/)
- [Creating a docker engine node](https://www.virtuozzo.com/application-platform-docs/docker-engine-deployment)

### Official Node.js Docker Image Documentation

- [GitHub docker-node repo README](https://github.com/nodejs/docker-node/blob/main/README.md)

---

## License

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)
