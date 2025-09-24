# Task 07 – Configuration Management with Ansible

## Goal

Automate the installation of Docker and the deployment of our NEBo sample application on an Amazon Linux 2023 EC2 instance using Ansible. This task shows how configuration management tools simplify server setup and application deployment.

### Steps
1. Prepare project structure
```
mkdir -p ~/nebo-labs/task07-ansible-config/{inventory,playbooks,app}
cd ~/nebo-labs/task07-ansible-config
```

### Folders:
```
inventory/ → Ansible hosts file.

playbooks/ → Ansible playbooks.

app/ → Dockerfile and app content.
```

2. Create inventory file

```
inventory/hosts.ini:
```
```
[targets]
web1 ansible_host=<EC2_PUBLIC_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/nebo_aws
```

- Replace <EC2_PUBLIC_IP> with the IP of your EC2 instance created with Terraform.

3. Write the Docker app
```
app/Dockerfile:
```
```
FROM amazonlinux:2023
RUN yum -y install nginx && yum clean all
COPY index.html /usr/share/nginx/html/index.html
CMD ["nginx", "-g", "daemon off;"]

```
app/index.html:
```
<!doctype html>

<html>
  <head><title>NEBo Ansible</title></head>
  <body><h1>Hello from Ansible-managed Docker App!</h1></body>
</html>

```

Build and push image:
```
cd app
docker build -t manuelherreram/nebo-ansible-app:1.0 .
docker push manuelherreram/nebo-ansible-app:1.0
```


4. Create the Ansible playbook
```

playbooks/docker_app.yml:
```
```
- name: Install Docker and run my app container (Amazon Linux 2023)
  hosts: targets
  become: true

  tasks:
    - name: Show OS info
      ansible.builtin.debug:
        msg: "Distribution={{ ansible_distribution }} Version={{ ansible_distribution_major_version }}"

    - name: Install Docker engine
      ansible.builtin.dnf:
        name: docker
        state: present

    - name: Enable and start Docker
      ansible.builtin.service:
        name: docker
        state: started
        enabled: true

    - name: Ensure ec2-user is in docker group
      ansible.builtin.user:
        name: ec2-user
        groups: docker
        append: true

    - name: Ensure Python Docker SDK is present
      block:
        - name: Install python3-docker
          ansible.builtin.dnf:
            name: python3-docker
            state: present
      rescue:
        - name: Install pip
          ansible.builtin.dnf:
            name: python3-pip
            state: present
        - name: Install docker SDK via pip
          ansible.builtin.pip:
            name: docker
            executable: pip3
            extra_args: --break-system-packages

    - name: Run app container
      community.docker.docker_container:
        name: nebo_app
        image: "manuelherreram/nebo-ansible-app:1.0"
        state: started
        restart_policy: always
        published_ports:
          - "8080:80"
```
5. Run Ansible

Test connectivity:
```
ansible -i inventory/hosts.ini targets -m ping
```


Run playbook:
```
ansible-playbook -i inventory/hosts.ini playbooks/docker_app.yml
```
6. Verify
```
curl http://<EC2_PUBLIC_IP>:8080
```

Expected output:
```
<!doctype html><html><head><title>NEBo Ansible</title></head>
<body><h1>Hello from Ansible-managed Docker App!</h1></body></html>
```

Re-run the playbook to confirm idempotency (changed=0 ideally).

### Key Learnings

- Ansible allows us to declaratively manage servers (install Docker, configure users, run containers).

- Using inventory files, we define targets for automation.

- Using playbooks, we define repeatable sets of tasks.

- This avoids manual SSH provisioning and makes deployments consistent.
