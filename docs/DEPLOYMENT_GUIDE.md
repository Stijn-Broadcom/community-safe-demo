# Deployment Guide: CommunitySafe Demo

This guide covers the deployment of the CommunitySafe application using pre-packaged OVAs.

## Phase 1: Deploy Virtual Machines

1.  **Download & Import OVAs:**
    * **Obtain Files:** Download `CommunitySafe-Web.ova`, `CommunitySafe-App.ova`, and `CommunitySafe-DB.ova` from the GitHub Release page.
    * **Deploy:** In vCenter/ESXi, select **"Deploy OVF Template"**. Import all three OVA files.
    * *Note:* Ensure the deployed VMs are attached to the network segment you intend to secure with NSX.
    * *Hardware Specs:* 1 vCPU, 2GB RAM minimum is recommended.

2.  **Power On & Identify IP Addresses:**
    * Start all three VMs.
    * Login to the console or via SSH (`root` / `changeme`).
    * Run `ip addr` on each VM and record their IP addresses (e.g., Web: 192.168.1.10, App: 192.168.1.11, DB: 192.168.1.12).

---

## Phase 2: Link the Tiers (Critical)

The application uses **FQDNs** (`*.communitysafe.local`) for communication. You must map these names to your specific IPs using the local hosts file.

**Perform this step on ALL 3 VMs (Web, App, and DB):**

1.  Edit the hosts file:
    ```bash
    vi /etc/hosts
    ```
2.  Add the following lines at the bottom (Replace the example IPs with **YOUR** IPs):
    ```text
    # FQDN Mapping for CommunitySafe Demo
    192.168.1.226  web.communitysafe.local
    192.168.1.138  app.communitysafe.local
    192.168.1.128  db.communitysafe.local
    ```
3.  Save and exit (`Esc`, `:wq`, `Enter`).

4.  **Restart the Services** (This loads the Nginx/Python services and checks the new hosts file):
    * **On Web VM:** `systemctl restart nginx`
    * **On App VM:** `systemctl restart community-app`
    * **On DB VM:** `systemctl restart community-db`

---

## Phase 3: Validation

1.  Open a browser and navigate to `http://<WEB-VM-IP>`.
2.  You should see the **CommunitySafe** dashboard.
3.  Navigate to the **Testing** tab.
4.  Click **"Single Flow"**.
5.  Verify that you see blue dots traveling from **Web Tier** -> **App Tier** -> **DB Tier**.

---

## Advanced: Manual Build (Source Code)

If you prefer to build the VMs from scratch instead of using OVAs:

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
