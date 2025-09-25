# Notes — Verification, Troubleshooting & Practical Tips

This file contains quick verification commands, common troubleshooting steps, and practical tips for running the Wazuh + Apache + Attacker PoC lab. Commands are formatted for copy/paste.

---

## 🔎 Verification Commands

### Apache (Web VM)
```bash
# Check Apache status
sudo systemctl status apache2

# Test landing page (replace <WEB_IP>)
curl http://<WEB_IP>
Wazuh Agent (Web VM)
bash
Copy code
# Service status
sudo systemctl status wazuh-agent

# Restart the agent if config changed
sudo systemctl restart wazuh-agent

# Tail recent agent logs
sudo tail -n 100 /var/ossec/logs/ossec.log
Wazuh Manager (Manager VM)
bash
Copy code
# Service status
sudo systemctl status wazuh-manager

# Restart manager
sudo systemctl restart wazuh-manager

# View recent alerts
sudo tail -n 200 /var/ossec/logs/alerts/alerts.log

# View manager logs
sudo tail -n 100 /var/ossec/logs/ossec.log
Wazuh Dashboard
URL: https://<MANAGER_IP>

Username: admin

Password: printed at end of installer or in wazuh-install-files.tar:

bash
Copy code
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt
⚠️ Common Issues & Fixes
1) Agent not visible in Manager
Confirm network connectivity (agent ↔ manager).

Check agent and manager logs for errors:

bash
Copy code
# On agent
sudo tail -n 100 /var/ossec/logs/ossec.log

# On manager
sudo tail -n 100 /var/ossec/logs/ossec.log
2) Active Response not blocking IP
Verify rule fired in alerts:

bash
Copy code
sudo grep "100100" /var/ossec/logs/alerts/alerts.log || true
Confirm CDB list exists and ownership:

bash
Copy code
ls -l /var/ossec/etc/lists/blacklist-alienvault
sudo chown wazuh:wazuh /var/ossec/etc/lists/blacklist-alienvault || true
Check Active Response scripts:

bash
Copy code
ls -l /var/ossec/active-response/bin/
3) Dashboard SSL warning
This is expected with default self-signed cert. Accept the exception in your browser or replace with a trusted certificate.

4) Disable auto-updates (recommended for lab)
bash
Copy code
# Debian/Ubuntu
sudo sed -i "s/^deb /#deb /" /etc/apt/sources.list.d/wazuh.list 2>/dev/null || true

# RHEL/CentOS
sudo sed -i "s/^enabled=1/enabled=0/" /etc/yum.repos.d/wazuh.repo 2>/dev/null || true
🖥️ Resource constraint / cloud option
If your local PC cannot run 3 VMs simultaneously due to CPU/RAM limits, use a public cloud provider to host the VMs (examples: Google Cloud, AWS, Azure). Benefits for this lab:

Provision multiple small VMs quickly (no heavy local resource usage).

Snapshots and images for quick recovery.

Public IPs and easier network/firewall testing.

Scale resources up/down if needed.

Practical tips:

Use small instance types for a lab (e.g., 1–2 vCPU, 2–4 GB RAM) for attacker and web VMs; manager may need more (4 vCPU, 8GB) depending on agents.

Use snapshots or images to save a working state before making large changes.

Configure firewall rules / VPC rules to allow only the ports you need (agent↔manager, HTTP/80).

🛠️ VM interface down: ens33 shows DOWN and ip address doesn't show IP
If a VM gets restarted and ip address shows ens33 but no inet address (or the interface is DOWN), use these steps to bring it up and request an IP from DHCP.

Check interface status:

bash
Copy code
# show link state and interfaces
ip link show ens33
# or show all addresses
ip addr show
Bring the interface up:

bash
Copy code
# Bring the link up (equivalent to "ifup")
sudo ip link set ens33 up
Request an IP via DHCP (DHCLIENT method):

bash
Copy code
# Request DHCP lease interactively and show the logs
sudo dhclient -v ens33
Verify the interface now has an IP:

bash
Copy code
ip addr show ens33
# or a concise view
ip -4 addr show dev ens33
If system uses NetworkManager (alternative):

bash
Copy code
# Make sure NM manages the device and connect it
sudo nmcli device set ens33 managed yes
sudo nmcli device connect ens33
# then check the IP
nmcli -g IP4.ADDRESS device show ens33
If system uses netplan (Ubuntu server modern versions):

bash
Copy code
# Re-apply netplan config (if configured for DHCP)
sudo netplan apply
# then check the IP
ip addr show ens33
If DHCP fails repeatedly, check:

bash
Copy code
# Look at system logs for dhclient / network error messages
sudo journalctl -u NetworkManager -n 200 --no-pager || true
sudo journalctl -u systemd-networkd -n 200 --no-pager || true
# Or review syslog
sudo tail -n 200 /var/log/syslog
Why this happens: after a reboot the NIC may be administratively down, or the network manager didn't re-request a DHCP lease. Running ip link set ... up + dhclient forces the kernel link and DHCP client to request a new lease.

📂 Useful Log Locations
Manager alerts: /var/ossec/logs/alerts/alerts.log

Manager logs: /var/ossec/logs/ossec.log

Agent logs: /var/ossec/logs/ossec.log

Apache logs: /var/log/apache2/access.log, /var/log/apache2/error.log

Networking logs: sudo journalctl -u NetworkManager or /var/log/syslog

✅ Quick troubleshooting checklist
 Confirm Apache landing page accessible from attacker VM.

 Agent enrolled and visible in Manager UI.

 blacklist-alienvault exists, owned by wazuh:wazuh.

 Rule 100100 appears in alerts when attacker hits webserver.

 Active Response blocks repeated attacker requests.

 If interface shows DOWN, run ip link set ens33 up then dhclient ens33 (or nmcli / netplan apply) and re-check.

