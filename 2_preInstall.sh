#!/bin/bash

source ~/INSTALL/0_variables.sh



echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Installing Prerequisites";

wget dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
rpm -ihv epel-release-7-11.noarch.rpm

# Install docker & python on master
sudo yum install -y yum-utils device-mapper-persistent-data lvm2


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Installing Docker on MASTER"
# INSTALL DOCKER
if [ "$ARCH" == "ppc64le" ]; then
  # https://developer.ibm.com/linuxonpower/docker-on-power/
  echo -e "[docker]\nname=Docker\nbaseurl=http://ftp.unicamp.br/pub/ppc64el/rhel/7/docker-ppc64el/\nenabled=1\ngpgcheck=0\n" | sudo tee /etc/yum.repos.d/docker.repo
else
  sudo yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo
fi
sudo yum update -y
sudo yum install -y docker-ce

# Fall back to pinned version (no fallback for ppc)
if [ "$?" == "1" ]; then
  yum install --setopt=obsoletes=0 -y docker-ce-17.09.0.ce-1.el7.centos.x86_64 docker-ce-selinux-17.09.0.ce-1.el7.centos.noarch
fi


sudo service docker start


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Installing Tools on MASTER"
sudo yum install -y python-setuptools
sudo easy_install pip


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Installing Workers"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
for ((i=0; i < $NUM_WORKERS; i++)); do
  echo "-----------------------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo "Installing Docker on ${WORKER_HOSTNAMES[i]}"
  # Install docker & python on worker
  ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo yum install -y yum-utils device-mapper-persistent-data lvm2
  if [ "$ARCH" == "ppc64le" ]; then
    ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} 'echo -e "[docker]\nname=Docker\nbaseurl=http://ftp.unicamp.br/pub/ppc64el/rhel/7/docker-ppc64el/\nenabled=1\ngpgcheck=0\n" | sudo tee /etc/yum.repos.d/docker.repo'
  else
    ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  fi

  ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo yum update -y
  ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo yum install -y docker-ce

  # Fall back to pinned version (no fallback for ppc)
  if [ "$?" == "1" ]; then
    ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} yum install --setopt=obsoletes=0 -y docker-ce-17.03.2.ce-1.el7.centos.x86_64 docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch
  fi
  echo "-----------------------------------------------------------------------------------------------------------"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo "Installing Tools on ${WORKER_HOSTNAMES[i]}"
  ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo yum install -y python-setuptools
  ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo easy_install pip
done





# Install Command Line Tools
echo "Installing Tools";
sudo yum install -y tree
sudo yum install -y htop
sudo yum install -y curl
sudo yum install -y unzip
sudo yum install -y iftop


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Adapt Environment"
# Set VM max map count (see max_map_count https://www.kernel.org/doc/Documentation/sysctl/vm.txt)
sudo sysctl -w vm.max_map_count=262144

sudo cat <<EOB >>/etc/sysctl.conf
vm.max_map_count=262144
EOB

# Sync time
sudo ntpdate -s time.nist.gov





echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Configure Firewall"
#https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/supported_system_config/required_ports.html
MASTER_PORTS=("8101" "179" "8500" "8743" "5044" "5046" "9200" "9300" "2380" "4001" "8082" "8084" "4500" "4300" "8600" "80" "443" "8181" "18080" "5000" "35357" "4194" "10248:10252" "30000:32767" "8001" "8888" "8080" "8443" "9235" "9443")
WORKER_PORTS=("179" "4300" "4194" "10248:10252" "30000:32767" "8001" "8888")
# Stop firewall
sudo systemctl stop firewalld.service

# Open required ports
for port in "${MASTER_PORTS[@]}"; do
  sudo iptables -A INPUT -p tcp -m tcp --sport $port -j ACCEPT
  sudo iptables -A OUTPUT -p tcp -m tcp --dport $port -j ACCEPT
done

# Do we need this?
sudo service iptables restart






echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "INSTALL INCEPTION"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"


#echo "Creating SSH Key";
#ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -N ""
#cat ~/.ssh/id_rsa.pub | sudo tee -a ~/.ssh/authorized_keys
#ssh-copy-id -i ~/.ssh/id_rsa.pub root@

echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Fetch Docker Inception Image"
sudo docker pull ibmcom/icp-inception:${ICP_VERSION}


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Creating Cluster Directory";
cd ~/INSTALL
sudo docker run -e LICENSE=accept -v "$(pwd)":/data ibmcom/icp-inception:${ICP_VERSION} cp -r cluster /data


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Adapting Config";

# Configure hosts
echo "[master]" | sudo tee ~/INSTALL/cluster/hosts
echo "${MASTER_IP}" | sudo tee -a ~/INSTALL/cluster/hosts
echo "" | sudo tee -a ~/INSTALL/cluster/hosts

echo "[worker]" | sudo tee -a ~/INSTALL/cluster/hosts
for ((i=0; i < $NUM_WORKERS; i++)); do
  echo ${WORKER_IPS[i]} | sudo tee -a ~/INSTALL/cluster/hosts
done
echo "" | sudo tee -a ~/INSTALL/cluster/hosts

echo "[proxy]" | sudo tee -a ~/INSTALL/cluster/hosts
echo "${MASTER_IP}" | sudo tee -a ~/INSTALL/cluster/hosts

# Add line for external IP in config
echo "cluster_access_ip: ${PUBLIC_IP}" | sudo tee -a ~/INSTALL/cluster/config.yaml
echo "proxy_access_ip: ${PUBLIC_IP}" | sudo tee -a ~/INSTALL/cluster/config.yaml


echo "Copy SSH Key";
sudo cp ~/.ssh/id_rsa ~/INSTALL/cluster/ssh_key
sudo chmod 400 ~/INSTALL/cluster/ssh_key
