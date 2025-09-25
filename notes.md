# Notes — Verification, Troubleshooting & Practical Tips

Quick reference of commands and checks for the Wazuh + Apache + Attacker lab. Copy/paste the commands and replace placeholder values (`<MANAGER_IP>`, `<WEB_IP>`, `<ATTACKER_IP>`).

---

## Verification Commands

### Apache (Web VM)

# Check apache service status
```bash
sudo systemctl status apache2
```
# Confirm HTTP page returns content (replace <WEB_IP>)
curl http://<WEB_IP>
Wazuh Agent (Web VM)

# Check agent service status
```bash
sudo systemctl status wazuh-agent
```
# Restart agent after config changes
```bash
sudo systemctl restart wazuh-agent
```
# Tail recent agent log entries
```bash
sudo tail -n 100 /var/ossec/logs/ossec.log
```
Wazuh Manager (Manager VM)

# Check manager service
```bash
sudo systemctl status wazuh-manager
```
# Restart manager if needed
```bash
sudo systemctl restart wazuh-manager
```
# Show recent alerts
```bash
sudo tail -n 200 /var/ossec/logs/alerts/alerts.log
```
# Show manager log
```bash
sudo tail -n 100 /var/ossec/logs/ossec.log
```
Wazuh Dashboard
URL: https://<MANAGER_IP>

Username: admin

Password: printed at install time or inside the installer bundle:

```bash
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
```
Common Problems & Remedies
Agent does not appear in Manager
Verify agent ↔ manager network connectivity (firewall, security groups, etc).

Inspect logs on both sides:


# On agent
```bash
sudo tail -n 100 /var/ossec/logs/ossec.log
```
# On manager
```bash
sudo tail -n 100 /var/ossec/logs/ossec.log
```
Active Response not blocking the attacker

# Look for custom rule hits in alerts
```bash
sudo grep "100100" /var/ossec/logs/alerts/alerts.log || true
```
# Confirm CDB file exists
```bash
ls -l /var/ossec/etc/lists/blacklist-alienvault
```
# Ensure correct ownership
```bash
sudo chown wazuh:wazuh /var/ossec/etc/lists/blacklist-alienvault || true
``` 
# List available active-response scripts
```bash
ls -l /var/ossec/active-response/bin/
```
Self-signed TLS warning in browser
This is normal for a lab install. Accept the exception or replace the certificate with one issued by a trusted CA.

Prevent accidental upgrades in a lab

# Debian/Ubuntu
```bash
sudo sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list 2>/dev/null || true
```
# RHEL/CentOS
```bash
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

# Show link state and all addresses
```bash
ip link show ens33
ip addr show
bash
```
# Bring interface up
```bash
sudo ip link set ens33 up
bash
```
# Request DHCP lease (verbose)
```bash
sudo dhclient -v ens33
bash
```
# Verify IPv4 address assigned
```bash
ip -4 addr show dev ens33
```
Alternative (NetworkManager):

```bash
sudo nmcli device set ens33 managed yes
sudo nmcli device connect ens33
nmcli -g IP4.ADDRESS device show ens33
```
Alternative (netplan on Ubuntu):

```bash
sudo netplan apply
ip addr show ens33
```
If still failing, inspect logs:

```bash
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
