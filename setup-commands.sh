#!/usr/bin/env bash
# setup-commands.sh
# Purpose: grouped, step-by-step commands for Manager / Web / Attacker VMs.
# Usage:
#   1) set MANAGER_IP, WEB_IP, ATTACKER_IP variables below
#   2) make this file executable: chmod +x setup-commands.sh
#   3) run: ./setup-commands.sh manager   (on manager VM)
#      or:  ./setup-commands.sh web       (on web VM)
#      or:  ./setup-commands.sh attacker  (on attacker VM)

set -euo pipefail

# -------------------------
# Edit placeholders here
# -------------------------
MANAGER_IP="<MANAGER_IP>"
WEB_IP="<WEB_IP>"
ATTACKER_IP="<ATTACKER_IP>"

# -------------------------
# Manager section
# -------------------------
manager_setup() {
  echo "== Manager: install Wazuh central components (quickstart) =="
  # Download and run the Wazuh installation assistant (single-host quickstart).
  # This installs Wazuh manager, indexer and dashboard on the same host.
  curl -sO https://packages.wazuh.com/4.13/wazuh-install.sh \
    && sudo bash ./wazuh-install.sh -a

  echo "== Manager: installer finished. Note the admin password printed by the installer =="
  echo "Dashboard URL: https://${MANAGER_IP}"
  echo "User: admin  (password printed at end of installer output)"

  echo "== Manager: download a public IP reputation list (AlienVault ipset) =="
  # Save the ipset list under Wazuh lists path
  sudo mkdir -p /var/ossec/etc/lists
  sudo wget https://iplists.firehol.org/files/alienvault_reputation.ipset \
    -O /var/ossec/etc/lists/alienvault_reputation.ipset

  echo "== Manager: append ATTACKER_IP to the ipset list =="
  # Add the attacker IP to the list so it will be part of the exported CDB list
  echo "${ATTACKER_IP}" | sudo tee -a /var/ossec/etc/lists/alienvault_reputation.ipset > /dev/null

  echo "== Manager: convert ipset to CDB list used by Wazuh =="
  # Download the conversion script, then convert ipset -> cdb (blacklist-alienvault)
  sudo wget https://wazuh.com/resources/iplist-to-cdblist.py -O /tmp/iplist-to-cdblist.py
  sudo /var/ossec/framework/python/bin/python3 /tmp/iplist-to-cdblist.py \
    /var/ossec/etc/lists/alienvault_reputation.ipset \
    /var/ossec/etc/lists/blacklist-alienvault

  # Ensure ownership so Wazuh can read it
  sudo chown wazuh:wazuh /var/ossec/etc/lists/blacklist-alienvault

  # Optional: remove the original ipset and converter if you want a clean directory
  sudo rm -f /tmp/iplist-to-cdblist.py
  sudo rm -f /var/ossec/etc/lists/alienvault_reputation.ipset

  echo "== Manager: add the list entry to /var/ossec/etc/ossec.conf (manual edit required) =="
  echo "Add under <ruleset> section:   <list>etc/lists/blacklist-alienvault</list>"
  echo "You can append it programmatically, but review the file before changes."

  echo "== Manager: add local rule to trigger Active Response (manual edit) =="
  echo "Append the following to /var/ossec/etc/rules/local_rules.xml:"
  cat <<'XML'
<group name="attack,">
  <rule id="100100" level="10">
    <if_group>web|attack|attacks</if_group>
    <list field="srcip" lookup="address_match_key">etc/lists/blacklist-alienvault</list>
    <description>IP address found in AlienVault reputation database.</description>
  </rule>
</group>
XML

  echo "== Manager: enable Active Response (manual edit in /var/ossec/etc/ossec.conf) =="
  echo "Add (Linux example using firewall-drop):"
  cat <<'XML'
<active-response>
  <disabled>no</disabled>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100100</rules_id>
  <timeout>60</timeout>
</active-response>
XML

  echo "== Manager: restart wazuh-manager to apply changes =="
  sudo systemctl restart wazuh-manager
  echo "Manager tasks completed."
}

# -------------------------
# Web server section (Ubuntu)
# -------------------------
web_setup() {
  echo "== Web: install Apache and configure Wazuh agent log collection =="
  # Update package list and install Apache server
  sudo apt update
  sudo apt install -y apache2

  # Ensure Apache is enabled and started
  sudo systemctl enable --now apache2

  # If UFW is active, allow the Apache profile
  if sudo ufw status | grep -q "Status: active"; then
    # This opens port 80 for Apache
    sudo ufw allow 'Apache'
  fi

  # Quick verification of the landing page (returns HTML)
  echo "== Web: test HTTP landing page =="
  curl -f "http://${WEB_IP}" || true

  # Configure the Wazuh agent to monitor Apache access.log
  echo "== Web: configure Wazuh agent to monitor /var/log/apache2/access.log =="
  # Backup agent config before editing
  sudo cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak.$(date +%s)

  # Append localfile block to ossec.conf
  sudo tee -a /var/ossec/etc/ossec.conf > /dev/null <<'XML'

<!-- monitor Apache access log -->
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/apache2/access.log</location>
</localfile>
XML

  # Restart the agent to pick up changes
  sudo systemctl restart wazuh-agent
  echo "Web server setup complete."
}

# -------------------------
# Attacker section
# -------------------------
attacker_test() {
  echo "== Attacker: curl test to simulate malicious traffic =="
  echo "Run the following from the attacker VM to hit the webserver:"
  echo "curl -v http://${WEB_IP}"
  echo ""
  echo "Expected behavior: first request is allowed and generates an alert. Subsequent requests (within the configured timeout) should be blocked by the Active Response."
}

# -------------------------
# Usage helper
# -------------------------
usage() {
  cat <<EOF
Usage: $0 {manager|web|attacker}
  manager   Run manager setup steps (run on the Wazuh Manager VM)
  web       Run web server setup steps (run on the Apache VM)
  attacker  Print attacker test command (run on the attacker VM)
EOF
  exit 1
}

# -------------------------
# Entry point
# -------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -ne 1 ]]; then
    usage
  fi

  case "$1" in
    manager) manager_setup ;;
    web) web_setup ;;
    attacker) attacker_test ;;
    *) usage ;;
  esac
fi
