#!/bin/bash
# wget -q -O deweb.sh https://github.com/encipher88/deweb/blob/main/deweb.sh && chmod +x deweb.sh && sudo /bin/bash deweb.sh


cd $HOME
sudo apt update && sudo apt upgrade -y
sleep 10
sudo apt install make curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git ncdu gcc git jq chrony liblz4-tool -y 

bash_profile=$HOME/.bash_profile

if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://raw.githubusercontent.com/encipher88/deweb/main/11.sh | bash && sleep 1


if [[ ! $DEWEB_NODENAME ]]; then
		read -p "Enter your node name: " DEWEB_NODENAME
		echo 'export DEWEB_NODENAME='${DEWEB_NODENAME} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[45mYour node name:' $DEWEB_NODENAME '\e[0m\n'
	if [[ ! $DEWEB_WALLET ]]; then
		read -p "Enter wallet name: " DEWEB_WALLET
		echo 'export DEWEB_WALLET='${DEWEB_WALLET} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[45mYour wallet name:' $DEWEB_WALLET '\e[0m\n'
	if [[ ! $DEWEB_PASSWORD ]]; then
		read -p "Enter wallet password: " DEWEB_PASSWORD
		echo 'export DEWEB_PASSWORD='${DEWEB_PASSWORD} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[45mYour wallet password:' $DEWEB_PASSWORD '\e[0m\n'
	. $HOME/.bash_profile
	sleep 1




echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME

sudo rm -rf /usr/local/go

curl https://dl.google.com/go/go1.17.6.linux-amd64.tar.gz | sudo tar -C/usr/local -zxvf -
cat <<'EOF' >>$HOME/.profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export GO111MODULE=on
export GOBIN=$HOME/go/bin
export PATH=$PATH:/usr/local/go/bin:$GOBIN
EOF
source $HOME/.profile

go version



echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1

cd $HOME
rm -r $HOME/deweb
git clone https://github.com/deweb-services/deweb.git
cd deweb
git fetch --all
git checkout v0.2
make build
sudo cp build/dewebd /usr/local/bin/dewebd
dewebd version –long

sleep 2


dewebd config chain-id deweb-testnet-1 

sleep 2

cd $HOME/deweb
echo -e "\n\e[45mWait some time before creating key...\e[0m\n"
sleep 20
sudo tee <<EOF >/dev/null $HOME/deweb/DEWEB_add_key.sh
#!/usr/bin/expect -f
EOF
echo "set timeout -1
spawn $HOME/deweb/stchaincli keys add $DEWEB_WALLET --home $HOME/deweb
match_max 100000
expect -exact \"Enter keyring passphrase:\"
send -- \"$DEWEB_PASSWORD\r\"
expect -exact \"\r
Re-enter keyring passphrase:\"
send -- \"$DEWEB_PASSWORD\r\"
expect eof" >> $HOME/deweb/DEWEB_add_key.sh
sudo chmod +x $HOME/deweb/DEWEB_add_key.sh
$HOME/deweb/DEWEB_add_key.sh &>> $HOME/deweb/$DEWEB_WALLET.txt
echo -e "You can find your mnemonic by the following command:"
echo -e "\e[32mcat $HOME/DEWEB/$DEWEB_WALLET.txt\e[39m"
export DEWEB_WALLET_ADDRESS=`cat $HOME/DEWEB/$DEWEB_WALLET.txt | grep address | awk '{split($0,addr," "); print addr[2]}' | sed 's/.$//'`
echo 'export DEWEB_WALLET_ADDRESS='${DEWEB_WALLET_ADDRESS} >> $HOME/.bash_profile
. $HOME/.bash_profile
echo -e '\n\e[45mYour wallet address:' $DEWEB_WALLET_ADDRESS '\e[0m\n'

dewebd init $DEWEB_NODENAME --chain-id deweb-testnet-1




cd $HOME
curl -s https://raw.githubusercontent.com/deweb-services/deweb/main/genesis.json > ~/.deweb/config/genesis.json 

sed -E -i 's/seeds = \".*\"/seeds = \"74d8f92c37ffe4c6393b3718ca531da8f0bf0594@seed1.deweb.services:26656\"/' $HOME/.deweb/config/config.toml

sed -E -i 's/persistent_peers = \".*\"/persistent_peers = \" a0434d6b1d1fa4cb3a6f619df3f49ada83d2abb7@167.235.57.142:26656,580b1bb524717c9f9340bc4052ef99eb38a32e28@185.216.203.24:26656,da6130e91acde648d23dda2847587f2cee86fb14@213.136.92.246:46656,33aa64ec6be8d1da694c9cb89111fb7481c36a50@66.94.120.208:26656,2d9d9cc1dcffe9484826f86037d50e79c96b9419@66.94.120.207:26656,4ba39c0031d6795ac9ca4900c113c594ec1540d7@173.249.9.186:36656,c9717257204a2dc05dfd3fda01d0c7b9982ae3a7@144.126.142.139:26656,986c2116fac2d9442190a7755b29793663da530d@65.108.199.79:26656 \"/' $HOME/.deweb/config/config.toml


sed -E -i 's/minimum-gas-prices = \".*\"/minimum-gas-prices = \"0.001udws\"/' $HOME/.deweb/config/app.toml

sudo ufw allow 26656

dewebd start
sleep 5
^c

echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1


cd $HOME
    echo "[Unit]
    Description=DWS Node
    After=network-online.target
    [Service]
    User=${USER}
    ExecStart=$(which dewebd) start
    Restart=always
    RestartSec=3
    LimitNOFILE=4096
    [Install]
    WantedBy=multi-user.target
    " >dewebd.services 

    sudo mv dewebd.service /lib/systemd/system/
    sudo systemctl enable dewebd.service && sudo systemctl start dewebd.service

sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl enable dewebd
sudo systemctl restart dewebd
echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service dewebd status | grep active` =~ "running" ]]; then
  echo -e "Your DEWEB node \e[32minstalled and works\e[39m!"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your deweb node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
