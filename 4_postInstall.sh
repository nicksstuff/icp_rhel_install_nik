#!/bin/bash


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Installing Command Line Tools";
# Install Command Line Tools
docker run -e LICENSE=accept --net=host -v /usr/local/bin:/data ibmcom/icp-inception:2.1.0.3 cp /usr/local/bin/kubectl /data
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sudo bash
sudo helm init --client-only


#export HELM_HOME=/home/icp/.helm
# https://192.168.27.199:8443/helm-api/cli/linux-amd64/helm
# bx pr login -a https://mycluster.icp:8443 --skip-ssl-validation
#
# bx pr login -a https://192.168.27.199:8443 --skip-ssl-validation
# bx pr clusters
# bx pr cluster-config mycluster



echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Installing kube config";
#INIT KUBECTL
mkdir ~/.kube
cp /var/lib/kubelet/kubectl-config ~/.kube/config


echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
read -p "Install and configure OpenLDAP? [y,N]" DO_LDAP
if [[ $DO_LDAP == "y" ||  $DO_LDAP == "Y" ]]; then
  # Install OpenLDAP
  echo "Install OpenLDAP "
  echo "Use mycluster.icp as DNS Domain Name"
  echo "and icp as Organization Name"
  sudo yum update -y
  sudo yum install -y openldap openldap-servers openldap-clients
  systemctl start slapd
  systemctl enable slapd


  slappasswd -h {SSHA} -s admin
  ldapmodify -Y EXTERNAL  -H ldapi:/// -f db.ldif
  ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
  ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
  ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif


  # Create LDAP Users
  echo "Create LDAP Users"
  ldapadd -x -D cn=admin,dc=mycluster,dc=icp -W -f  ~/INSTALL/LDAP/addldapcontent.ldif

else
  echo "LDAP not configured"
fi




echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
read -p "Install and configure PersistentVolumes? [y,N]" DO_PV
if [[ $DO_PV == "y" ||  $DO_PV == "Y" ]]; then
  # Create PersistentVolumes
  #echo "Install NFS Server"
  #sudo apt-get --yes --force-yes install nfs-kernel-server

  echo "Start NFS Server"
  systemctl start nfs

  # Create NFS Directories
  echo "Create NFS Directories"
  sudo mkdir -p /storage/
  sudo mkdir -p /storage/nfsvol01rwo
  sudo mkdir -p /storage/nfsvol02rwm
  sudo mkdir -p /storage/nfsvol03rwo
  sudo mkdir -p /storage/nfsvol04rwm
  sudo mkdir -p /storage/nfsvol05rwo
  sudo mkdir -p /storage/nfsvol06rwm
  sudo mkdir -p /storage/nfsvol07rwo
  sudo mkdir -p /storage/nfsvol08rwm
  sudo mkdir -p /storage/nfsvol11rwo
  sudo mkdir -p /storage/nfsvol12rwo
  sudo mkdir -p /storage/nfsvol13rwo
  sudo mkdir -p /storage/nfsvol14rwo
  sudo mkdir -p /storage/nfsvol15rwo
  sudo mkdir -p /storage/nfsvol16rwo
  sudo mkdir -p /storage/nfsvol17rwo
  sudo mkdir -p /storage/nfsvol18rwo
  sudo mkdir -p /storage/dsx
  sudo mkdir -p /storage/TRA_data
  sudo mkdir -p /storage/data-stor
  sudo mkdir -p /storage/hadr-stor
  sudo mkdir -p /storage/etcd-stor
  sudo mkdir -p /storage/pv0001
  sudo mkdir -p /storage/pv0002
  sudo mkdir -p /storage/CAM_db
  sudo mkdir -p /storage/CAM_logs
  sudo mkdir -p /storage/CAM_terraform
  sudo mkdir -p /storage/CAM_bpd

  sudo chmod -R 777 /storage
  sudo chown -R nobody:nogroup /storage

  # Configure NFS
  echo "Configure NFS"
  echo "/storage           *(rw,sync,no_subtree_check,async,insecure,no_root_squash)" | sudo tee -a /etc/exports
  sudo systemctl restart nfs
  sudo exportfs -a


  # Create PersistentVolumes
  echo "Create PersistentVolumes"
  kubectl apply -f ~/INSTALL/KUBE/PV/pv.yaml
else
  echo "PersistentVolumes not configured"
fi



echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
read -p "Install and configure ISTIO? [y,N]" DO_ISTIO
if [[ $DO_ISTIO == "y" ||  $DO_ISTIO == "Y" ]]; then
  # Install ISTIO
  echo "Install ISTIO"
  cd ~/INSTALL/ISTIO

  wget https://github.com/istio/istio/releases/download/0.8.0/istio-0.8.0-linux.tar.gz
  tar -xzf istio-0.8.0-linux.tar.gz
  export PATH="$PATH:~/INSTALL/ISTIO/istio-0.8.0/bin"

  cd istio-0.8.0

  sudo cp bin/istioctl /usr/local/bin/

  # Create ISTIO
  echo "Create ISTIO Resources"

  cd ~/INSTALL/ISTIO/istio-0.8.0

  kubectl apply -f ./install/kubernetes/istio-demo.yaml

  kubectl -n istio-system delete -f ~/INSTALL/ISTIO/ingress_gateway.json
  kubectl -n istio-system apply -f ~/INSTALL/ISTIO/ingress_gateway.json

  istioctl create -f ~/INSTALL/ISTIO/helloworld_destinationrule.yaml

  istioctl get virtualservice

  cat ~/INSTALL/ISTIO/bashrc_add_istio.sh >> ~/.bashrc

else
  echo "ISTIO not configured"
fi





echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
read -p "Install and configure Alert Manager? [y,N]" DO_AM
if [[ $DO_AM == "y" ||  $DO_AM == "Y" ]]; then
  # Create ALERTS
  echo "Create ALERTS"

  kubectl -n kube-system delete -f ~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertrules_config.yaml
  kubectl -n kube-system delete -f ~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertmanager_config.yaml

  kubectl -n kube-system apply -f ~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertrules_config.yaml
  kubectl -n kube-system apply -f ~/INSTALL/KUBE/CONFIG/monitoring-prometheus-alertmanager_config.yaml
else
  echo "Alert Manager not configured"
fi

read -p "Install and configure CALICO Commandline? [y,N]" DO_CAL
if [[ $DO_CAL == "y" ||  $DO_CAL == "Y" ]]; then
  # Create ALERTS
  echo "Download CALICO Commandline"
  docker run -v /root:/data --entrypoint=cp ibmcom/calico-ctl:v2.0.2 /calicoctl /data
  sudo cp /root/calicoctl /usr/local/bin/
  export ETCD_CERT_FILE=/etc/cfc/conf/etcd/client.pem
  export ETCD_CA_CERT_FILE=/etc/cfc/conf/etcd/ca.pem
  export ETCD_KEY_FILE=/etc/cfc/conf/etcd/client-key.pem
  export ETCD_ENDPOINTS=https://mycluster.icp:4001

else
  echo "CALICO Commandline not configured"
fi

read -p "Install and configure Liberty Demo? [y,N]" DO_LIB
if [[ $DO_LIB == "y" ||  $DO_LIB == "Y" ]]; then
  # Create Liberty Demo
  echo "Download Liberty Demo"
  cd ~/INSTALL/
  git clone https://github.com/niklaushirt/demoliberty.git
  cd ~/INSTALL/demoliberty
  docker build -t demoliberty:1.0.0 docker_100
  docker build -t demoliberty:1.1.0 docker_110
  docker build -t demoliberty:1.2.0 docker_120
  docker build -t demoliberty:1.3.0 docker_130

  docker login mycluster.icp:8500 -u admin -p admin
  docker tag mple:1.3.0 mycluster.icp:8500/default/demoliberty:1.3.0
  docker tag demoliberty:1.3.0 mycluster.icp:8500/default/demoliberty:1.2.0
  docker tag demoliberty:1.3.0 mycluster.icp:8500/default/demoliberty:1.1.0
  docker tag demoliberty:1.3.0 mycluster.icp:8500/default/demoliberty:1.0.0
  docker push mycluster.icp:8500/default/demoliberty:1.3.0
  docker push mycluster.icp:8500/default/demoliberty:1.2.0
  docker push mycluster.icp:8500/default/demoliberty:1.1.0
  docker push mycluster.icp:8500/default/demoliberty:1.0.0

  echo "SET WORKER PLACEMENT labels"
  for ((i=0; i < $NUM_WORKERS; i++)); do
    kubectl label nodes ${WORKER_IPS[i]} placement=local
  done

else
  echo "Liberty Demo not configured"
fi




echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
read -p "Install and configure Demo Stuff? [y,N]" DO_STF
if [[ $DO_STF == "y" ||  $DO_STF == "Y" ]]; then
  # Create some Stuff
  echo "Create some Stuff"
  cd ~/INSTALL/
  kubectl create secret docker-registry camsecret --docker-username=test --docker-password=abcd --docker-email=test@gmail.com -n services
  kubectl create -f ~/INSTALL/KUBE/CONFIG/devlimits_quota.yaml
  kubectl create -f ~/INSTALL/KUBE/CONFIG/restricted_policy.yaml
  kubectl create -f ~/INSTALL/KUBE/CONFIG/privileged_policy.yaml
  kubectl create -f ~/INSTALL/KUBE/CONFIG/calico_demo.yaml

  cat ~/INSTALL/KUBE/CONFIG/bashrc_add_stress.sh >> ~/.bashrc
else
  echo "Stuff not configured"
fi




echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "ALL DONE"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Please execute 'source ~/.bashrc'"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Configure LDAP"
echo "-----------------------------------------------------------------------------------------------------------"
echo "LDAP_ID               : OPENLDAP"
echo "LDAP_URL              : ldap://${PUBLIC_IP}:389"
echo "LDAP_BASEDN           : dc=mycluster,dc=icp"
echo "LDAP_BINDDN           : cn=admin,dc=mycluster,dc=icp"
echo "LDAP_BINDPASSWORD     : admin"
echo "LDAP_TYPE             : Custom"
echo "LDAP_USERFILTER       : (&(uid=%v)(objectclass=person))"
echo "LDAP_GROUPFILTER      : (&(cn=%v)(objectclass=groupOfUniqueNames))"
echo "LDAP_USERIDMAP        :  *:uid"
echo "LDAP_GROUPIDMAP       : *:cn"
echo "LDAP_GROUPMEMBERIDMAP : groupOfUniqueNames:uniquemember"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Add Repositories"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Charts"
echo "https://raw.githubusercontent.com/niklaushirt/charts/master/charts/repo/stable/"
echo ""
echo "Liberty Simple"
echo "https://raw.githubusercontent.com/niklaushirt/demoliberty/master/charts/stable/repo/stable/"
echo ""
echo "Service Broker"
echo "https://raw.githubusercontent.com/niklaushirt/servicebroker/master/charts/repo/stable/"
