# Deployment Guide: CommunitySafe Demo

This guide covers the deployment of the CommunitySafe application using pre-packaged OVAs.

## Phase 1: Deploy Virtual Machines

1.  **Import OVAs:**
    * Deploy `CommunitySafe-Web.ova`
    * Deploy `CommunitySafe-App.ova`
    * Deploy `CommunitySafe-DB.ova`
    * *Hardware Specs:* 1 vCPU, 2GB RAM, 16GB Disk (Thin) per VM.

2.  **Power On:**
    * Start all three VMs.
    * Login to the console or via SSH.
    * **Default Credentials:** `root` / `changeme` (or as configured in OVA).

3.  **Identify IP Addresses:**
    * Run `ip addr` on each VM and note their IP addresses.

---

## Phase 2: Link the Tiers (Critical)

The application uses **FQDNs** (Domain Names) to communicate. You must map these names to your specific IPs using the local hosts file.

**Perform this step on ALL 3 VMs (Web, App, and DB):**

1.  Edit the hosts file: `vi /etc/hosts`
2.  Add the following lines at the bottom (Replace with **YOUR** IPs):
    ```text
    192.168.1.10  web.communitysafe.local
    192.168.1.11  app.communitysafe.local
    192.168.1.12  db.communitysafe.local
    ```
3.  **Restart Services:**
    * **Web:** `systemctl restart nginx`
    * **App:** `systemctl restart community-app` (or reboot)
    * **DB:** `systemctl restart community-db` (or reboot)

---

## Phase 3: Validation

1.  Open a browser and navigate to `http://<WEB-VM-IP>`.
2.  Navigate to the **Testing** tab.
3.  Click **"Single Flow"**.
4.  Verify that you see blue dots traveling from **Web Tier** -> **App Tier** -> **DB Tier**.

---

## Advanced: Manual Build (Source Code)

If you prefer to build the VMs from scratch:

1.  Deploy 3 **Photon OS 5.0 Minimal** VMs.
2.  **Web VM:**
    * Install Node.js (`tdnf install nodejs`).
    * Copy `scripts/setup_app.sh` to the VM.
    * Run `chmod +x setup_app.sh && ./setup_app.sh`.
    * Configure Nginx using `configs/nginx.conf`.
3.  **App & DB VMs:**
    * Install Python 3.
    * Copy `scripts/backend_services.py` to `/root/`.
    * **App VM:** Run `python3 backend_services.py --mode app --db-host db.communitysafe.local`
    * **DB VM:** Run `python3 backend_services.py --mode db`
