# vDefend Evaluation Guide

## Test 1: Micro-segmentation
1. Go to **Testing** tab -> Click **Single Flow**.
2. Create NSX Rule: **Block App -> DB (TCP 5432)**.
3. Click **Single Flow** again. 
   - **Result:** The blue dots should stop at App Tier. 

## Test 2: IDPS (Signatures)
1. Go to **Testing** tab -> **Attack Simulation**.
2. Click **SQL Injection**.
3. Check NSX IDPS Dashboard for `ET WEB_SPECIFIC_APPS` alert.

## Test 3: Malware
1. Click **Malware Download**.
2. Check NSX Malware Dashboard for `EICAR-Test-File`.
