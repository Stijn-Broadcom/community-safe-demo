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
        
        # DB TIER
        if args.mode == 'db':
            self.send_response(200)
            self._send_cors()
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(DB_STORE).encode())
            return

        # APP TIER
        if parsed_path.path == '/api/alerts':
            try:
                req = urllib.request.urlopen(f"http://{args.db_host}:5432/", timeout=2)
                db_data = req.read()
                self.send_response(200)
                self._send_cors()
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(db_data)
            except Exception as e:
                self.send_response(503)
                self._send_cors()
                self.end_headers()
                self.wfile.write(json.dumps([]).encode())

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

        if args.mode == 'app' and self.path == '/api/alerts':
            try:
                req = urllib.request.Request(f"http://{args.db_host}:5432/", data=post_data, method='POST')
                urllib.request.urlopen(req, timeout=2)
                self.send_response(200)
                self._send_cors()
                self.end_headers()
                self.wfile.write(json.dumps({"status": "forwarded"}).encode())
            except:
                self.send_response(503)
                self._send_cors()
                self.end_headers()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['app', 'db'], required=True)
    parser.add_argument('--db-host', default='db.communitysafe.local')
    args = parser.parse_args()
    port = 5432 if args.mode == 'db' else 5000
    server = HTTPServer(('0.0.0.0', port), RequestHandler)
    server.serve_forever()
