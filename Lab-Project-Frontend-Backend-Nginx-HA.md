# 🧪 Lab Project – Terraform + Ansible Roles: Nginx Frontend with 3 Backend HTTPD Servers (HA + Auto-Config)

Estimated Duration: 5–6 hours  
Environment: **GitHub Codespace (Linux)** with **Terraform**, **AWS CLI**, **Python**, and **Ansible** available or installable.

Final repo name (on GitHub):  
`CC_<YourName>_<YourRollNumber>/LabProject_FrontendBackend`

---

## 🎯 Learning Outcomes

By completing this lab project, you must demonstrate that you can:

1. Design a small **multi-tier AWS architecture** using **Terraform**.
2. Use **Ansible roles** to separate responsibilities for:
   - Frontend Nginx configuration.
   - Backend HTTPD configuration.
   - (Optional but recommended) Common base configuration.
3. Configure **Nginx** as a reverse proxy / load balancer with:
   - **2 active backend HTTPD servers**.
   - **1 backup backend** (used only on primary failure).
4. Integrate **Terraform and Ansible** so that running:

   ```bash
   terraform apply -auto-approve
   ```

   - Creates all EC2 instances.
   - Automatically runs the relevant Ansible **role-based** playbooks to fully configure the system (no manual `ansible-playbook` after apply).

5. Document and structure your repo in a production-like way (modules, roles, templates).

---

## 📊 Marks Distribution (Total: 100 Marks)

| Section                                      | Marks |
|---------------------------------------------|------:|
| A. Terraform Infrastructure Design          | 25    |
| B. Ansible Roles & Playbook Structure       | 25    |
| C. Nginx Frontend + Backend HTTPD Behavior  | 25    |
| D. Terraform–Ansible Automation & Idempotence | 15  |
| E. Code Quality, Documentation & Git Usage  | 10    |
| **Total**                                   | **100** |

### A. Terraform Infrastructure Design (25 Marks)

- VPC, Subnet, Internet Gateway, Route Table correct (8)
- Security Groups correctly scoped (SSH from your IP, HTTP access) (7)
- 1 frontend + 3 backend EC2 instances provisioned with meaningful tags and variables (10)

### B. Ansible Roles & Playbook Structure (25 Marks)

- Proper use of **roles** (must NOT put everything into a single playbook only) (8)
- Separate roles for **frontend** and **backend** (and optional **common** role) (10)
- Sensible defaults, handlers, templates within roles (7)

### C. Nginx Frontend + Backend HTTPD Behavior (25 Marks)

- All 3 backends running HTTPD and serving distinct content (8)
- Nginx correctly reverse-proxying to backends via upstream (8)
- Upstream configured with **2 primary + 1 backup**, behavior verified (9)

### D. Terraform–Ansible Automation & Idempotence (15 Marks)

- Ansible triggered **automatically** from Terraform (null_resource/local-exec) (8)
- Single `terraform apply -auto-approve` does all provisioning + config (4)
- Re-running apply is **idempotent** (no errors, no unnecessary changes) (3)

### E. Code Quality, Documentation & Git Usage (10 Marks)

- Clear directory structure, useful comments, and variable naming (5)
- README or short explanation in this MD file updated with any assumptions (3)
- Clean Git history (no secrets, no state files, no private keys committed) (2)

---

## 🏗️ Architecture Requirements

### Overall Topology

- **1 frontend EC2 instance**:
  - Runs **Nginx** via Ansible **frontend role**.
  - Acts as **entry point** and **reverse proxy / load balancer**.

- **3 backend EC2 instances**:
  - Run **Apache HTTPD** via Ansible **backend role**.
  - Each serves a simple HTML page identifying itself.

- All instances:
  - In a single **VPC** and **public subnet**.
  - Reachable via **SSH** from your Codespace IP.
  - HTTP accessible (port 80) from the Internet (for testing).

### Nginx Load Balancer Behavior

- Nginx upstream configuration must:
  - Use **2 backends as active** servers.
  - Use **1 backend as backup** (`backup` parameter in upstream server definition).
- When all backends are healthy:
  - Requests to `http://<frontend-public-ip>/` must alternate between the 2 primary backends (round-robin).
- When primary backends are **stopped** (HTTPD service stopped intentionally for test):
  - Requests must be served by the backup backend.

---

## 📁 Required Project Structure (Roles MUST be used)

You must use **roles**. A recommended structure:

```txt
LabProject_FrontendBackend/
  main.tf
  variables.tf
  outputs.tf
  locals.tf
  terraform.tfvars

  modules/
    subnet/
      main.tf
      variables.tf
      outputs.tf
    webserver/          # optional module to create generic EC2 instances
      main.tf
      variables.tf
      outputs.tf

  ansible/
    ansible.cfg
    inventory/
      hosts             # if using static inventory
    playbooks/
      site.yaml         # main entry playbook
    roles/
      common/           # optional: base config (firewall, packages, etc.)
        tasks/main.yml
      frontend/         # REQUIRED: Nginx role
        tasks/main.yml
        handlers/main.yml
        templates/nginx_frontend.conf.j2
      backend/          # REQUIRED: HTTPD role
        tasks/main.yml
        handlers/main.yml
        templates/backend_index.html.j2

  screenshots/          # optional but encouraged
  Lab-Project-Frontend-Backend-Nginx-HA.md
  README.md             # optional summary
  .gitignore
```

You may adjust naming but **roles/fronted** and **roles/backend** (or equivalent) must exist and be used in the playbook.

---

## 🔧 Step-by-Step Requirements

### 1. Terraform – Networking & Common Settings (Architecture Definition)

**Requirements:**

1. **Variables setup** (`variables.tf`):
   - `vpc_cidr_block`, `subnet_cidr_block`, `availability_zone`, `env_prefix`, `instance_type`, `public_key`, `private_key`.

2. **Locals** (`locals.tf`):
   - Determine your public IP:

   ```hcl
   locals {
     my_ip = "${chomp(data.http.my_ip.response_body)}/32"
   }

   data "http" "my_ip" {
     url = "https://icanhazip.com"
   }
   ```

3. **VPC & Subnet**:
   - Either inline in `main.tf` or via `modules/subnet`.
   - VPC must have:
     - CIDR from `var.vpc_cidr_block`.
     - Internet gateway and default route for `0.0.0.0/0`.
   - Subnet must be public (map public IPs on launch or use IGW + route table).

4. **Security Group**:
   - SSH: port 22 from `local.my_ip`.
   - HTTP: port 80 from `0.0.0.0/0`.

### 2. Terraform – Frontend & Backend EC2 Instances

**Requirements:**

1. **Frontend EC2 Instance**:
   - Use `aws_instance` or a `webserver` module.
   - Tag: `Name = "${var.env_prefix}-frontend"`.
   - Attach security group.
   - Use SSH key pair from `var.public_key`.

2. **Backend EC2 Instances**:
   - Use a module or `count = 3`.
   - Tag each as `Name = "${var.env_prefix}-backend-${count.index}"`.
   - Use same security group or a dedicated backend SG (optional).
   - Expose their **private IPs** and **public IPs** via `outputs.tf`.

**Example Outputs:**

```hcl
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ips" {
  value = [for b in aws_instance.backend : b.public_ip]
}

output "backend_private_ips" {
  value = [for b in aws_instance.backend : b.private_ip]
}
```

---

### 3. Ansible – Global Config & Inventory

**Requirements:**

1. `ansible/ansible.cfg` must at least include:

```ini
[defaults]
host_key_checking = False
interpreter_python = /usr/bin/python3
```

2. **Inventory** (`ansible/inventory/hosts`) – choose:
   - **Static** inventory filled manually using `terraform output`, **or**
   - Inline inventory via Terraform `-i 'ip1,ip2,ip3'`.

For easier marking, we recommend a static file:

```ini
[frontend]
<frontend-public-ip>

[backends]
<backend1-public-ip>
<backend2-public-ip>
<backend3-public-ip>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

*(You may generate or update this file manually for the project; automation bonus if done via Terraform template.)*

---

### 4. Ansible Roles – Backend HTTPD Role (backend/)

**Backend Role Requirements (must be in `ansible/roles/backend/`)**:

1. **`tasks/main.yml`** must:

   - Install Apache (`httpd`) and ensure service enabled & started.
   - Deploy a distinct index page per backend using a template.

   Example:

   ```yaml
   - name: Install httpd
     yum:
       name: httpd
       state: present
       update_cache: yes

   - name: Enable and start httpd
     service:
       name: httpd
       state: started
       enabled: true

   - name: Deploy backend index page
     template:
       src: backend_index.html.j2
       dest: /var/www/html/index.html
       owner: apache
       group: apache
       mode: '0644'
   ```

2. **`templates/backend_index.html.j2`** must contain at least:

   ```html
   <!DOCTYPE html>
   <html>
   <head>
     <title>Backend {{ inventory_hostname }}</title>
   </head>
   <body>
     <h1>Backend server: {{ inventory_hostname }}</h1>
     <p>Private IP: {{ ansible_default_ipv4.address | default('unknown') }}</p>
   </body>
   </html>
   ```

3. If you need restart behavior, configure **`handlers/main.yml`** (optional) to restart httpd when template changes.

---

### 5. Ansible Roles – Frontend Nginx Role (frontend/)

**Frontend Role Requirements (must be in `ansible/roles/frontend/`)**:

1. **`tasks/main.yml`** must:

   - Install Nginx.
   - Enable and start Nginx.
   - Deploy Nginx config via template `nginx_frontend.conf.j2`.
   - Use **backend private IPs** in Nginx upstream (not public IPs).

   Example (outline):

   ```yaml
   - name: Install nginx
     yum:
       name: nginx
       state: present
       update_cache: yes

   - name: Enable and start nginx
     service:
       name: nginx
       state: started
       enabled: true

   - name: Deploy nginx frontend config
     template:
       src: nginx_frontend.conf.j2
       dest: /etc/nginx/nginx.conf
     notify: Restart nginx
   ```

2. **`handlers/main.yml`**:

   ```yaml
   - name: Restart nginx
     service:
       name: nginx
       state: restarted
   ```

3. **`templates/nginx_frontend.conf.j2`** must:

   - Define `upstream` with all 3 backends:
     - Two normal servers.
     - One with `backup`.

   Example:

   ```nginx
   user nginx;
   worker_processes auto;
   error_log /var/log/nginx/error.log notice;
   pid /run/nginx.pid;

   events {
       worker_connections 1024;
   }

   http {
       log_format  main  '$remote_addr - $remote_user [$time_local] "$request"'
                         '$status $body_bytes_sent "$http_referer"'
                         '"$http_user_agent" "$http_x_forwarded_for"';

       access_log  /var/log/nginx/access.log  main;

       sendfile            on;
       tcp_nopush          on;
       keepalive_timeout   65;
       types_hash_max_size 4096;

       include             /etc/nginx/mime.types;
       default_type        application/octet-stream;

       upstream backend_servers {
           server {{ backend1_private_ip }}:80;
           server {{ backend2_private_ip }}:80;
           server {{ backup_backend_private_ip }}:80 backup;
       }

       server {
           listen 80;
           server_name _;

           location / {
               proxy_pass http://backend_servers;
               proxy_set_header Host $host;
               proxy_set_header X-Real-IP $remote_addr;
               proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           }
       }
   }
   ```

   You must pass in `backend1_private_ip`, `backend2_private_ip`, and `backup_backend_private_ip` into the role via variables or facts.

---

### 6. Ansible Main Playbook Using Roles

Your main playbook e.g. `ansible/playbooks/site.yaml` **must use roles**. For example:

```yaml
---
- name: Configure backend HTTPD servers
  hosts: backends
  become: true
  roles:
    - backend

- name: Configure frontend Nginx load balancer
  hosts: frontend
  become: true
  vars:
    backend1_private_ip: "<private-ip-backend-1 or from hostvars>"
    backend2_private_ip: "<private-ip-backend-2 or from hostvars>"
    backup_backend_private_ip: "<private-ip-backend-3 or from hostvars>"
  roles:
    - frontend
```

Better is to **dynamically gather** backend IPs from inventory using `hostvars` / groups in the play:

```yaml
  vars:
    backend1_private_ip: "{{ hostvars[groups['backends'][0]].ansible_default_ipv4.address }}"
    backend2_private_ip: "{{ hostvars[groups['backends'][1]].ansible_default_ipv4.address }}"
    backup_backend_private_ip: "{{ hostvars[groups['backends'][2]].ansible_default_ipv4.address }}"
```

> Using roles in this way is **mandatory**. If you do not use roles for frontend and backend, you will lose most or all marks from Section B.

---

### 7. Terraform–Ansible Integration (Automation)

**Requirement:**

- Terraform must **trigger Ansible automatically** after EC2 instances are ready.

**Implementation hint:**

- Add a `null_resource` to `main.tf` that:

  - Has `depends_on` for frontend and backend instances.
  - Has `triggers` that include instance IPs.
  - Uses `local-exec` to run Ansible.

Example:

```hcl
resource "null_resource" "ansible_config" {
  triggers = {
    frontend_ip   = aws_instance.frontend.public_ip
    backend_ips   = join(",", [for b in aws_instance.backend : b.public_ip])
  }

  depends_on = [
    aws_instance.frontend,
    aws_instance.backend
  ]

  provisioner "local-exec" {
    command = <<-EOT
      cd ansible
      ansible-playbook \
        -i ../generated_hosts.ini \
        playbooks/site.yaml
    EOT
  }
}
```

You can either:

- Generate `generated_hosts.ini` via a Terraform template file (`templatefile` function + `local_file` resource), or
- Directly use inline inventory; e.g.,

```hcl
provisioner "local-exec" {
  command = <<-EOT
    cd ansible
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
      -i "${self.triggers.frontend_ip}," \
      playbooks/site.yaml
  EOT
}
```

*(But you need all 4 hosts; so static inventory + playbook is usually easier.)*

**Key evaluation criteria:**

- After `terraform apply -auto-approve`, **do not** manually call `ansible-playbook`.  
- All configuration must be applied already.

---

## ✅ Verification Checklist (What the Instructor Will Check)

1. **Repo Structure**:
   - Terraform files present, no `.tfstate` or `.terraform/` committed.
   - `ansible/roles/frontend` and `ansible/roles/backend` exist and are used from playbook.

2. **Terraform Plan/Apply**:
   - `terraform init` works.
   - `terraform apply -auto-approve` successfully:
     - Creates a VPC, subnet, security group(s).
     - Creates 1 frontend and 3 backend instances.
     - Runs `null_resource` which runs Ansible.

3. **Ansible Roles**:
   - `backend` role installs httpd and sets per-backend index page.
   - `frontend` role installs nginx and sets upstream with 2 primary + 1 backup.

4. **Runtime Behavior**:
   - `http://<backend-N-public-ip>/` shows distinct backend pages.
   - `http://<frontend-public-ip>/` alternates between backend 1 and backend 2 responses.
   - When backend 1 and 2 `httpd` services are stopped:
     - `http://<frontend-public-ip>/` returns backup backend page.

5. **Automation**:
   - Destroy + re-apply (optionally done by instructor):
     - `terraform destroy -auto-approve`
     - `terraform apply -auto-approve`
   - Ends with correct configuration **without** any manual Ansible command.

---

## 🚫 What Will Lose Marks

- Hard-coding everything into a single Ansible playbook with no roles.
- Manually running `ansible-playbook` after Terraform apply (no automation).
- Nginx not configured as 2 primary + 1 backup upstream.
- Backends not returning distinct content (cannot tell which backend served the response).
- Committing:
  - AWS credentials.
  - Private SSH keys.
  - Terraform state files.

---

## 📦 Submission Instructions

1. Push all code to GitHub repo:

   `CC_<YourName>_<YourRollNumber>/LabProject_FrontendBackend`

2. Include:

   - Terraform code (`*.tf`, modules).
   - Ansible code (`ansible/` with roles, playbooks, templates).
   - This lab description: `Lab-Project-Frontend-Backend-Nginx-HA.md`.
   - Optional screenshots inside `screenshots/`.

3. Ensure `.gitignore` includes at least:

   ```gitignore
   .terraform/*
   *.tfstate
   *.tfstate.*
   *.tfvars
   *.pem
   .terraform.lock.hcl
   ```

4. Add a short `README.md` or update this MD file:
   - How to run:
     ```bash
     terraform init
     terraform apply -auto-approve
     ```
   - Any assumptions (e.g., region used, instance type, AMI ID).

---

## 💡 Hints

- Start by making Ansible work **manually** (without Terraform integration).
- Once roles and behavior are correct:
  - Wire up Terraform `null_resource` to call Ansible.
- Use tags and hostnames to debug traffic distribution.
- Check Nginx logs (`/var/log/nginx/access.log`) to see which backend served each request.

Good luck! This project simulates a realistic deployment workflow and emphasizes **clean separation of concerns** using **Terraform for infrastructure** and **Ansible roles for configuration**, all glued together with **fully automated provisioning**.