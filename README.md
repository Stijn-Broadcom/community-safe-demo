# CommunitySafe: VCF Security Demo Application

**CommunitySafe** is a purpose-built, 3-tier web application designed to demonstrate **VMware vDefend (formerly NSX) Distributed Firewall (DFW)** and **Advanced Threat Prevention (ATP)** capabilities on VMware Cloud Foundation (VCF).

## 🎯 Demo Capabilities

### 1. Zero Trust & Micro-segmentation
* **Scenario:** Enforce strict East-West traffic controls.
* **Validation:** The app relies on a strict `Web -> App -> DB` traffic chain. Blocking `Web -> DB` or `App -> DB` ports will visibly break specific features (Alerts, Zone Lookups), providing immediate visual feedback of policy enforcement.

### 2. Advanced Threat Prevention (IDPS)
* **Scenario:** Detect and block malicious traffic signatures.
* **Feature:** The built-in **"Threat Generator"** (Testing Tab) launches real HTTP requests containing signatures for **SQL Injection**, **Log4j**, and **DNS Exfiltration**.

### 3. Malware Prevention
* **Scenario:** Prevent malicious file downloads.
* **Feature:** The **"Malware Sim"** button attempts to download an EICAR test string.

---

## 📚 Documentation

* **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md):** Step-by-step instructions for deploying the VMs using OVAs.
* **[vDefend Evaluation Guide](docs/vDefend_Eval_Guide.md):** A structured Proof of Concept (POC) test plan.

---

## 🚀 Quick Start (OVA Deployment)

1.  **Download** the 3 OVA files from the Releases Page.
2.  **Deploy** them into your VCF environment.
3.  **Configure Networking:** Ensure all 3 VMs can communicate.
4.  **Link the Tiers:** Update `/etc/hosts` on ALL 3 VMs to map IPs to FQDNs (See [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)).
5.  **Access:** Open `http://<WEB-VM-IP>` in your browser.
