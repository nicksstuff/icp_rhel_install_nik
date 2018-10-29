#!/bin/bash

source ~/INSTALL/0_variables.sh



echo "-----------------------------------------------------------------------------------------------------------"
echo "-----------------------------------------------------------------------------------------------------------"
echo "Preparing Cluster";

read -p "Can your Cluster already communicate with SSH? [Y,n]" DO_CAL

if [[ $DO_CAL == "n" ||  $DO_CAL == "N" ]]; then

    echo "Create Key"
    # Generate RSA key
    mkdir ~/.ssh
    ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ""
    cat ~/.ssh/master.id_rsa.pub | tee -a ~/.ssh/authorized_keys
    ssh-copy-id -i ~/.ssh/master.id_rsa.pub ${SSH_USER}@$MASTER_IP

    echo IdentityFile ~/.ssh/master.id_rsa | sudo tee -a ~/.ssh/config

    for ((i=0; i < $NUM_WORKERS; i++)); do
      if [[ $WORKER_IPS[i] != "n" ||  $MASTER_IP == "N" ]]; then
        # If host IP exists in known hosts remove it
        sudo ssh-keygen -R ${WORKER_IPS[i]} -f ~/.ssh/known_hosts
        # Add host IP to known hosts
        sudo ssh-keyscan -H ${WORKER_IPS[i]} | sudo tee -a ~/.ssh/known_hosts

        sudo scp ~/.ssh/master.id_rsa.pub ${SSH_USER}@${WORKER_IPS[i]}:~/.ssh/master.id_rsa.pub
        sudo ssh ${SSH_USER}@${WORKER_IPS[i]} 'mkdir -p ~/.ssh; cat ~/.ssh/master.id_rsa.pub | tee -a ~/.ssh/authorized_keys'
        #sudo ssh ${SSH_USER}@${WORKER_IPS[i]} 'systemctl restart sshd'
      fi
    done

    #sudo systemctl restart sshd


    echo "Adapt HOSTS file"
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
      if [[ $WORKER_IPS[i] != "n" ||  $MASTER_IP == "N" ]]; then
        echo "${WORKER_IPS[i]} ${WORKER_HOSTNAMES[i]}" | sudo tee -a /etc/hosts
      fi
    done

    sudo cp /etc/hosts ~/worker-hosts
    sudo chown $USER ~/worker-hosts

    echo "$MASTER_IP mycluster.icp" | sudo tee -a /etc/hosts


    for ((i=0; i < $NUM_WORKERS; i++)); do
      if [[ $WORKER_IPS[i] != "n" ||  $MASTER_IP == "N" ]]; then
        # Remove old instance of host
       sudo ssh ${SSH_USER}@${WORKER_HOSTNAMES[i]} 'cp /etc/hosts ~/hosts.bak'
        # Replace worker hosts with file
        sudo scp /etc/hosts root@${WORKER_HOSTNAMES[i]}:/etc/hosts
      fi
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
      echo "${WORKER_IPS[i]} ${SSH_USER}@${WORKER_HOSTNAMES[i]}" | sudo tee -a /etc/hosts
    done
    echo "" | sudo tee -a /etc/hosts

    sudo cp /etc/hosts ~/worker-hosts
    sudo chown $USER ~/worker-hosts

    echo "$MASTER_IP mycluster.icp" | sudo tee -a /etc/hosts
fi
