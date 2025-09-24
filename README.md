# NEBo Labs — Cloud DevOps PeeX

This repository contains my step-by-step labs for the **NEBo DevOps PeeX**.  
Each folder represents a separate task from PeeX.  

---

## Structure

- **task01-copy-tree** — Python script to copy directory trees (no loops/ifs).
- **task02-ec2** — Provision an EC2 instance with Terraform + user-data bootstrap (nginx).
- **task03-parent-image** — Build and push a parent Docker image.
- **task04-vpc** — Create a custom VPC with public subnet and nginx instance.
- **task05-private-compute-bastion** — Bastion host with Linux and Windows private instances.
- **task06-observability-cloudwatch** — Install and configure CloudWatch Agent for metrics/logs.
- **task07-ansible-config** — Use Ansible to configure Docker and deploy a containerized app.
- **task08-cloud-security** — Configure secure SSH access and non-root users.
- **task09-cicd** — Jenkins pipeline with Docker agent, build and test stages.

Each folder includes:
- **Terraform / Ansible / scripts** required for the task.
- **README.md** with usage instructions, outputs, and acceptance criteria.

---

## Goals

- Practice **Infrastructure as Code (IaC)** with Terraform and Ansible.  
- Learn **AWS basics** (EC2, VPC, Security Groups, CloudWatch).  
- Build and push **Docker images**.  
- Configure **secure SSH access** and non-root users.  
- Deploy and test a **Jenkins CI/CD pipeline**.  

---
