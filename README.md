# dirks.nz - Repo
Responsible for deploying dirks.nz online resources using (docker-)compose.yml file for deploying a node.js image to a node on my account with app.cloudlets.com.au

For details see
* https://www.virtuozzo.com/application-platform-docs/docker-engine-deployment
* https://github.com/nodejs/docker-node/blob/main/README.md

And if the cloudlet is up and running you can access it below 
* https://dirks-nz.mel.cloudlets.com.au or
* https://dirks.nz once the DNS stuff is setup

## Instructions
1. Make sure `docker` and `docker compose` are installed<br>
`docker -v`<br>
`docker compose version`
2. It is useful to configure a service to start the node.
3. Open a terminal or SSH to the host
4. Configure the host to automatically obtain, or clone, this repo. <br>
In cloudlets use the `Compose Repo` setting <br>
At `New Environment => Custom => Docker Engine => Deploy containers from compose.yml` <br>
(The setting is only availble and shown when creating a new environment)
5. Setup the `docker-compose.service` by running <br>
`/root/application/setupServiceDaemon.sh`. <br>
After this you can use `systemctl start docker-compose` etc...
7. In cloudlets navigate to `Docker Engine Node => CMD/Entry Point` and <br>
change it to `systemctl start docker-compose`
8. In cloudlets navigate to `Docker Engine Node => Config`<br>
Open `redeploy.conf`<br>
add `/etc/systemd/system/docker-compose.service` to the `Custom Files and Folders` section<br>
This should retain the service during redeploys, it should only need to be done once when creating the environment. 

## License
[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)
