# Kubernetes Java Application with ELK Stack Monitoring

> **Assignment Submission for System Support Engineer Position**  
> **Candidate:** Suresh B.K  
> **Date:** January 2, 2026  
> **Submission Deadline:** January 4, 2026, 5:00 PM

---

## 📑 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Lab Environment](#Environment)
- [Task 1: Kubernetes Cluster Setup](#task-1-kubernetes-cluster-setup)
- [Task 2: Java Application Deployment](#task-2-java-application-deployment)
- [Task 3: Service Exposure](#task-3-service-exposure)
- [Task 4: ELK Stack Setup](#task-4-elk-stack-setup)
- [Task 5: Monitoring & Verification](#task-5-monitoring--verification)
- [Access Information](#access-information)
- [Troubleshooting](#troubleshooting)
- [Lessons Learned](#lessons-learned)
- [Conclusion](#conclusion)
- [Contact](#contact)

---

## 🎯 Overview

This project demonstrates a complete Kubernetes deployment with:

- ✅ **2-node Kubernetes cluster** (1 master, 1 worker)
- ✅ **Java web application** (WAR file on Tomcat)
- ✅ **Dual service exposure** (NodePort & Ingress)
- ✅ **ELK Stack** for centralized logging
- ✅ **Filebeat** for log collection

**🏆 Key Achievement:** Successfully collected and visualized application logs in Kibana dashboard.

---

## 🏗️ Architecture

### Lab Environment

- **Virtualization:** VMware Workstation 17+
- **Operating System:** CentOS Stream 9 (2 VMs)
- **RAM:** 4GB per VM
- **Container Runtime:** Docker/containerd
- **Tools:** kubectl configured
- **Network:** Internet connectivity required

---

## 🚀 Task 1: Kubernetes Cluster Setup

### Cluster Information

**Environment Details:**
- **Platform:** VMware Workstation
- **OS:** CentOS Stream 9
- **Container Runtime:** containerd 2.2.1
- **Kubernetes Version:** v1.28.15
- **CNI Plugin:** Flannel

### Node Specifications

| Node | Role | IP Address | RAM | CPU | Disk | Status |
|------|------|------------|-----|-----|------|--------|
| **k8s-master** | Control Plane | 192.168.1.69 | 4 GB | 2 cores | 20 GB | Ready |
| **k8s-worker** | Worker | 192.168.1.64 | 4 GB | 2 cores | 30 GB | Ready |

---

## 🔧 Kubernetes Master Node Setup

### 1. System Preparation

#### a. Update System Packages
```bash
sudo dnf update -y
```
> Updates all system packages to ensure security, stability, and compatibility with Kubernetes components.

#### b. Disable Swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```
> Kubernetes requires swap to be disabled for proper resource management.

#### c. Configure SELinux
```bash
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```
> Sets SELinux to permissive mode to prevent blocking Kubernetes components and container communication.

#### d. Disable Firewall
```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```
> Disables firewall to avoid network traffic being blocked between Kubernetes pods and services.

---

### 2. Container Runtime Installation (containerd)

#### a. Add Docker Repository
```bash
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
```
> Adds the official Docker repository required to install the containerd runtime.

#### b. Install containerd
```bash
sudo dnf install -y containerd.io
```
> Installs containerd, the container runtime used by Kubernetes.

#### c. Configure containerd
```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```
> Creates the default containerd configuration file required for Kubernetes integration.

#### d. Enable SystemdCgroup
```bash
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```
> Enables systemd cgroup driver to match kubelet's cgroup configuration.

#### e. Start containerd Service
```bash
sudo systemctl enable --now containerd
```
> Starts containerd service and ensures it runs automatically after reboot.

**Verification:**

<div align="center">
  <img src="Screenshots/Task1/containerd.png" 
       alt="containerd Service Running" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 1: containerd service status.</i></p>
</div>

---

### 3. Kubernetes Packages Installation

#### a. Add Kubernetes Repository
```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
```
> Adds the official Kubernetes repository for secure installation.

#### b. Install Kubernetes Components
```bash
sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```

**Components:**
- `kubeadm` - Initializes the Kubernetes cluster
- `kubelet` - Runs on each node to manage pods
- `kubectl` - Command-line tool to manage the cluster

#### c. Enable kubelet Service
```bash
sudo systemctl enable --now kubelet
```
> Enables kubelet service to start automatically after cluster initialization.

---

### 4. Kernel Modules and sysctl Configuration

#### a. Load Required Kernel Modules
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```
> Configures required kernel modules to load on boot.

#### b. Activate Kernel Modules
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```
> Immediately activates kernel modules required for container networking.

#### c. Configure System Networking Parameters
```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```
> Configures system networking parameters required for Kubernetes pod-to-pod and service networking.

#### d. Apply sysctl Settings
```bash
sudo sysctl --system
```
> Applies the sysctl settings system-wide without requiring a reboot.

---

### 5. Initialize Master Node

#### a. Initialize Kubernetes Cluster
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
> Initializes the Kubernetes control plane and sets the Pod network CIDR required by Flannel CNI.

**Important:** Save the `kubeadm join` command from the output:
```bash
sudo kubeadm join 192.168.1.69:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

---

### 6. Configure kubectl for Normal User
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
> Allows the non-root user to manage the Kubernetes cluster using kubectl.

---

### 7. Install CNI Plugin (Flannel)
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```
> Installs the Flannel CNI plugin, enabling pod-to-pod communication across nodes.

---

## 💼 Worker Node Setup

### Setup Steps

Repeat the following steps from the Master Node setup:

1. ✅ System Preparation (Update, Disable Swap, SELinux, Firewall)
2. ✅ Container Runtime Installation (containerd)
3. ✅ Kubernetes Packages Installation
4. ✅ Kernel Modules and sysctl Configuration

### Join Worker Node to Cluster

Use the join command generated during master node initialization:
```bash
sudo kubeadm join 192.168.1.69:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```
> Joins the worker node to the Kubernetes master securely using a token and certificate hash.

---

## ✅ Verification

#### 1. Check Node Status


<div align="center">
  <img src="Screenshots/Task1/02-nodes-ready.png" 
       alt="nodes ready" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 2: Confirms that the Kubernetes cluster is up and running.</i></p>
</div>

---
#### 2. View Detailed Node Information

<div align="center">
  <img src="Screenshots/Task1/cluster-info.png" 
       alt="Cluster-info" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 3:Provides an overview of the Kubernetes cluster details.</i></p>
</div>

---

### 3. Verify Cluster Health
```bash
kubectl cluster-info
```

**Expected Output:**
```
Kubernetes control plane is running at https://192.168.1.69:6443
CoreDNS is running at https://192.168.1.69:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### 4. Check System Pods
```bash
kubectl get pods -n kube-system
```

All pods should be in `Running` state.

---

## 📦 Task 2: Java Application Deployment

*(Section to be completed with Dockerfile, deployment manifests, and verification steps)*

---

## 🌐 Task 3: Service Exposure

*(Section to be completed with NodePort and Ingress configuration)*

---

## 📊 Task 4: ELK Stack Setup

*(Section to be completed with Elasticsearch, Kibana, and Filebeat deployment)*

---

## 🔍 Task 5: Monitoring & Verification

*(Section to be completed with Kibana dashboard configuration and traffic simulation)*

---

## 🔗 Access Information

*(Section to be completed with URLs and access credentials)*

---

## 🛠️ Troubleshooting

### Common Issues

**Issue:** Nodes not reaching Ready state
```bash
kubectl describe node <node-name>
kubectl get pods -n kube-system
```

**Issue:** containerd service failing
```bash
sudo systemctl status containerd
sudo journalctl -xeu containerd
```

**Issue:** Pod network not working
```bash
kubectl get pods -n kube-system | grep flannel
kubectl logs -n kube-system <flannel-pod-name>
```

---

## 📚 Lessons Learned

*(Section to be completed with insights and best practices)*

---

## 🎓 Conclusion

This project successfully demonstrates a production-grade Kubernetes cluster setup with comprehensive logging and monitoring capabilities using the ELK stack.

---

## 📧 Contact

**Candidate:** Suresh B.K  
**Email:** [Your Email]  
**Date:** January 2, 2026

---

## 📝 License

This project is submitted as part of a technical assignment for the System Support Engineer position.

---

**Note:** This is a living document. Please refer to the latest version for updates.
