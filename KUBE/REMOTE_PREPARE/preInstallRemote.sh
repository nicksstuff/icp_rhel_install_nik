echo "Installing Prerequisites";
apt-get  --yes --force-yes install apt-transport-https ca-certificates curl software-properties-common python-minimal

sysctl -w vm.max_map_count=262144

echo "vm.max_map_count=262144" >> /etc/sysctl.conf


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get --yes --force-yes update
apt-get install --yes docker-ce=17.09.0~ce-0~ubuntu

ufw disable
