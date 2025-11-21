import argparse
import json
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import urllib.request
import sys

# --- DATA STORE (Lives on DB Tier) ---
INITIAL_DATA = [
    {"id": 1, "type": "critical", "title": "Evacuation Warning", "message": "Zone 4 residents should prepare to evacuate.", "time": "10 mins ago"},
    {"id": 2, "type": "warning", "title": "High Wind Advisory", "message": "Gusts up to 45mph expected in canyon areas.", "time": "2 hours ago"}
]
# Global in-memory store
DB_STORE = list(INITIAL_DATA)

class RequestHandler(BaseHTTPRequestHandler):
    def _send_cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self._send_cors()
        self.end_headers()

    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        # -------------------------------------------------------
        # TIER 3: DATABASE LOGIC (The "Real" Data Source)
        # -------------------------------------------------------
        if args.mode == 'db':
            self.send_response(200)
            self._send_cors()
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            # The DB Tier returns the actual data
            self.wfile.write(json.dumps(DB_STORE).encode())
            return

        # -------------------------------------------------------
        # TIER 2: APPLICATION LOGIC (The Middleware)
        # -------------------------------------------------------
        
        # 1. Get Alerts: MUST query the DB Tier
        if parsed_path.path == '/api/alerts':
            try:
                print(f"[App] Querying Database at {args.db_host}...")
                # REAL TRAFFIC FLOW: App -> DB
                req = urllib.request.urlopen(f"http://{args.db_host}:5432/", timeout=2)
                db_data = req.read()
                
                self.send_response(200)
                self._send_cors()
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(db_data) # Pass DB response to Web
            except Exception as e:
                print(f"[App] CRITICAL: Database Unreachable! {e}")
                self.send_response(503)
                self._send_cors()
                self.end_headers()
                self.wfile.write(json.dumps([]).encode()) # Return empty list if DB down

        # 2. Chain/Health Check (For Testing Page)
        elif parsed_path.path == '/api/chain':
            try:
                req = urllib.request.urlopen(f"http://{args.db_host}:5432/", timeout=2)
                self.send_response(200)
                self._send_cors()
                self.end_headers()
                self.wfile.write(json.dumps({"status": "success"}).encode())
            except:
                self.send_response(500)
                self._send_cors()
                self.end_headers()
                self.wfile.write(b'{"status": "failed"}')

        # 3. Threat Simulations (Endpoint exists but does nothing malicious)
        elif '/api/status' in parsed_path.path or '/api/download' in parsed_path.path:
            self.send_response(200)
            self._send_cors()
            self.end_headers()
            self.wfile.write(b'{"status": "threat_logged"}')
            
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        # DB Tier: Actually save the data
        if args.mode == 'db':
            try:
                new_record = json.loads(post_data)
                DB_STORE.insert(0, new_record)
                self.send_response(200)
            except:
                self.send_response(400)
            self._send_cors()
            self.end_headers()
            self.wfile.write(b'{"status": "committed"}')
            return

        # App Tier: Forward to DB
        if args.mode == 'app' and self.path == '/api/alerts':
            try:
                print(f"[App] Writing to Database at {args.db_host}...")
                req = urllib.request.Request(f"http://{args.db_host}:5432/", data=post_data, method='POST')
                urllib.request.urlopen(req, timeout=2)
                
                self.send_response(200)
                self._send_cors()
                self.end_headers()
                self.wfile.write(json.dumps({"status": "forwarded"}).encode())
            except Exception as e:
                print(f"[App] DB Write Failed: {e}")
                self.send_response(503)
                self._send_cors()
                self.end_headers()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['app', 'db'], required=True)
    parser.add_argument('--db-host', default='db.communitysafe.local')
    args = parser.parse_args()

    port = 5432 if args.mode == 'db' else 5000
    print(f"[{args.mode.upper()}] Listening on port {port}...")
    server = HTTPServer(('0.0.0.0', port), RequestHandler)
    server.serve_forever()
