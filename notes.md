# Notes — Verification, Troubleshooting & Practical Tips

Quick reference of commands and checks for the Wazuh + Apache + Attacker lab. Copy/paste the commands and replace placeholder values (`<MANAGER_IP>`, `<WEB_IP>`, `<ATTACKER_IP>`).

---

## Verification Commands

### Apache (Web VM)
```bash
# Check apache service status
sudo systemctl status apache2
```
# Confirm HTTP page returns content (replace <WEB_IP>)
curl http://<WEB_IP>
Wazuh Agent (Web VM)
```bash
Copy code
# Check agent service status
sudo systemctl status wazuh-agent

# Restart agent after config changes
sudo systemctl restart wazuh-agent

# Tail recent agent log entries
sudo tail -n 100 /var/ossec/logs/ossec.log
```
Wazuh Manager (Manager VM)
```bash
Copy code
# Check manager service
sudo systemctl status wazuh-manager

# Restart manager if needed
sudo systemctl restart wazuh-manager

# Show recent alerts
sudo tail -n 200 /var/ossec/logs/alerts/alerts.log

# Show manager log
sudo tail -n 100 /var/ossec/logs/ossec.log
```
Wazuh Dashboard
URL: https://<MANAGER_IP>

Username: admin

Password: printed at install time or inside the installer bundle:

```bash
Copy code
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```
Common Problems & Remedies
Agent does not appear in Manager
Verify agent ↔ manager network connectivity (firewall, security groups, etc).

Inspect logs on both sides:

```bash
Copy code
# On agent
sudo tail -n 100 /var/ossec/logs/ossec.log

# On manager
sudo tail -n 100 /var/ossec/logs/ossec.log
```
Active Response not blocking the attacker
```bash
Copy code
# Look for custom rule hits in alerts
sudo grep "100100" /var/ossec/logs/alerts/alerts.log || true

# Confirm CDB file exists
ls -l /var/ossec/etc/lists/blacklist-alienvault

# Ensure correct ownership
sudo chown wazuh:wazuh /var/ossec/etc/lists/blacklist-alienvault || true

# List available active-response scripts
ls -l /var/ossec/active-response/bin/
Self-signed TLS warning in browser
```
This is normal for a lab install. Accept the exception or replace the certificate with one issued by a trusted CA.

Prevent accidental upgrades in a lab
```bash
Copy code
# Debian/Ubuntu
sudo sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list 2>/dev/null || true

# RHEL/CentOS
sudo sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo 2>/dev/null || true
```
Running this lab on the cloud (if local resources are constrained)
If your machine can't host three VMs reliably, consider a cloud provider (Google Cloud, AWS, Azure). Benefits:

Offload compute and memory usage.

Use snapshots and machine images for quick rollback.

Public IPs and easier network/firewall configuration for testing.

Suggested minimal sizes for a lab:

Manager: 4 vCPU / 8 GiB RAM

Web VM: 1–2 vCPU / 2–4 GiB RAM

Attacker VM: 1 vCPU / 1–2 GiB RAM

Practical tips:

Use snapshots or images to save a working state before making big changes.

Limit open ports via security groups/VPC rules to the bare minimum needed.

Network interface down (ens33 shows no IP after reboot)
If ip address shows the interface but no inet address, follow these recovery steps.

```bash
Copy code
# Show link state and all addresses
ip link show ens33
ip addr show
bash
Copy code
# Bring interface up
sudo ip link set ens33 up
bash
Copy code
# Request DHCP lease (verbose)
sudo dhclient -v ens33
bash
Copy code
# Verify IPv4 address assigned
ip -4 addr show dev ens33
```
Alternative (NetworkManager):

```bash
Copy code
sudo nmcli device set ens33 managed yes
sudo nmcli device connect ens33
nmcli -g IP4.ADDRESS device show ens33
```
Alternative (netplan on Ubuntu):

```bash
Copy code
sudo netplan apply
ip addr show ens33
```
If still failing, inspect logs:

```bash
Copy code
sudo journalctl -u NetworkManager -n 200 --no-pager || true
sudo journalctl -u systemd-networkd -n 200 --no-pager || true
sudo tail -n 200 /var/log/syslog
```
Why this happens: after a reboot the NIC may be administratively down or the DHCP client didn't renew — bringing the link up and re-requesting a lease resolves this in most cases.

Useful log & file locations
Manager alerts: /var/ossec/logs/alerts/alerts.log

Manager log: /var/ossec/logs/ossec.log

Agent log: /var/ossec/logs/ossec.log

Apache access log: /var/log/apache2/access.log

Apache error log: /var/log/apache2/error.log

Active response scripts: /var/ossec/active-response/bin/

Lists (CDBs): /var/ossec/etc/lists/

Quick troubleshooting checklist
 Apache landing page reachable from Attacker VM

 Wazuh agent enrolled and visible in Manager UI

 blacklist-alienvault exists and is owned by wazuh:wazuh

 Rule 100100 appears in alerts after attacker traffic

 Active Response blocks repeated attacker requests

 If no IP after reboot: ip link set ens33 up → dhclient ens33 (or nmcli / netplan apply) and re-check
