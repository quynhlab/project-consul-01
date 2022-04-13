#!/bin/bash

#Get IP
#local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
export ip=$(hostname  -I | cut -f1 -d' ')
#Utils
sudo apt-get install unzip
sudo apt-get update
sudo apt-get install software-properties-common
sudo add-apt-repository universe
sudo apt-get update
#Download Consul

export CONSUL_VERSION="1.12.0-beta1+ent"
export CONSUL_URL="https://releases.hashicorp.com/consul"

curl --silent --remote-name \
  ${CONSUL_URL}/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip

curl --silent --remote-name \
  ${CONSUL_URL}/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS

curl --silent --remote-name \
  ${CONSUL_URL}/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig

#Unzip the downloaded package and move the consul binary to /usr/bin/. Check consul is available on the system path.

unzip consul_${CONSUL_VERSION}_linux_amd64.zip
sudo chown root:root consul
sudo mv consul /usr/bin/

#The consul command features opt-in autocompletion for flags, subcommands, and arguments (where supported). Enable autocompletion.

consul -autocomplete-install
complete -C /usr/bin/consul consul

#Create a unique, non-privileged system user to run Consul and create its data directory.
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /opt/consul
sudo chown --recursive consul:consul /opt/consul

sudo cat << EOF > /etc/consul.d/license.hclic
02MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JJVLVSMKNGJDG2T2HIV2E2RCFGFHGSMBVJZCFS6CMKRGXQTKXKF2FSMSZGRHFIRJUJZKEM2COPJBG2SLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJUE2VCNGRNFOTTKLJUTC3C2NJVXQTCUMM2FSV2VORNEISTLLFUTC22ZGJJG2WLKIF5FURC2NFMWUVLJJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SJORGUIULUJVKEUVKNKRVTMTSEJE3E2VCNOVHUIZ3YJ5CFSM2PKRTXUV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJPFGFIQJQJRKEK6KWIRAXOT3KIF3U62SBO5LWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKJV2E2RCRORGVISSVJVVE2NSOKRVTMTSUNN2U6VDLGVLWSSLTJFXFE3DDNUYXAYTNIYYGCVZZOVMDGUTQMJLVK2KPNFEXSTKEJF5EYVCFPFGFIRLZKZCEC52PNJAXOT3KIF3VO2KJONEW4QTZMIZFEMKZGNIWST3JJJVGEMRVPJSFO53JJRBUU3LCI5DG4Y3ZJE3GKMZRHEXHCU3RM44HSRZYONIEER2NIM4EGYLUKVUTG5SKPBDGM22MPJ2FG5ZLMZEVGOCJOY3TGSRYNFIWK2JSPJCEMRLFOQ2HI4LRGFWDMWCDMNDXS5CSOVKG24RLIU4HURDEPBZGYWDKOZCEUMLEIFVWGYJUMRLDAMZTHBIHO3KWNRQXMSSQGRYEU6CJJE4UINSVIZGFKYKWKBVGWV2KORRUINTQMFWDM32PMZDW4SZSPJIEWSSSNVDUQVRTMVNHO4KGMUVW6N3LF5ZSWQKUJZUFAWTHKMXUWVSZM4XUWK3MI5IHOTBXNJBHQSJXI5HWC2ZWKVQWSYKIN5SWWMCSKRXTOMSEKE6T2
EOF

#Create Systemd Config
sudo cat << EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul
Documentation=https://www.consul.io/
[Service]
ExecStart=/usr/bin/consul agent -server -data-dir=/opt/consul -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

#Create config dir
sudo mkdir --parents /etc/consul.d
sudo touch /etc/consul.d/consul.hcl
sudo chown --recursive consul:consul /etc/consul.d
sudo chmod 640 /etc/consul.d/consul.hcl

sudo cat << EOF > /etc/consul.d/consul.hcl
datacenter = "maniak-academy"
data_dir = "/opt/consul"
encrypt = "uIrgwyzyGFeNUR1mWevcc9vIrF2dnL/7IEg509x4QT4="
server = true
bind_addr = "${ip}"
client_addr = "0.0.0.0"
advertise_addr = "${ip}"
bootstrap_expect = 3
node_name = "${HOSTNAME}"
license_path = "/etc/consul.d/license.hclic"
bootstrap = false
retry_join = ["192.168.86.70","192.168.86.71","192.168.86.72"]
ui_config {
  enabled = true
}
connect {
  enabled = true
}
acl {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
}
EOF

sudo systemctl daemon-reload
sudo systemctl stop consul
sudo systemctl start consul
sudo systemctl restart consul
sudo systemctl status consul

#cert bot install 
sudo apt-get install certbot -y
#sudo certbot certonly --standalone -d c0.maniak.academy -m sebastian@maniak.io --agree-tos --eff-email

sudo apt  install jq -y

sudo systemctl status consul

