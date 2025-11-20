# VMware vDefend: Evaluation & Testing Guide
**Target Environment:** CommunitySafe 3-Tier Demo Application

This guide outlines a structured Proof of Concept (POC) plan to evaluate **VMware vDefend Firewall** and **Advanced Threat Prevention (ATP)**.

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
3.  **Test B (RCE):** Click **"Log4j / RCE Attack"**.
4.  **Validation:** Check **NSX Manager -> Security -> IDS/IPS Events**. Look for `ET WEB_SPECIFIC_APPS` or `Apache Log4j`.

### Scenario 3: Malware Prevention
**Objective:** Demonstrate file inspection.

1.  **Attack:** Click **"Malware Download (EICAR)"** in the Testing tab.
2.  **Validation:** Check **NSX Manager -> Malware Prevention**. Look for `EICAR-Test-File`.

### Scenario 4: NDR (Anomaly Detection)
**Objective:** Detect "low and slow" attacks.

1.  **Attack:** Click **"DNS Tunneling"** or **"Port Scan"**.
2.  **Validation:** Check **NSX NDR Dashboard** for MITRE ATT&CK T1048/T1046.
