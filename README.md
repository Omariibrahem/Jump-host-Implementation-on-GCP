# Secure Access to Private Resources on GCP (Jump Host/Bastion)

<p align="center">
  <img src="/JumpHost.gif" width="600" alt="Demo Preview">
</p>
---

## Overview

This README describes how to build a **secure jump host (bastion)** on Google Cloud Platform to access **private VMs without public IPs**. It covers VPC design, firewall least-privilege, SSH hardening (key-based auth, disable passwords), and using Google’s IAP egress range so the **Console/CLI** can still SSH to private instances.

**Conventions used**

* **Project**: `konecta-testing`
* **Region/Zone**: `us-central1` / `us-central1-c`
* **VPC**: `secure-vpc`
* **Subnets**: `public-subnet` (10.0.1.0/24), `private-subnet` (10.0.2.0/24)
* **Jump host (bastion)**: `bastion-host` (public IP **35.192.57.118**, tag `bastion`)
* **Private VM**: `private-vm` (internal IP e.g. **10.0.2.2**, tag `private`)

---

## Architecture

```
Internet
   │
   │  SSH (tcp/22) limited by firewall
   ▼
[ bastion-host ]  (public-subnet, has external IP 35.192.57.118)
   │  internal SSH only
   ▼
[ private-vm ]    (private-subnet, NO external IP, 10.0.2.2)
```

Also supported: Google Console/`gcloud` SSH via **IAP egress** range `35.235.240.0/20` to `private-vm`.

---

## Prerequisites

* `gcloud` SDK authenticated to `konecta-testing`
* IAM permissions to create networking and compute resources

---
## You can use the terraform file or you can implemnt this architecture using this steps
## 1) Network & Subnets

```bash
# VPC
gcloud compute networks create secure-vpc \
  --subnet-mode=custom

# Subnets
gcloud compute networks subnets create public-subnet \
  --network=secure-vpc --region=us-central1 --range=10.0.1.0/24

gcloud compute networks subnets create private-subnet \
  --network=secure-vpc --region=us-central1 --range=10.0.2.0/24
```

---

## 2) Firewall (Least-Privilege)

```bash
# SSH to bastion from anywhere (demo). In prod, restrict to your office IPs.
gcloud compute firewall-rules create allow-ssh-bastion \
  --network=secure-vpc --allow=tcp:22 \
  --source-ranges=0.0.0.0/0 --target-tags=bastion

# Internal traffic within VPC (adjust to your needs)
gcloud compute firewall-rules create allow-internal \
  --network=secure-vpc --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/16

# Allow SSH to private-vm from bastion only (by tag)
gcloud compute firewall-rules create allow-ssh-private-bastion \
  --network=secure-vpc --allow=tcp:22 \
  --source-tags=bastion --target-tags=private

# Allow SSH to private-vm from Google IAP (Console/CLI)
# IAP egress range: 35.235.240.0/20
gcloud compute firewall-rules create allow-ssh-private-iap \
  --network=secure-vpc --allow=tcp:22 \
  --source-ranges=35.235.240.0/20 --target-tags=private
```

---

## 3) Compute Instances

```bash
# Jump host (bastion)
gcloud compute instances create bastion-host \
  --zone=us-central1-c --machine-type=e2-micro \
  --subnet=public-subnet --tags=bastion \
  --image-family=debian-12 --image-project=debian-cloud \
  --boot-disk-size=10GB --boot-disk-type=pd-balanced

# Private VM (no external IP)
gcloud compute instances create private-vm \
  --zone=us-central1-c --machine-type=e2-micro \
  --subnet=private-subnet --no-address --tags=private \
  --image-family=debian-12 --image-project=debian-cloud \
  --boot-disk-size=10GB --boot-disk-type=pd-balanced
```

> If your bastion already exists with public IP **35.192.57.118**, keep using it; just ensure it has tag `bastion`.

---

## 4) Secure SSH (Hardening)

On **both** VMs (especially the bastion):

```bash
# Install OpenSSH if needed
sudo apt-get update && sudo apt-get install -y openssh-server

# Disable password auth + root login
sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# (Optional) Basic rate limiting
sudo apt-get install -y fail2ban
```

Generate a keypair on your **local machine** and add the **public key** to the bastion (`~/.ssh/authorized_keys`). Then generate or copy a keypair on the bastion and append its **public key** to the private VM’s `~/.ssh/authorized_keys` so bastion → private works via keys only.

**Example (from bastion to private):**

```bash
# On bastion
[ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub | ssh <user>@10.0.2.2 \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

---

## 5) Access Paths

**A) From Internet → Bastion → Private**

```bash
# From your workstation
ssh -i ~/.ssh/gcp_bastion_key <user>@35.192.57.118
# From bastion to private
ssh <user>@10.0.2.2
```

**B) From Console/CLI via IAP → Private**

```bash
gcloud compute ssh private-vm --zone=us-central1-c
```

(Works because the firewall allows `35.235.240.0/20` on tcp/22 to tag `private`.)

**C) One-liner ProxyJump from workstation**

```bash
ssh -J <user>@35.192.57.118 <user>@10.0.2.2
```

---

## 6) Troubleshooting

* **IAP 4003: failed to connect to backend** → ensure firewall allows `35.235.240.0/20` to tcp/22 on the private VM’s tag.
* **Permission denied (publickey)** → verify the right public keys are in `~/.ssh/authorized_keys` and permissions are `700 ~/.ssh`, `600 authorized_keys`.
* **Timeout from bastion to private** → confirm `allow-ssh-private-bastion` rule exists and both VMs have correct tags.

---

## 7) Cleanup

```bash
# Instances
gcloud compute instances delete bastion-host private-vm --zone=us-central1-c --quiet

# Firewall rules
gcloud compute firewall-rules delete \
  allow-ssh-bastion allow-internal \
  allow-ssh-private-bastion allow-ssh-private-iap --quiet

# Subnets & VPC
gcloud compute networks subnets delete public-subnet --region=us-central1 --quiet
gcloud compute networks subnets delete private-subnet --region=us-central1 --quiet
gcloud compute networks delete secure-vpc --quiet
```

---

## Why this is secure

* Only the **bastion** has a public IP; private workloads stay isolated.
* **Firewall rules** enforce least-privilege (bastion-only SSH to private, IAP-only for Console access).
* **SSH keys** and **disabled passwords** mitigate brute-force and credential stuffing.

---

## Notes

* For production, restrict inbound SSH to known office/VPN IP ranges instead of `0.0.0.0/0`.
* Consider enabling OS Login & 2FA, audit logging, and rotating keys regularly.
