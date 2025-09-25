# Wazuh SIEM Demo — Blocking a Malicious IP (POC)

## Introduction
This repository contains a compact lab to deploy a Wazuh SIEM (manager + indexer + dashboard) and an Apache web server, then demonstrate a Proof-of-Concept where Wazuh automatically blocks a malicious IP using a reputation list and Active Response. It's a hands-on demo for learning Wazuh detection → response workflow in a small 3-VM lab.

## What this project includes
- A three-VM topology (Manager, Web server, Attacker) for a reproducible PoC.
- `setup-commands.sh` — copy/paste commands for each VM (Manager / Web / Attacker). Commands are commented to explain their function.
- `notes.md` — troubleshooting tips and verification commands (optional).
- Suggested license: MIT or Apache-2.0 (add `LICENSE` if desired).

## Topology
- **VM1 — Wazuh Manager**: Wazuh server + indexer + dashboard (single-host quickstart).  
- **VM2 — Apache Web Server**: Ubuntu host with Apache and Wazuh agent installed.  
- **VM3 — Attacker**: Linux host used to generate HTTP requests to the Apache server.

<img width="700" height="384" alt="image" src="https://github.com/user-attachments/assets/041bbdcd-7e89-44c9-9b19-ff56c670d3f8" />


## Goals
1. Install Wazuh central components (quickstart).  
2. Configure agent on Apache server to collect `access.log`.  
3. Import an IP reputation list, add the attacker IP, convert to CDB.  
4. Add a custom rule that references the CDB list and ties to an Active Response (e.g., `firewall-drop`).  
5. Validate: attacker can access once, then is blocked for the configured timeout.

## Prerequisites
- Three VMs with network connectivity and sudo access.  
- Recommended OS examples:
  - Manager: Ubuntu 20.04 / 22.04 (64-bit) or RHEL/CentOS supported versions.
  - Web: Ubuntu 22.04.
  - Attacker: RHEL 9 / any Linux with `curl`.
- Time sync enabled on all hosts.  
- Ensure required ports (agent ↔ manager) are open.

## How to use
1. Edit `setup-commands.sh` and set `MANAGER_IP`, `WEB_IP`, and `ATTACKER_IP`.  
2. On each VM run the appropriate section from `setup-commands.sh`:
   - `./setup-commands.sh manager` (on manager VM)
   - `./setup-commands.sh web` (on web VM)
   - `./setup-commands.sh attacker` (on attacker VM)
3. Validate using the commands in `notes.md` or the verification section below.

## Verification
- Apache status: `sudo systemctl status apache2`  
- Agent status: `sudo systemctl status wazuh-agent`  
- Manager status: `sudo systemctl status wazuh-manager`  
- Alerts: `sudo tail -n 200 /var/ossec/logs/alerts/alerts.log`  
- Dashboard: `https://<MANAGER_IP>` (user: `admin`, password printed by installer)

## Safety note
This repo is for lab/demo use. Active Response scripts modify firewall rules — test in an isolated lab before trying in production.

## References
- Wazuh Quickstart: https://documentation.wazuh.com/current/quickstart.html  
- PoC guide: Blocking a known malicious actor — Wazuh docs.
