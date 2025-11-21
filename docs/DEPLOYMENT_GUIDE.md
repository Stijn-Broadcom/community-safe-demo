# Deployment Guide: CommunitySafe Demo

## Phase 1: Deploy Virtual Machines
1.  **Import OVAs:** Deploy `Web`, `App`, and `DB` OVAs from the release page.
2.  **Power On:** Start all three VMs. Default creds: `root` / `changeme`.
3.  **Identify IPs:** Run `ip addr` on each VM.

## Phase 2: Link the Tiers (Critical)
The app uses FQDNs. Run this on **ALL 3 VMs**:
1.  Edit hosts: `vi /etc/hosts`
2.  Add lines (replace with your IPs):
    ```text
    192.168.1.10  web.communitysafe.local
    192.168.1.11  app.communitysafe.local
    192.168.1.12  db.communitysafe.local
    ```
3.  **Restart Services:**
    * Web: `systemctl restart nginx`
    * App/DB: `reboot`
