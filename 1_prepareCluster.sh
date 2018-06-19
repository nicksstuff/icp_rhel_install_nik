#!/bin/bash

source ~/INSTALL/0_variables.sh



echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Preparing Cluster";

read -p "Can your Cluster already communicate with SSH? [Y,n]" DO_CAL
echo "Just update all the hosts"
if [[ $DO_CAL == "n" ||  $DO_CAL == "N" ]]; then

# Generate RSA key
ssh-keygen -b 4096 -t rsa -f ~/.ssh/id_rsa -N ""

# Move RSA key to workers
for ((i=0; i < $NUM_WORKERS; i++)); do
  # Prevent SSH identity prompts
  # If host IP exists in known hosts remove it
  ssh-keygen -R ${WORKER_IPS[i]}
  # Add host IP to known hosts
  ssh-keyscan -H ${WORKER_IPS[i]} | tee -a ~/.ssh/known_hosts

  # Copy over key (Will prompt for password)
  scp ~/.ssh/id_rsa.pub ${SSH_USER}@${WORKER_IPS[i]}:~/id_rsa.pub
  ssh ${SSH_USER}@${WORKER_IPS[i]} 'mkdir -p ~/.ssh; cat ~/id_rsa.pub | tee -a ~/.ssh/authorized_keys'
done

echo IdentityFile ~/.ssh/id_rsa | tee -a ~/.ssh/config




# Back up old hosts file
sudo cp /etc/hosts /etc/hosts.bak

echo "127.0.0.1 localhost" | sudo tee /etc/hosts
echo "" | sudo tee -a /etc/hosts

echo "fe00::0 ip6-localnet" | sudo tee -a /etc/hosts
echo "ff00::0 ip6-mcastprefix" | sudo tee -a /etc/hosts
echo "ff02::1 ip6-allnodes" | sudo tee -a /etc/hosts
echo "ff02::2 ip6-allrouters" | sudo tee -a /etc/hosts
echo "ff02::3 ip6-allhosts" | sudo tee -a /etc/hosts
echo "" | sudo tee -a /etc/hosts

# Loop through the array
for ((i=0; i < $NUM_WORKERS; i++)); do
  echo "${WORKER_IPS[i]} ${WORKER_HOSTNAMES[i]}" | sudo tee -a /etc/hosts
done
echo "" | sudo tee -a /etc/hosts

sudo cp /etc/hosts ~/worker-hosts
sudo chown $USER ~/worker-hosts

echo "$MASTER_IP mycluster.icp" | sudo tee -a /etc/hosts

for ((i=0; i < $NUM_WORKERS; i++)); do
  # Remove old instance of host
  ssh-keygen -R ${WORKER_IPS[i]}
  ssh-keygen -R ${WORKER_HOSTNAMES[i]}

  # Do not ask to verify fingerprint of server on ssh
  ssh-keyscan -H ${WORKER_IPS[i]} >> ~/.ssh/known_hosts
  ssh-keyscan -H ${WORKER_HOSTNAMES[i]} >> ~/.ssh/known_hosts

  # Copy over file
  sudo scp -i ${SSH_KEY} ~/worker-hosts  ${SSH_USER}@${WORKER_HOSTNAMES[i]}:~/worker-hosts

  # Replace worker hosts with file
  ssh -i ${SSH_KEY} ${SSH_USER}@${WORKER_HOSTNAMES[i]} 'sudo cp /etc/hosts /etc/hosts.bak; sudo mv ~/worker-hosts /etc/hosts'
done


# Make a new key so we are not reusing our key for server communications
ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ""
sudo mkdir -p /root/.ssh
cat ~/.ssh/master.id_rsa.pub | sudo tee /root/.ssh/authorized_keys | tee -a ~/.ssh/authorized_keys


# Make sure SSH uses this key by default (makes next commands easier)
# no quotes in echo so ~ expands to usr root
echo IdentityFile ~/.ssh/master.id_rsa | sudo tee -a /root/.ssh/config | tee -a ~/.ssh/config

# Loop through the array
for ((i=0; i < $NUM_WORKERS; i++)); do
  # Prevent SSH identity prompts
  # If hostname exists in known hosts remove it
  ssh-keygen -R ${WORKER_HOSTNAMES[i]}
  # Add hostname to known hosts
  ssh-keyscan -H ${WORKER_HOSTNAMES[i]} | tee -a ~/.ssh/known_hosts

  # Allow root and user login
  ssh -i ${SSH_KEY} ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo mkdir -p /root/.ssh
  scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub ${SSH_USER}@${WORKER_HOSTNAMES[i]}:~/.ssh/master.id_rsa.pub

  ssh -i ${SSH_KEY} ${SSH_USER}@${WORKER_HOSTNAMES[i]} 'cat ~/.ssh/master.id_rsa.pub | sudo tee /root/.ssh/authorized_keys | tee -a ~/.ssh/authorized_keys; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config'
  ssh -i ${SSH_KEY} ${SSH_USER}@${WORKER_HOSTNAMES[i]} sudo service sshd restart

done
else
  echo "Just update the hosts file"
  # Back up and adapt old hosts file
  sudo cp /etc/hosts /etc/hosts.bak


  echo "127.0.0.1 localhost" | sudo tee /etc/hosts
  echo "" | sudo tee -a /etc/hosts

  echo "fe00::0 ip6-localnet" | sudo tee -a /etc/hosts
  echo "ff00::0 ip6-mcastprefix" | sudo tee -a /etc/hosts
  echo "ff02::1 ip6-allnodes" | sudo tee -a /etc/hosts
  echo "ff02::2 ip6-allrouters" | sudo tee -a /etc/hosts
  echo "ff02::3 ip6-allhosts" | sudo tee -a /etc/hosts
  echo "" | sudo tee -a /etc/hosts


  # Loop through the array
  for ((i=0; i < $NUM_WORKERS; i++)); do
    echo "${WORKER_IPS[i]} ${WORKER_HOSTNAMES[i]}" | sudo tee -a /etc/hosts
  done
  echo "" | sudo tee -a /etc/hosts

  sudo cp /etc/hosts ~/worker-hosts
  sudo chown $USER ~/worker-hosts

  echo "$MASTER_IP mycluster.icp" | sudo tee -a /etc/hosts
fi
