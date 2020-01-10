#!/bin/bash

#Following ports should be free before installing voltha

#Service                             :PortNumber
#voltha-etcd-cluster                 :2379
#voltha-api                          :55555
#kindest-node                        :45004
#onos-ssh                            :8101
#onos-ui                             :8181


echo -e "\e[31;43m****Do You want to install Kind-Voltha from scratch?(This will first fetch required tools and repo's and then install kind-voltha)[Y/N]****\e[0m"

read choice

port_check(){

declare -a listofports=("8101" "45004" "55555" "8181" "30115" "30120" "30555")

ports_in_use=0

for port in "${listofports[@]}"
do
      
       if netstat -lntp | grep :$port > /dev/null ; then
               echo "$port"
               used_process=$(netstat -lntp | grep :$port | tr -s ' ' | cut -f7 -d' ')
               echo "ERROR: Process with PID/Program_name $used_process is already listening on port: $port needed by VOLTHA"
               ports_in_use=$((ports_in_use+1))
       fi
done
if [ $ports_in_use -gt 0 ]
    then
         echo "Kill the running services mentioned above before proceeding to install KIND-VOLTHA"
         echo  -e "\e[31;43m****Terminating Kind-Voltha Installation****\e[0m"
         exit 1
fi
}

if [ "${choice::1}" = "Y" ] || [ "${choice::1}" = "y" ]; then
    echo  -e "\e[31;43m****Installing KIND-VOLTHA From Scratch****\e[0m"
    port_check
    export GOPATH=/usr/local/go
    export PATH=$PATH:$GOPATH/bin
    ver=$(go version)
    if [ "${ver::2}" != "go" ]; then
        wget https://dl.google.com/go/go1.12.9.linux-amd64.tar.gz
        tar -xvf go1.12.9.linux-amd64.tar.gz
    fi
    mv go /usr/local
    apt install docker
    apt install docker-ce
    export GOPATH=$(pwd)
    export GOPATH=/usr/local/go
    export PATH=$PATH:$GOPATH/bin
    export PATH="$(go env GOPATH)bin:$PATH"
    mkdir -p $GOPATH/bin
    curl -o $GOPATH/bin/kubectl -sSL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/$(go env GOHOSTOS)/$(go env GOARCH)/kubectl
    curl -o $GOPATH/bin/kind \
    -sSL https://github.com/kubernetes-sigs/kind/releases/download/v0.4.0/kind-$(go env GOHOSTOS)-$(go env GOARCH)
    curl -o $GOPATH/bin/voltctl \
    -sSL https://github.com/ciena/voltctl/releases/download/0.0.5-dev/voltctl-0.0.5_dev-$(go env GOHOSTOS)-$(go env GOARCH)
    curl -sSL https://git.io/get_helm.sh | USE_SUDO=false HELM_INSTALL_DIR=$(go env GOPATH)/bin bash
    chmod 755 $GOPATH/bin/kind $GOPATH/bin/voltctl $GOPATH/bin/kubectl
    export PATH=$(go env GOPATH)/bin:$PATH
    export TYPE=minimal
    export KUBECONFIG="$(kind get kubeconfig-path --name="voltha-$TYPE")"
    export VOLTCONFIG="/root/.volt/config-minimal"
    running_pods=$(kubectl get pods -n voltha)
    if docker ps | grep kindest > /dev/null && kubectl get pods -n voltha | grep voltha-kafka > /dev/null ; then
        echo  -e "\e[31;43m****Kind-Voltha SetUp was already there on this machine!!Showing list of the VOLTHA-PODS****\e[0m"
        echo  -e "$running_pods"
    else
        git clone http://github.com/ciena/kind-voltha
        cd kind-voltha/
        ./voltha up
        sleep 15
        echo  -e "\e[31;43m****KIND-VOLTHA INSTALLED SUCCESSFULLY****\e[0m"
        export GOPATH=/usr/local/go
        export PATH=$PATH:$GOPATH/bin
        export PATH="$(go env GOPATH)bin:$PATH"
        export KUBECONFIG="$(kind get kubeconfig-path --name="voltha-$TYPE")"
        export VOLTCONFIG="/root/.volt/config-minimal"
        echo  -e "\e[31;43m****Showing list of the VOLTHA-PODS****\e[0m"
        kubectl get pod -n voltha
    fi
    
else
    echo  -e "\e[31;43m****Not Installing KIND-VOLTHA From Scratch****\e[0m"
    export GOPATH=/usr/local/go
    export PATH=$PATH:$GOPATH/bin
    ver=$(go version)
    if [ "${ver::2}" != "go" ]; then
        echo  -e "\e[31;43m****GO IS NOT INSTALLED-Please select option Y while running the script****\e[0m"
        echo  -e "\e[31;43m****Terminating installation****\e[0m"
        exit 1
    fi
    export GOPATH=/usr/local/go
    export PATH=$PATH:$GOPATH/bin
    export PATH="$(go env GOPATH)bin:$PATH"
    export TYPE="minimal"
    export KUBECONFIG="$(kind get kubeconfig-path --name="voltha-$TYPE")"
    export VOLTCONFIG="/root/.volt/config-minimal"
    running_pods=$(kubectl get pods -n voltha)
    if docker ps | grep kindest > /dev/null && kubectl get pods -n voltha | grep voltha-kafka > /dev/null ; then
        echo  -e "\e[31;43m****Kind-Voltha SetUp was already there on this machine!!Showing list of the VOLTHA-PODS****\e[0m"
        echo  -e "$running_pods"
    else
        export GOPATH=/usr/local/go
        export PATH=$PATH:$GOPATH/bin
        export PATH="$(go env GOPATH)bin:$PATH"
        export TYPE="minimal"
        port_check
        ./voltha down
        ./voltha up
        sleep 15
        echo  -e "\e[31;43m****KIND-VOLTHA INSTALLED SUCCESSFULLY****\e[0m"
        export GOPATH=/usr/local/go
        export PATH=$PATH:$GOPATH/bin
        export PATH="$(go env GOPATH)bin:$PATH"
        export KUBECONFIG="$(kind get kubeconfig-path --name="voltha-$TYPE")"
        export VOLTCONFIG="/root/.volt/config-minimal"
        echo  -e "\e[31;43m****Showing list of the VOLTHA-PODS****\e[0m"
        kubectl get pod -n voltha
    fi

        
fi

