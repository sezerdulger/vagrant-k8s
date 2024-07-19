#!/bin/bash -x


echo "provisioning $hostname with $ip"
hostnamectl set-hostname k8s-master-lb
cp /vagrant/hosts.txt /etc/hosts
sed -i s/'{HOSTNAME}'/'k8s-master-lb'/g /etc/hosts

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py --user
python3 -m pip install --user ansible
mkdir /etc/ansible
touch /etc/ansible/hosts

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

curl -sLS https://get.k3sup.dev | sh

if [ ! -f '/root/.ssh/id_rsa' ]; then ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa; fi
apt-get update && apt-get install expect -y


./k3s-cluster.sh

service nginx status

if [[ $? != 0 ]]; then

	cat <<EOF
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi
EOF
>> ~/.bashrc
	source ~/.bashrc

	sudo apt-get update
	sudo apt-get install -y nginx net-tools
	
	echo "include /etc/nginx/tcp.conf.d/*.conf;" >> /etc/nginx/nginx.conf
	mkdir /etc/nginx/tcp.conf.d

	cp /vagrant/k8s-master-lb/apiserver.conf.txt /etc/nginx/tcp.conf.d/apiserver.conf
	service nginx restart
else
	sed -i s/'#'/''/g /etc/nginx/tcp.conf.d/*.conf
	service nginx restart
fi

