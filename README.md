# AWS High-Availability Web Infrastructure
### Terraform + Ansible Roles Project

**Student Name:** Ushna Saad  
**Roll Number:** 2023-BSE-069

This project demonstrates a fully automated deployment of a multi-tier web architecture on AWS. It uses **Terraform** for infrastructure provisioning and **Ansible Roles** for software configuration, ensuring a clean separation of concerns.

## 🏗️ Architecture Overview
* **1 Frontend Server:** Runs Nginx as a reverse proxy/load balancer.
* **3 Backend Servers:** Run Apache (httpd) serving unique content.
* **High Availability:** Nginx is configured with an upstream group consisting of 2 active primary backends and 1 backup backend.

## 🚀 How to Deploy
1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Apply Infrastructure:**
    ```bash
    terraform apply -auto-approve
    ```
    *Terraform will automatically trigger the Ansible playbooks via a `null_resource` once the instances are ready.*

## 🛠️ Components
### Terraform (Infrastructure)
* **VPC & Networking:** Custom VPC, Public Subnet, and Internet Gateway.
* **Security:** Security groups locked down to allow SSH only from the developer's dynamic IP.
* **Compute:** 4 EC2 instances (Amazon Linux 2023).

### Ansible (Configuration)
* **`role: backend`:** Installs httpd and deploys a custom index page displaying the instance's Private IP.
* **`role: frontend`:** Installs Nginx and configures a dynamic load-balancing template.

## ✅ Verification & HA Logic
The system was verified using the following steps:
1.  **Round-Robin:** Accessing the Frontend IP alternates between Backend 1 and Backend 2.
2.  **Failover Test:** * Stopped the `httpd` service on both primary backends.
    * Verified that Nginx automatically routed traffic to the **Backup Backend (Backend 3)**.
    * Command used: `ansible backends[0:1] -m service -a "name=httpd state=stopped" --become`

