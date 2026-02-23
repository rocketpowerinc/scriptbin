#!/usr/bin/env bash

set -e

PROJECT_NAME="UltimateLinuxLauncher"

echo "🚀 Building Ultimate Linux Launcher..."

# ----------------------------------
# Install Node.js if missing
# ----------------------------------
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js and npm..."
    sudo apt update
    sudo apt install -y nodejs npm
fi

# ----------------------------------
# Ensure Flatpak + Flathub
# ----------------------------------
if ! command -v flatpak &> /dev/null; then
    echo "📦 Installing Flatpak..."
    sudo apt install -y flatpak
fi

if ! flatpak remote-list | grep -q flathub; then
    echo "📦 Adding Flathub repo..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ----------------------------------
# Clean previous build
# ----------------------------------
rm -rf "$PROJECT_NAME"
mkdir -p "$PROJECT_NAME/src/services"
mkdir -p "$PROJECT_NAME/assets/Games"
mkdir -p "$PROJECT_NAME/assets/Dev"
mkdir -p "$PROJECT_NAME/assets/Utilities"

cd "$PROJECT_NAME"

npm init -y > /dev/null
npm install electron --save-dev > /dev/null

# ----------------------------------
# package.json
# ----------------------------------
cat > package.json << 'EOF'
{
  "name": "ultimate-linux-launcher",
  "version": "2.0.0",
  "main": "main.js",
  "scripts": {
    "start": "electron ."
  },
  "devDependencies": {
    "electron": "^28.0.0"
  }
}
EOF

# ----------------------------------
# main.js
# ----------------------------------
cat > main.js << 'EOF'
const { app, BrowserWindow, ipcMain, Menu, shell } = require("electron");
const path = require("path");
const { exec } = require("child_process");

let win;

function createWindow() {
  win = new BrowserWindow({
    width: 1200,
    height: 750,
    frame: false,
    backgroundColor: "#000000",
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  win.loadFile(path.join(__dirname, "src/index.html"));
}

app.whenReady().then(createWindow);

ipcMain.on("minimize", () => win.minimize());
ipcMain.on("toggle-maximize", () => {
  if (win.isMaximized()) win.unmaximize();
  else win.maximize();
  win.webContents.send("max-state", win.isMaximized());
});
ipcMain.on("close", () => win.close());

ipcMain.on("context-menu-extended", (event, data) => {
  const template = [
    {
      label: "Open Official Website",
      click: () => shell.openExternal(data.website)
    }
  ];

  if (data.type === "flatpak") {
    template.push({ type: "separator" });
    template.push({
      label: "Uninstall App",
      click: () => exec(`flatpak remove ${data.id} -y`)
    });
  }

  const menu = Menu.buildFromTemplate(template);
  menu.popup({ window: win });
});
EOF

# ----------------------------------
# index.html
# ----------------------------------
cat > src/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Ultimate Launcher</title>
<style>
html, body { height:100%; margin:0; overflow:hidden; }
body {
  font-family: 'Segoe UI', sans-serif;
  color:white;
  background-size:cover;
  background-position:center;
  transition: background-image 0.4s ease;
}
.topbar {
  height:35px;
  display:flex;
  justify-content:flex-end;
  align-items:center;
  background:rgba(0,0,0,0.8);
  -webkit-app-region: drag;
}
.window-btn {
  width:45px;
  height:100%;
  border:none;
  background:transparent;
  color:white;
  cursor:pointer;
  -webkit-app-region:no-drag;
}
.window-btn:hover { background:rgba(255,255,255,0.2); }
.close-btn:hover { background:#e81123; }

.sidebar {
  position:absolute;
  left:0; top:35px;
  width:220px;
  height:calc(100% - 35px);
  background:rgba(0,0,0,0.85);
  backdrop-filter:blur(15px);
  display:flex;
  flex-direction:column;
  transition: width 0.3s ease;
}
.sidebar.collapsed { width:60px; }

.hamburger {
  padding:20px;
  background:none;
  border:none;
  color:white;
  font-size:20px;
  text-align:left;
  cursor:pointer;
}

.category-btn {
  background:none;
  border:none;
  color:white;
  padding:15px 20px;
  text-align:left;
  cursor:pointer;
}
.category-btn:hover { background:rgba(255,255,255,0.1); }
.sidebar.collapsed .category-text { display:none; }

.content-area {
  margin-left:220px;
  height:calc(100% - 35px);
  padding:40px;
  transition: margin-left 0.3s ease;
}
.content-area.shifted { margin-left:60px; }

.apps-grid {
  display:grid;
  grid-template-columns:repeat(auto-fill,minmax(180px,1fr));
  gap:25px;
}

.app-card {
  background:rgba(0,0,0,0.5);
  padding:30px;
  text-align:center;
  border-radius:12px;
  cursor:pointer;
  transition:0.3s ease;
}
.app-card:hover {
  transform:translateY(-5px);
  background:rgba(255,255,255,0.15);
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
  <div id="category-list"></div>
</div>

<div class="content-area" id="content-area">
  <div class="apps-grid" id="apps-grid"></div>
</div>

<script src="AppLauncher.js"></script>
</body>
</html>
EOF

# ----------------------------------
# categoryService.js
# ----------------------------------
cat > src/services/categoryService.js << 'EOF'
const fs = require("fs");
const path = require("path");

const assetsPath = path.join(__dirname, "..", "..", "assets");

function getCategories() {
  return fs.readdirSync(assetsPath, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => {
      const config = JSON.parse(
        fs.readFileSync(path.join(assetsPath, d.name, "config.json"))
      );
      return {
        name: d.name,
        wallpaper: path.join(assetsPath, d.name, "wallpaper.png"),
        apps: config.apps
      };
    });
}

module.exports = { getCategories };
EOF

# ----------------------------------
# AppLauncher.js
# ----------------------------------
cat > src/AppLauncher.js << 'EOF'
const { exec } = require("child_process");
const { ipcRenderer } = require("electron");
const { getCategories } = require("./services/categoryService");

const categories = getCategories();
const categoryList = document.getElementById("category-list");
const appsGrid = document.getElementById("apps-grid");
const sidebar = document.getElementById("sidebar");
const contentArea = document.getElementById("content-area");

function run(cmd) { exec(cmd); }

function handleApp(app) {
  if (app.type === "flatpak") {
    exec(`flatpak info ${app.id}`, (err) => {
      if (err) {
        run(`flatpak install flathub ${app.id} -y`);
        setTimeout(() => run(`flatpak run ${app.id}`), 4000);
      } else {
        run(`flatpak run ${app.id}`);
      }
    });
  }

  if (app.type === "bash") run(`bash ${app.script}`);
  if (app.type === "binary") run(app.cmd);
}

function loadCategory(category) {
  const imgPath = category.wallpaper.replace(/\\/g, "/");
  document.body.style.backgroundImage =
    `linear-gradient(rgba(0,0,0,0.4), rgba(0,0,0,0.4)), url('file://${imgPath}')`;

  appsGrid.innerHTML = "";

  category.apps.forEach(app => {
    const card = document.createElement("div");
    card.className = "app-card";
    card.innerHTML = `<div>${app.name}</div>`;

    card.onclick = () => handleApp(app);

    card.oncontextmenu = (e) => {
      e.preventDefault();
      ipcRenderer.send("context-menu-extended", app);
    };

    appsGrid.appendChild(card);
  });
}

categories.forEach(cat => {
  const btn = document.createElement("button");
  btn.className = "category-btn";
  btn.innerHTML = `<span class="category-text">${cat.name}</span>`;
  btn.onclick = () => loadCategory(cat);
  categoryList.appendChild(btn);
});

window.toggleSidebar = () => {
  sidebar.classList.toggle("collapsed");
  contentArea.classList.toggle("shifted");
};

window.minimize = () => ipcRenderer.send("minimize");
window.toggleMax = () => ipcRenderer.send("toggle-maximize");
window.closeApp = () => ipcRenderer.send("close");

ipcRenderer.on("max-state", (e, isMax) => {
  document.getElementById("maxBtn").innerText = isMax ? "❐" : "▢";
});

if (categories.length > 0) loadCategory(categories[0]);
EOF

# ----------------------------------
# Config Files (2 apps only)
# ----------------------------------
for dir in Games Dev Utilities; do
cat > assets/$dir/config.json << 'EOF'
{
  "apps": [
    {
      "name": "Tally",
      "type": "flatpak",
      "id": "ca.vlacroix.Tally",
      "website": "https://flathub.org/en/apps/ca.vlacroix.Tally"
    },
    {
      "name": "Marknote",
      "type": "flatpak",
      "id": "org.kde.marknote",
      "website": "https://flathub.org/en/apps/org.kde.marknote"
    }
  ]
}
EOF
done

touch assets/Games/wallpaper.png
touch assets/Dev/wallpaper.png
touch assets/Utilities/wallpaper.png

echo "✅ Build Complete — Launching..."
npm start