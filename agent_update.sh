#!/bin/sh

echo "Printing the Working Directory... /n"
pwd
echo "/n"

echo "Updating MTConnect Adapter... /n"

sudo systemctl stop adapter
sudo cp -r ./adapter/. /etc/adapter/
sudo cp -r ./afg/SmartSaw_DC.afg /etc/adapter/
sudo chown -R adapter:adapter /etc/adapter
sudo chmod +x /etc/adapter/Adapter
sudo cp /etc/adapter/adapter.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl start adapter
sudo systemctl status adapter

echo "MTConnect Adapter Up and Running /n"


echo "Updating MTConnect Agent... /n"

sudo systemctl stop agent
sudo cp -r ./agent/. /etc/mtconnect/agent/
sudo cp -r ./devices/. /etc/mtconnect/devices/
sudo cp -r ./schema/. /etc/mtconnect/schema/
sudo cp -r ./styles/. /etc/mtconnect/styles/
sudo chown -R mtconnect:mtconnect /etc/mtconnect
sudo cp agent/agent /usr/bin/
sudo chmod +x /usr/bin/agent
sudo cp /etc/mtconnect/agent/agent.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl start agent
sudo systemctl status agent

echo "MTConnect Agent Up and Running /n"
pwd
