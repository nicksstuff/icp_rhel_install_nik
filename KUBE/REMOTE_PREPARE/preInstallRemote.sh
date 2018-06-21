echo "Installing Prerequisites";
sudo apt-get  --yes --force-yes install apt-transport-https ca-certificates curl software-properties-common python-minimal

sudo sysctl -w vm.max_map_count=262144

sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get --yes --force-yes update
sudo apt-get install --yes docker-ce=17.09.0~ce-0~ubuntu

sudo ufw disable
