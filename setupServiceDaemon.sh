# This copies the service file to the correct location, and reloads the services. 
cp /root/application/docker-compose.service /etc/systemd/system/docker-compose.service
# below example how to replace ${...} with value from environment
#sed -i "s/\${SPLUNK_PASSWORD}/${SPLUNK_PASSWORD}/g" /etc/systemd/system/docker-compose.service
systemctl daemon-reload
