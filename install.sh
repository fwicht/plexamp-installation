#!/usr/bin/env bash
. ~/.profile
. ~/.bashrc
. ~/.nvm/nvm.sh


# node.js version to use 
# hardcoded until a better solution is found (scrapping the HTML seems overkill)
NODE_VERSION=16

# making sure that jq is installed
if ! [ -x "$(command -v jq)" ]; then
    echo "jq is not installed..."
    echo "installing jq"
    sudo apt install jq -y
fi


# making sure that node version manager is installed
if ! [ -x "$(command -v nvm)" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. ~/.nvm/nvm.sh
fi


# downloading and installing plexamp per the original upgrade.sh script
cd
PLEXAMP_URL=$(curl -s "https://plexamp.plex.tv/headless/version$1.json" | jq -r '.updateUrl')  
nvm install $NODE_VERSION
nvm use $NODE_VERSION
wget -q "$PLEXAMP_URL" -O plexamp.tar.bz2
if [[ -d ./plexamp.last ]]; then
    rm -rf plexamp.last
fi
if [[ -d ./plexamp ]]; then
    mv plexamp plexamp.last
fi
tar xfj plexamp.tar.bz2
rm plexamp.tar.bz2
chown -R "${USER}:${USER}" plexamp

# authenticating if first installation
if ! [ -d ~/.local/share/Plexamp ]; then
    echo "authentication needed, follow the instructions below"
    cd plexamp
    node js/index.js;
    cd
fi

# installing service
SERVICE_CONFIG="[Unit]\n
Description=Plexamp\n
After=network-online.target\n
Requires=network-online.target\n
\n
[Service]\n
Type=simple\n
User=pi\n
WorkingDirectory=/home/pi/plexamp\n
ExecStart=$(which node) /home/pi/plexamp/js/index.js\n
Restart=on-failure\n
\n
[Install]\n
WantedBy=multi-user.target" 

echo -e $SERVICE_CONFIG > plexamp.service
sudo mv plexamp.service /lib/systemd/system/plexamp.service

# enabling service
sudo systemctl daemon-reload
sudo systemctl enable plexamp
sudo systemctl -q restart plexamp
