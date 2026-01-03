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

#### 4. Check System Pods

<div align="center">
  <img src="Screenshots/Task1/04-kube-A.png" 
       alt="pod-state" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 4:All pods are running State.</i></p>
</div>

---

## 🛠️ Troubleshooting - Task 1

### Issue: Worker Node Join Failure

**Error Message:**
```bash
[ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
```

---

### Quick Fix Steps

**Step 1: Verify containerd**
```bash
sudo systemctl status containerd
sudo systemctl restart containerd
```

**Step 2: Set Hostname**
```bash
sudo hostnamectl set-hostname k8s-worker
```

**Step 3: Update /etc/hosts**
```bash
sudo vi /etc/hosts
# Add these lines:
192.168.1.69    k8s-master
127.0.0.1       k8s-worker
```

**Step 4: Clean Previous Config**
```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d /etc/kubernetes/ /var/lib/kubelet/ /var/lib/etcd/
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo systemctl restart containerd
```

**Step 5: Rejoin Cluster**
```bash
sudo kubeadm join 192.168.1.69:6443 --token  \
  --discovery-token-ca-cert-hash sha256:
```

**Step 6: Verify**
```bash
kubectl get nodes
# Both nodes  show "Ready" status
```

---

## 📦 Task 2: Java Application Deployment


### Application Overview

**Application Details:**
- **Name:** Esewa Web Application
- **Technology:** Java Servlet & JSP
- **Build Tool:** Maven 3.6.3
- **Java Version:** JDK 17
- **Application Server:** Apache Tomcat 9.0
- **Source Code:** [GitHub Repository](https://github.com/Tezen96/Esewa-Assignment.git)

---

### Step 1: Build WAR File

#### Install Maven 
```bash
sudo dnf install -y maven

```
#### Verification

<div align="center">
  <img src="Screenshots/Task2/01-mvn-version.png" 
       alt="mvn-version" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 5:verify maven is installed.</i></p>
</div>

---

#### Clone Repository and Build
```bash
# Clone from GitHub
git clone https://github.com/Tezen96/Esewa-Assignment.git
cd Esewa-Assignment
```
<div align="center">
  <img src="Screenshots/Task2/03-git clone project.png" 
       alt="git-clone" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 6:successful cloning of the Git repository.</i></p>
</div>

```bash
# Build WAR file
mvn clean package

# Verify WAR file
ls -lh target/*.war
```
<div align="center">
  <img src="Screenshots/Task2/02-war-file.png" 
       alt="war-file" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 6:successful creation of the WAR file.</i></p>
</div>

---

### Step 2: Containerize Application

#### Dockerfile Explanation

The application uses the following Dockerfile:
```dockerfile
FROM tomcat:9.0-jdk17

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file to ROOT context
COPY target/Esewa-webapp.war /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat server
CMD ["catalina.sh", "run"]
```

**Key Points:**
- **Base Image:** `tomcat:9.0-jdk17` provides Tomcat server with Java 17
- **Clean Webapps:** Removes default Tomcat applications
- **ROOT Context:** Deploys application at root path (`/`)
- **Port 8080:** Standard Tomcat HTTP port
- **Startup Command:** Runs Tomcat in foreground mode

---

### Step 3: Build Docker Image
```bash
# Build Docker image
docker build -t esewa_app:v1 .

# Verify image
docker images | grep esewa
```
---

### Step 4: Push to Docker Hub
```bash
# Login to Docker Hub
docker login

# Tag image
docker tag esewa_app:v1 suresh53/esewa_app:v1

# Push to Docker Hub
docker push suresh53/esewa_app:v1
```

**Docker Hub:** [suresh53/esewa_app:v1](https://hub.docker.com/repository/docker/suresh53/esewa_app/tags)

<div align="center">
  <img src="Screenshots/Task2/04-push- to dockerhub.png" 
       alt="Docker Push Success" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 9: Image pushed to Docker Hub.</i></p>
</div>




---

**Note:** This is a living document. Please refer to the latest version for updates.
