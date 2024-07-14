#!/bin/bash -x

hostname=$1
ip=$2

echo "provisioning $hostname with $ip"
hostnamectl set-hostname $hostname
cp /vagrant/hosts.txt /etc/hosts
sed -i s/'{HOSTNAME}'/$hostname/g /etc/hosts

apt install net-tools -y


#sudo cat /etc/hosts  | grep $ip
#if [ $? != 0 ]; then
#	echo "$ip $hostname" >> /etc/hosts
#fi

: ' docker ps
if [ $? != 0 ]; then
	sudo apt-get update
	sudo apt-get install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update

	sudo apt-get install -y --allow-unauthenticated docker-ce docker-ce-cli containerd.io #docker-buildx-plugin docker-compose-plugin

	sudo docker run hello-world
	
	echo "docker is installed "
else
  echo "docker is installed already"
fi
'
ctr containers ls

if [ $? != 0 ]; then
	wget https://github.com/containerd/containerd/releases/download/v1.7.19/containerd-1.7.19-linux-amd64.tar.gz
	tar Cxzvf /usr/local containerd-1.7.19-linux-amd64.tar.gz
	 
	mkdir -p /usr/local/lib/systemd/system
	wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -O /usr/local/lib/systemd/system/containerd.service
	systemctl unmask containerd.service
	systemctl daemon-reload
	systemctl enable --now containerd
	 
	wget https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64
	install -m 755 runc.amd64 /usr/local/sbin/runc
	
	wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
	mkdir -p /opt/cni/bin
	tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz
	 
	service containerd restart
	 
	 
fi

swapoff -a

kubectl version
if [[ $? != 0 && $? != 1 ]]; then
	sudo apt-get update
	sudo apt-get install -y apt-transport-https ca-certificates curl gpg

	sudo mkdir -p -m 755 /etc/apt/keyrings
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

	sudo apt-get update
	sudo apt-get install -y kubelet kubeadm kubectl
	sudo apt-mark hold kubelet kubeadm kubectl
	
	alias k=kubectl
	complete -o default -F __start_kubectl k
	
cat <<EOT >> ~/.bashrc
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
source <(kubectl completion bash)
source <(kubeadm completion bash)
EOT

	sudo systemctl enable --now kubelet
	
mkdir /etc/sysctl.d
touch /etc/sysctl.d/k8s.conf

cat <<EOT >> /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOT
	
	sudo sysctl --system

	ipforwarded=$(sysctl net.ipv4.ip_forward)
	
	echo "ipforwarded: $ipforwarded"
	
	if [[ "$ipforwarded" == 1 ]]; then
		echo "ip is forwarded ok."
	fi
	
	echo "checking containerd config"
	mkdir /etc/containerd
	containerd config default > /etc/containerd/config.toml
	
	cat /etc/containerd/config.toml | grep "SystemdCgroup = true"
	if [ $? != 0 ]; then
		echo "adding SystemdCgroup"
		sed -i s/'SystemdCgroup = false'/'\SystemdCgroup = true'/g /etc/containerd/config.toml
		#sed -i s/'k8s.gcr.io\/pause\:3.2'/'registry.k8s.io\/pause\:3.9'/g /etc/containerd/config.toml
	fi
	service containerd restart
	
	echo "kubectl, kubeadm is installed "
	
	
else
	echo "kubectl is installed already"
	if [[ "$hostname" == "k8s-master-1" ]]; then
		mkdir /etc/keepalived
		
		cp /vagrant/keepalived.conf /etc/keepalived/
		chmod -x /etc/keepalived/keepalived.conf
		cp /vagrant/check_apiserver.sh /etc/keepalived/
		chmod +x /etc/keepalived/check_apiserver.sh
		
		mkdir /etc/haproxy
		cp /vagrant/haproxy.cfg /etc/haproxy/
		netstat -plnt | grep 6443
		if [[ $? == 1 ]]; then
			kubeadm init --apiserver-advertise-address=$ip --control-plane-endpoint=k8s-master-lb --upload-certs --pod-network-cidr=192.168.3.0/16
			join_command=$(kubeadm token create --print-join-command)
			
			upload_certs_cmd=$(kubeadm init phase upload-certs --upload-certs)
			cert_key=$(echo $upload_certs_cmd | awk -F'Using certificate key: ' '{print $2}')
			echo "$join_command --certificate-key $cert_key" > /vagrant/join_command.txt
			
			export KUBECONFIG=/etc/kubernetes/admin.conf
			kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
			
			wget https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
			sed -i s/'192.168.0.0\/16'/'192.168.3.0\/16'/g custom-resources.yaml
			
			kubectl create -f custom-resources.yaml
			
			echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
			
		fi
		
		
	else
		if [[ "$hostname" == "k8s-master-2" || "$hostname" == "k8s-master-3" ]]; then
			join_command=$(cat /vagrant/join_command.txt)
			join_command="$join_command --control-plane --apiserver-advertise-address=$ip"
			$join_command
		else
			join_command=$(cat /vagrant/join_command.txt)
			join_command="$join_command --apiserver-advertise-address=$ip"
			$join_command
		fi
	fi
fi
