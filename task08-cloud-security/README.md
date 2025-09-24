Task08: Cloud Security (SSH Hardening)
🎯 Objective

Configure and secure SSH access to a Linux EC2 instance.
The goal is to:

Use SSH keys (not passwords) for authentication.

Configure GitHub SCM to use SSH keys.

Disable direct root login.

Create and use a non-root user with sudo.

Demonstrate escalation from non-root to root via sudo.

This ensures access follows best security practices.

🛠️ Steps Performed
1. Generate SSH Key Pair (on local machine)
ssh-keygen -t ed25519 -f ~/.ssh/nebo_sec -C "manuel.herrera.m@gmail.com"


Private key: ~/.ssh/nebo_sec

Public key: ~/.ssh/nebo_sec.pub

2. Configure GitHub for SSH

Added ~/.ssh/nebo_sec.pub to GitHub → Settings → SSH and GPG keys.

Verified connectivity:

ssh -T git@github.com

3. Launch EC2 Instance

Amazon Linux 2023 AMI

Key pair: nebo-sec-key.pem (downloaded from AWS console)

Security group: used default SG (later recommended to restrict to my IP).

4. Connect to Instance
chmod 400 ~/.ssh/nebo-sec-key.pem
ssh -i ~/.ssh/nebo-sec-key.pem ec2-user@<EC2_PUBLIC_IP>

5. Create Non-Root User
sudo adduser manuel
sudo usermod -aG wheel manuel

6. Configure SSH for New User
sudo mkdir -p /home/manuel/.ssh
sudo cp /home/ec2-user/.ssh/authorized_keys /home/manuel/.ssh/
sudo chown -R manuel:manuel /home/manuel/.ssh
sudo chmod 700 /home/manuel/.ssh
sudo chmod 600 /home/manuel/.ssh/authorized_keys


Now login works with:

ssh -i ~/.ssh/nebo-sec-key.pem manuel@<EC2_PUBLIC_IP>

7. Disable Root Login & Passwords

Edited /etc/ssh/sshd_config:

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no


Then restarted SSH:

sudo systemctl restart sshd

8. Test Sudo Access
sudo whoami
# Output: root

✅ Verification

Non-root login works

ssh -i ~/.ssh/nebo-sec-key.pem manuel@<EC2_PUBLIC_IP>


Root login disabled

ssh -i ~/.ssh/nebo-sec-key.pem root@<EC2_PUBLIC_IP>
# Expected: access denied


Sudo escalation works

sudo whoami
# root


GitHub SSH works

ssh -T git@github.com

🔒 Security Recommendations

Restrict SSH SG to your IP only (not 0.0.0.0/0).

Rotate keys periodically.

Store .pem in ~/.ssh/ with chmod 400.

Use ED25519 keys (stronger than RSA).

Remove unused keys from GitHub.

📚 Key Learnings

Difference between root login vs. sudo escalation.

Why key-based authentication is stronger than passwords.

How to integrate GitHub SCM with SSH.

The principle of least privilege: always use non-root.
