
Suse Linux Exterprise 15 based spilo image
===========================================

To build image use SLES15 SP4 system
If needed one can be used on AWS in 
Zone: Ireland 
AMI: suse-sles-15-sp4-v20221216-hvm-ssd-x86_64

Following is main docs refrence:

https://www.suse.com/c/upgrading-suse-linux-enterprise-in-the-public-cloud/

The first thing you will want to do is PREPARE the instance, ensuring the instance is fully up-to-date with the latest updates.  To do this, run:

ec2-user@ip-172-31-47-158:~> sudo zypper patch

Make sure to read the output while running this command.  There are cases where you may need to run this command more than once if a package manager restart is required. 

ec2-user@ip-172-31-47-158:~> sudo zypper migration

Follow the prompts to select your migration target.  Once the upgrade completes, reboot the instance. 


https://documentation.suse.com/sles/15-SP3/html/SLES-all/cha-docker-building-images.html

To vuild image use following:

~/spilo_sles/postgres-appliance> podman build --rm --logfile build.log --jobs 1 --network host --build-ar
g COMPRESS=true  -t spilo_sles:15_compress -f Dockerfile.sles . 2>&1 | tee build.log

push to the dockerhub repo
podman login docker.io 
podman push a805ca80458c docker://docker.io/cybertecpostgresql/spilo_sles:15_compress

to run locally use 

podman run --rm --name spilo -e SPILO_PROVIDER=local spilo_sles:15_compress

to run in k3s using podman

sudo podman run --privileged --name k3s-server-1 --hostname k3s-server-1 -p 6443:6443 rancher/k3s:v1.24.10-k3s1 server
sudo podman cp k3s-server-1:/etc/rancher/k3s/k3s.yaml .k3s.yaml
sudo KUBECONFIG=.k3s.yaml kubectl get nodes

KUBECONFIG=.k3s.yaml helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
KUBECONFIG=.k3s.yaml helm install postgres-operator postgres-operator-charts/postgres-operator

sudo KUBECONFIG=.k3s.yaml kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=hlihovac --docker-password="#qw789docker123yx" --docker-email=hlihovac@gmail.com
sudo KUBECONFIG=.k3s.yaml kubectl create -f https://raw.githubusercontent.com/zalando/postgres-operator/master/manifests/minimal-postgres-manifest.yaml

then modify opconfig to accomodate for new image

export KUBECONFIG=.k3s.yaml
kubectl edit opconfig postgres-operator

configuration:
  docker_image: cybertecpostgresql/spilo_sles:15_compress
  kubernetes:
    spilo_allow_privilege_escalation: true
    spilo_privileged: true

modify service account postgres-pod to add image registry secret
imagePullSecrets:
- name: regcred
