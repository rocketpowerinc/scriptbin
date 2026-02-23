#!/usr/bin/env bash

set -e

PROJECT_NAME="UltimateLinuxLauncher"

echo "🚀 Building Ultimate Linux Launcher..."

# Dependency Check
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js and npm..."
    sudo apt update
    sudo apt install -y nodejs npm
fi

rm -rf "$PROJECT_NAME"
mkdir -p "$PROJECT_NAME/src/services"
mkdir -p "$PROJECT_NAME/assets/Games"
mkdir -p "$PROJECT_NAME/assets/Dev"
mkdir -p "$PROJECT_NAME/assets/Utilities"

cd "$PROJECT_NAME"

npm init -y > /dev/null
npm install electron --save-dev > /dev/null

# -----------------------------
# package.json
# -----------------------------
cat > package.json << 'EOF'
{
  "name": "ultimate-linux-launcher",
  "version": "1.0.0",
  "main": "main.js",
  "scripts": {
    "start": "electron ."
  },
  "devDependencies": {
    "electron": "^28.0.0"
  }
}
EOF

# -----------------------------
# main.js (Frameless & Right-Click Support)
# -----------------------------
cat > main.js << 'EOF'
const { app, BrowserWindow, ipcMain, Menu, shell } = require("electron");
const path = require("path");

let win;

function createWindow() {
  win = new BrowserWindow({
    width: 1200,
    height: 750,
    frame: false, // Frameless for modern look
    backgroundColor: "#000000",
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  win.loadFile(path.join(__dirname, "src/index.html"));
}

app.whenReady().then(createWindow);

// Window Control Listeners
ipcMain.on("minimize", () => win.minimize());
ipcMain.on("toggle-maximize", () => {
  if (win.isMaximized()) win.unmaximize();
  else win.maximize();
  win.webContents.send("max-state", win.isMaximized());
});
ipcMain.on("close", () => win.close());

// Native Context Menu for Apps
ipcMain.on("context-menu", (event, website) => {
  const menu = Menu.buildFromTemplate([
    { label: "Open Official Website", click: () => shell.openExternal(website) },
    { type: 'separator' },
    { label: "Close Menu", role: 'close' }
  ]);
  menu.popup({ window: win });
});
EOF

# -----------------------------
# src/index.html (Modern UI + Sidebar Logic)
# -----------------------------
cat > src/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Ultimate Launcher</title>
<style>
  html, body { height: 100%; margin: 0; overflow: hidden; }
  body {
    font-family: 'Segoe UI', sans-serif;
    color: white;
    background-size: cover;
    background-position: center;
    transition: background-image 0.5s ease-in-out;
  }

  /* Top Bar Controls */
  .topbar {
    height: 35px;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    background: rgba(0,0,0,0.7);
    backdrop-filter: blur(10px);
    -webkit-app-region: drag;
  }
  .window-btn {
    width: 45px;
    height: 100%;
    border: none;
    background: transparent;
    color: white;
    cursor: pointer;
    -webkit-app-region: no-drag;
  }
  .window-btn:hover { background: rgba(255,255,255,0.2); }
  .close-btn:hover { background: #e81123; }

  /* Sidebar */
  .sidebar {
    position: absolute;
    left: 0; top: 35px;
    width: 220px;
    height: calc(100% - 35px);
    background: rgba(0,0,0,0.85);
    backdrop-filter: blur(20px);
    display: flex;
    flex-direction: column;
    transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 10;
  }
  .sidebar.collapsed { width: 60px; }

  .hamburger {
    padding: 20px;
    font-size: 20px;
    background: none; border: none; color: white;
    cursor: pointer; text-align: left;
  }

  .category-btn {
    background: none; border: none; color: white;
    padding: 15px 20px; text-align: left;
    font-size: 16px; cursor: pointer;
    white-space: nowrap; overflow: hidden;
    transition: background 0.2s;
  }
  .category-btn:hover { background: rgba(255,255,255,0.1); }
  .sidebar.collapsed .category-text { display: none; }

  /* App Grid */
  .content-area {
    margin-left: 220px;
    height: calc(100% - 35px);
    overflow-y: auto;
    transition: margin-left 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    padding: 40px;
  }
  .content-area.shifted { margin-left: 60px; }

  .apps-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 25px;
  }

  .app-card {
    background: rgba(0,0,0,0.5);
    backdrop-filter: blur(5px);
    padding: 30px 15px;
    text-align: center;
    border-radius: 12px;
    border: 1px solid rgba(255,255,255,0.1);
    cursor: pointer;
    transition: all 0.3s ease;
  }
  .app-card:hover {
    transform: translateY(-5px);
    background: rgba(255,255,255,0.15);
    border-color: rgba(255,255,255,0.4);
  }
</style>
</head>
<body>

<div class="topbar">
  <button class="window-btn" onclick="minimize()">—</button>
  <button class="window-btn" id="maxBtn" onclick="toggleMax()">▢</button>
  <button class="window-btn close-btn" onclick="closeApp()">✕</button>
</div>

<div class="sidebar" id="sidebar">
  <button class="hamburger" onclick="toggleSidebar()">☰</button>
  <div id="category-list" style="display:flex; flex-direction:column;"></div>
</div>

<div class="content-area" id="content-area">
  <div class="apps-grid" id="apps-grid"></div>
</div>

<script src="AppLauncher.js"></script>
</body>
</html>
EOF

# -----------------------------
# src/services/categoryService.js
# -----------------------------
cat > src/services/categoryService.js << 'EOF'
const fs = require("fs");
const path = require("path");

const assetsPath = path.join(__dirname, "..", "..", "assets");

function getCategories() {
  if (!fs.existsSync(assetsPath)) return [];
  
  return fs.readdirSync(assetsPath, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => {
      const configPath = path.join(assetsPath, d.name, "config.json");
      let config = { apps: [] };
      if (fs.existsSync(configPath)) {
        config = JSON.parse(fs.readFileSync(configPath));
      }
      return {
        name: d.name,
        wallpaper: path.join(assetsPath, d.name, "wallpaper.png"),
        apps: config.apps || []
      };
    });
}

module.exports = { getCategories };
EOF

# -----------------------------
# src/AppLauncher.js
# -----------------------------
cat > src/AppLauncher.js << 'EOF'
const { exec } = require("child_process");
const { ipcRenderer } = require("electron");
const { getCategories } = require("./services/categoryService");

const categories = getCategories();
const categoryList = document.getElementById("category-list");
const appsGrid = document.getElementById("apps-grid");
const sidebar = document.getElementById("sidebar");
const contentArea = document.getElementById("content-area");

function loadCategory(category) {
  // Update Background
  const imgPath = category.wallpaper.replace(/\\/g, "/");
  document.body.style.backgroundImage = `linear-gradient(rgba(0,0,0,0.4), rgba(0,0,0,0.4)), url('file://${imgPath}')`;

  appsGrid.innerHTML = "";

  category.apps.forEach(app => {
    const card = document.createElement("div");
    card.className = "app-card";
    card.innerHTML = `<div>${app.name}</div>`;

    card.onclick = () => exec(app.cmd);

    // Right Click for Website
    if (app.website) {
      card.oncontextmenu = (e) => {
        e.preventDefault();
        ipcRenderer.send("context-menu", app.website);
      };
    }

    appsGrid.appendChild(card);
  });
}

// Build Sidebar
categories.forEach(cat => {
  const btn = document.createElement("button");
  btn.className = "category-btn";
  btn.innerHTML = `<span style="margin-right:15px">📁</span> <span class="category-text">${cat.name}</span>`;
  btn.onclick = () => loadCategory(cat);
  categoryList.appendChild(btn);
});

// Sidebar Toggle
window.toggleSidebar = () => {
  sidebar.classList.toggle("collapsed");
  contentArea.classList.toggle("shifted");
};

// Window Controls
window.minimize = () => ipcRenderer.send("minimize");
window.toggleMax = () => ipcRenderer.send("toggle-maximize");
window.closeApp = () => ipcRenderer.send("close");

ipcRenderer.on("max-state", (e, isMax) => {
  document.getElementById("maxBtn").innerText = isMax ? "❐" : "▢";
});

// Initial Load
if (categories.length > 0) loadCategory(categories[0]);
EOF

# -----------------------------
# Sample Data & Launch
# -----------------------------
cat > assets/Games/config.json << 'EOF'
{
  "apps": [
    { "name": "Steam", "cmd": "steam", "website": "https://store.steampowered.com/" }
  ]
}
EOF

cat > assets/Dev/config.json << 'EOF'
{
  "apps": [
    { "name": "VS Code", "cmd": "code", "website": "https://code.visualstudio.com" },
    { "name": "Terminal", "cmd": "gnome-terminal" }
  ]
}
EOF

# Create dummy wallpaper files if they don't exist
touch assets/Games/wallpaper.png
touch assets/Dev/wallpaper.png
touch assets/Utilities/wallpaper.png

echo "✅ Ultimate Launcher Build Complete"
echo "👉 Pro-tip: Replace the empty wallpaper.png files in the assets folders!"
npm start