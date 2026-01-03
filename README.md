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
  <p><i>Figure 01:verify maven is installed.</i></p>
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
  <p><i>Figure 02:successful cloning of the Git repository.</i></p>
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
  <p><i>Figure 03:successful creation of the WAR file.</i></p>
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
  <p><i>Figure 04: Image pushed to Docker Hub.</i></p>
</div>

---

### Step 5: Create Kubernetes Deployment

**File:** `k8s-manifests/deployment.yaml`

**Description:**
- Kubernetes Deployment manifest for the Java application
- Creates 1 replica pod running the Tomcat container
- Container listens on port 8080
- Uses `imagePullPolicy: Always` to ensure latest image is pulled
- Labels: `app: esewa` for service selector matching

**Key Configuration:**
- **Image:** `docker.io/suresh53/esewa_app:v1`
- **Container Port:** 8080
- **Replicas:** 1
- **Namespace:** default

**Deploy to Kubernetes:**
```bash
kubectl apply -f k8s-manifests/deployment.yaml
```

**Verify Deployment:**
```bash
# Check deployment & pods status
kubectl get deployment 
kubectl get pods

```
**Output:**
<div align="center">
  <img src="Screenshots/Task2/05-deployment-pod.png" 
       alt="deployment and pods" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 05: Deployment and pods status showing Ready state</i></p>
</div>

---
#### Verify Application Logs

```bash
kubectl logs esewa-app-66b9c6b458-dt6ck --tail=20
```

**Output:**

<div align="center">
  <img src="Screenshots/Task2/06-pods-logs.png" 
       alt="Pod logs" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 06: Tomcat started successfully.</i></p>
</div>

---

### Summary

✅ **WAR File:** Built using Maven  
✅ **Docker Image:** Created and pushed to Docker Hub  
✅ **Kubernetes Deployment:** Pod running successfully  
✅ **Application Status:** Tomcat started, ready to serve requests  

---
## ✅ Task 3: Service Exposure

### NodePort Service

**File:** k8s-manifests/service-nodeport.yaml


**Key Configuration:**
- **Service Type:** NodePort (exposes service on static port on each node)
- **Selector:** `app: esewa` (matches deployment label)
- **Port:** 8080 (internal service port)
- **TargetPort:** 8080 (container port)
- **NodePort:** 30080 (external access port)

**Deploy Command:**
```bash
kubectl apply -f service-nodeport.yaml
```

**Verification:**
<div align="center">
  <img src="Screenshots/Task3/01-get-svc.png" 
       alt="service-info" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 01: displaying the list of services in the cluster</i></p>
</div>

---
<div align="center">
  <img src="Screenshots/Task3/04-nodes-details.png" 
       alt="service-info" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 02: Cluster nodes information showing master and worker nodes with their internal IP addresses</i></p>
</div>


---

**NodePort Access URLs:**
- Master node: http://192.168.1.69:30080
- Worker node: http://192.168.1.68:30080


<div align="center">
  <img src="Screenshots/Task3/1.68-nodeport.png" 
       alt="NodePort access via worker node" 
       width="45%" 
       style="display: inline-block; border: 1px solid #ddd; border-radius: 4px; padding: 5px; margin-right: 10px; vertical-align: top;">
  <img src="Screenshots/Task3/1.69-nodeport.png" 
       alt="NodePort access via master node" 
       width="45%" 
       style="display: inline-block; border: 1px solid #ddd; border-radius: 4px; padding: 5px; vertical-align: top;">
  <p><i>Figure 02: Successful external access to Java application via NodePort through master and worker nodes.</i></p>
</div>
---

### Ingress Configuration

#### Step 1: Install Ingress Controller

**Install NGINX Ingress Controller:**
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml
```

**Verify Installation:**



<div align="center">
  <img src="Screenshots/Task3/A.png" 
       alt="Ingress Controller" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 02: Successfully running Ingress NGINX controller pods.</i></p>
</div>

---
<div align="center">
  <img src="Screenshots/Task3/B.png" 
       alt="Ingress Controller" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 02: List of services in the ingress-nginx namespace.</i></p>
</div>

---

#### Step 2: Create Ingress Resource

**File:** k8s-manifests/ingress.yaml`


**Key Configuration:**
- **Host:** `bksuresh.com.np` (domain name)
- **Path:** `/` (root path)
- **Backend Service:** `esewa-service-nodeport` on port 8080
- **Ingress Class:** nginx

**Deploy Command:**
```bash
kubectl apply -f ingress.yaml
```

**Verification:**
```bash
$ kubectl get ingress

```
<div align="center">
  <img src="Screenshots/Task3/C.png" 
       alt="get ingress" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 06: List of Ingress resources in the cluster</i></p>
</div>

```bash
$ kubectl describe ingress esewa-ingress

```

<div align="center">
  <img src="Screenshots/Task3/D.png" 
       alt="describe ingress" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 07: Verification of esewa-ingress configuration and routing rules</i></p>
</div>

---

#### Step 3: Configure DNS/Hosts File

**For Testing (Local Access):**

Add the following entry to hosts file:


**Windows:**
```cmd
# Run Notepad as Administrator
# Open: C:\Windows\System32\drivers\etc\hosts

# Added this line:
192.168.1.68 bksuresh.com.np
```

<div align="center">
  <img src="Screenshots/Task3/host.png" 
       alt="Hosts File Configuration" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 04: Hosts file configured for domain resolution.</i></p>
</div>

---

### Traffic Flow Explanation

**Request Flow:**

1. **User Request:** Browser accesses `http://bksuresh.com.np:32690`
2. **DNS Resolution:** Domain `bksuresh.com.np` resolves to `192.168.1.68` (worker node IP)
3. **NodePort:** Request hits worker node on port `32690` (NGINX Ingress Controller NodePort)
4. **Ingress Controller:** NGINX controller receives the request and checks routing rules
5. **Host Matching:** Ingress rules match `Host: bksuresh.com.np`
6. **Path Routing:** Path `/` matches ingress path rule
7. **Backend Service:** Routes to `esewa-service-nodeport` on port `8080`
8. **Service:** Service forwards to pod IP `10.244.1.5:8080`
9. **Pod Response:** Tomcat container in the pod serves the application
10. **Return Path:** Response flows back through the same path to user

**Traffic Flow Diagram:**
```

User Browser
     │
     │ http://bksuresh.com.np:32690
     ▼
DNS Resolution (/etc/hosts file)
     │
     │ 192.168.1.68:32690
     ▼
Worker Node (192.168.1.68)
     │
     │ NodePort 32690 (HTTP)
     ▼
NGINX Ingress Controller
     │
     │ Host: bksuresh.com.np
     ▼
Ingress Rules Evaluation
     │
     │ Path: / → Backend Service
     ▼
esewa-service-nodeport (ClusterIP)
     │
     │ Service IP: 10.108.101.85:8080
     ▼
eSewa Pod (10.244.1.5:8080)
     │
     │ Container: Tomcat
     ▼
Application Response
     │
     │ HTML/HTTP Response
     ▼
User Browser

```

---

### Access Methods

**Method 1: NodePort (Direct Access)**
```
http://192.168.1.68:30080
http://192.168.1.69:30080
```
```
--> Already Access showing in fig(3)
```
**Method 2: Ingress (Domain-based Access)**
```
http://bksuresh.com.np:32690
```


<div align="center">
  <img src="Screenshots/Task3/ingress-domain(1).png" 
       alt="welcome-page" 
       width="45%" 
       style="display: inline-block; border: 1px solid #ddd; border-radius: 4px; padding: 5px; margin-right: 10px; vertical-align: top;">
  <img src="Screenshots/Task3/ingress-domain(2).png" 
       alt="information" 
       width="45%" 
       style="display: inline-block; border: 1px solid #ddd; border-radius: 4px; padding: 5px; vertical-align: top;">
  <p><i>Figure 09:Application accessible via Ingress using domain name
 </i></p>
</div>

---

### Summary

✅ **NodePort Service:** Exposed on port 30080 across all nodes  
✅ **Ingress Controller:** NGINX installed and running  
✅ **Ingress Resource:** Domain-based routing configured  
✅ **DNS Configuration:** Hosts file updated for local testing  
✅ **Application Access:** Available via both NodePort and Ingress  

**Key Benefits of Ingress:**
- Single entry point for multiple services
- Host and path-based routing
- SSL/TLS termination support (future enhancement)
- Load balancing across multiple pods
- Centralized configuration management

---
[🔝 Back to Top](#table-of-contents)


## 🛠️ Troubleshooting - Task 3


### Issue 1: Ingress Controller Not Working

**Symptom:**
```bash
kubectl get ingress
NAME            CLASS   HOSTS             ADDRESS   PORTS   AGE
esewa-ingress   nginx   bksuresh.com.np   <none>    80      5m
```

**Root Cause:**
- Ingress Controller pods not running
- Missing IngressClass

**Solution:**
```bash
# Check Ingress Controller pods
kubectl get pods -n ingress-nginx

# If not running, reinstall
kubectl delete namespace ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Wait for pods to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

---

### Issue 2: Domain Not Resolving (Ingress)

**Symptom:**
```bash
curl: (6) Could not resolve host: bksuresh.com.np
```

**Root Cause:**
- hosts file not configured
- Wrong IP address in hosts file

**Solution:**

**Windows:**
```cmd
# Edit as Administrator
notepad C:\Windows\System32\drivers\etc\hosts

# Add line:
192.168.1.68  bksuresh.com.np
```


---

### Issue 2: Ingress Returns 404 Error

**Symptom:**
```bash
curl http://bksuresh.com.np:32690
<html>
<head><title>404 Not Found</title></head>
</html>
```

**Root Cause:**
- Backend service name mismatch
- Wrong service port in Ingress

**Solution:**
```bash
# Verify backend service exists
kubectl get svc esewa-service-nodeport

# Check Ingress configuration
kubectl describe ingress esewa-ingress

# Ensure service name and port match
# In ingress.yaml:
backend:
  service:
    name: esewa-service-nodeport  # Must match actual service name
    port:
      number: 8080                # Must match service port
```

---

[🔝 Back to Top](#table-of-contents)

## ✅ Task 4: ELK Stack Setup

### 4.1 Overview

The ELK Stack (Elasticsearch, Logstash, Kibana) is deployed for centralized logging and monitoring of the Kubernetes cluster and applications.

**Architecture:**

**Note:** Logstash was omitted due to limited system resources. Filebeat sends logs directly to Elasticsearch..
```
┌──────────────┐
│  Filebeat    │ (DaemonSet - runs on all nodes)
│  (Collector) │
└──────┬───────┘
       │ Sends container logs
       ▼
┌──────────────┐
│Elasticsearch │ (Storage & Indexing)
│    :9200     │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Kibana     │ (Visualization Dashboard)
│    :5601     │
└──────────────┘
```

### 4.2 Component Specifications

| Component | Version | Purpose | Resources | Service Type |
|-----------|---------|---------|-----------|--------------|
| Elasticsearch | 8.11.0 | Log storage & indexing | 500Mi RAM, 300m CPU | ClusterIP (9200) |
| Kibana | 8.11.0| Log visualization | 512Mi RAM, 300m CPU | NodePort (30561) |
| Filebeat | 8.11.0 | Log collection | 100Mi RAM, 50m CPU | DaemonSet |

### 4.3 Namespace Setup

**Create logging namespace:**

**File:** ELK/
01-namespace.yaml

```
kubectl apply -f 01-namespace.yaml
kubectl get namespaces
```

<div align="center">
  <img src="Screenshots/Task4/01-A.png" 
       alt="Logging namespace creation" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 01: Logging namespace created for ELK Stack components.</i></p>
</div>

### 4.4 Elasticsearch Deployment

**File:** `ELK/02-elasticsearch-master.yaml`

**Key configurations:**
- **Node Selector:** Runs on master node (`kubernetes.io/hostname: k8s-master`)
- **Single-node mode:** `discovery.type=single-node`
- **Security disabled:** `xpack.security.enabled=false` (for development)
- **Storage:** Uses hostPath volume `/mnt/elasticsearch-data`
- **Service Port:** 9200 (ClusterIP)


**Deploy Elasticsearch:**
```bash
kubectl apply -f 02-elasticsearch-master.yaml
kubectl get pods -n logging

```

<div align="center">
  <img src="Screenshots/Task4/ELK-running.png" 
       alt="Elasticsearch deployment" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 02: Elasticsearch pod running on master node.</i></p>
</div>

### 4.5 Kibana Deployment

**File:** `ELK/03-kibana.yaml`

**Key configurations:**
- **Service Type:** NodePort (30561)
- **Elasticsearch Connection:** `http://elasticsearch:9200`
- **Access URL:** http://192.168.1.69:30561


**Deploy Kibana:**
```bash
kubectl apply -f 03-kibana.yaml
kubectl get svc -n logging
```
<div align="center">
  <img src="Screenshots/Task4/svc.png" 
       alt="svc-logging" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 03: services running in the logging namespace,.</i></p>
</div>

**Access Kibana Dashboard:**
- URL: http://192.168.1.69:30561

<div align="center">
  <img src="Screenshots/Task4/kibana-dashboard.png" 
       alt="Kibana dashboard access" 
       width="700" 
       style="border: 1px solid #ddd; border-radius: 4px; padding: 5px;">
  <p><i>Figure 04: Kibana dashboard accessible via NodePort on master node.</i></p>
</div>



