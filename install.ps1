# ─────────────────────────────────────────────────────────────────────────────
# Beatrice — One-paste installer for Windows (PowerShell)
# Works on freshly formatted machines with no dev tools installed.
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$REPO_URL        = if ($env:BEATRICE_REPO_URL) { $env:BEATRICE_REPO_URL } else { "https://github.com/lovegold120221-dot/turbo-dollop.git" }
$REPO_BRANCH     = if ($env:BEATRICE_BRANCH) { $env:BEATRICE_BRANCH } else { "main" }
$INSTALL_DIR     = if ($env:BEATRICE_INSTALL_DIR) { $env:BEATRICE_INSTALL_DIR } else { "$env:USERPROFILE\beatrice" }
$NODE_VERSION    = "22"
$PYTHON_VERSION  = "3.11"

function Write-Step($msg)  { Write-Host "`n▶ $msg" -ForegroundColor Cyan }
function Write-OK($msg)    { Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "⚠ $msg" -ForegroundColor Yellow }
function Write-Fail($msg)  { Write-Host "✗ $msg" -ForegroundColor Red; exit 1 }

# ─── Check admin rights ───────────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Fail "Run PowerShell as Administrator to install all dependencies." }

# ─── STEP 1/14: Install Chocolatey if missing ────────────────────────────────
Write-Step "── STEP 1/14: Chocolatey package manager ──"
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
Write-OK "Chocolatey ready"

# ─── STEP 2/14: System packages (Git, Python, Node.js, build tools) ─────────
Write-Step "── STEP 2/14: Git, Python 3.11, Node.js, Visual Studio Build Tools ──"
choco install -y git python311 nodejs-lts visualstudio2022buildtools postgresql ffmpeg 2>&1 | Out-Host
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

foreach ($cmd in @("git", "python", "node", "npm")) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Write-Fail "$cmd is not available." }
}
Write-OK "Node.js $(node -v), Python $(python --version), Git $(git --version)"

# ─── STEP 3/14: Docker Desktop (container runtime + compose) ───────────────
Write-Step "── STEP 3/14: Docker Desktop ──"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  choco install -y docker-desktop 2>&1 | Out-Host
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  Write-Warn "Docker Desktop installed — restart your shell so docker CLI is on PATH"
} else {
  Write-OK "Docker already installed: $(docker --version)"
}

# ─── STEP 4/14: PostgreSQL client for Supabase migrations ───────────────────
Write-Step "── STEP 4/14: PostgreSQL client ──"
if (Get-Command psql -ErrorAction SilentlyContinue) {
  Write-OK "PostgreSQL client already present"
} else {
  if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Warn "psql not on PATH. It was installed via Chocolatey — restart your shell if needed."
  }
}

# ─── STEP 5/14: ffmpeg for media transcoding ───────────────────────────────
Write-Step "── STEP 5/14: ffmpeg ──"
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
  Write-OK "ffmpeg already present: $(ffmpeg -version 2>$null | Select-Object -First 1)"
} else {
  Write-Warn "ffmpeg not detected — reinstall your shell or check PATH"
}

# ─── STEP 6/14: Clone or update repository ──────────────────────────────────
Write-Step "── STEP 6/14: Clone or update repository ──"
if (Test-Path "$INSTALL_DIR\.git") {
  Push-Location $INSTALL_DIR
  git fetch --all
  git reset --hard "origin/$REPO_BRANCH"
  git clean -fdx
  Pop-Location
} else {
  git clone --branch $REPO_BRANCH --depth 1 $REPO_URL $INSTALL_DIR
}
Write-OK "Repository ready at $INSTALL_DIR"

# ─── STEP 7/14: npm dependencies ─────────────────────────────────────────────
Write-Step "── STEP 7/14: npm dependencies ──"
Push-Location $INSTALL_DIR
npm ci --include=dev
Write-OK "npm dependencies installed"

# ─── STEP 8/14: Python venv + Playwright/Chromium ───────────────────────────
Write-Step "── STEP 8/14: Python venv + Playwright/Chromium ──"
if (-not (Test-Path ".venv")) { python -m venv .venv }
& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
& .\.venv\Scripts\python.exe -m playwright install chromium 2>$null
Write-OK "Python dependencies installed"

# ─── STEP 9/14: Ollama (Hermes 3 model) ──────────────────────────────────────
Write-Step "── STEP 9/14: Ollama ──"
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
  Write-Step "Downloading Ollama for Windows"
  $ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
  $ollamaInstaller = "$env:TEMP\OllamaSetup.exe"
  Invoke-WebRequest -Uri $ollamaUrl -OutFile $ollamaInstaller -UseBasicParsing
  Start-Process -FilePath $ollamaInstaller -ArgumentList "/S" -Wait
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  Write-Warn "Ollama installer ran silently. You may need to start the Ollama app once."
} else {
  Write-OK "Ollama already installed: $(ollama --version)"
}

if (Get-Command ollama -ErrorAction SilentlyContinue) {
  Write-Step "Pulling Hermes 3 model"
  try { ollama pull hermes3:latest } catch { Write-Warn "Failed to pull hermes3 — Beatrice will fall back to other agents" }
}

# ─── STEP 10/14: OpenCode CLI (terminal sub-agent) ───────────────────────────
Write-Step "── STEP 10/14: OpenCode CLI ──"
$opencodeBin = "$env:USERPROFILE\.opencode\bin\opencode.exe"
if (-not (Test-Path $opencodeBin)) {
  Write-Step "Downloading OpenCode CLI"
  irm https://opencode.ai/install.ps1 | iex
  $env:Path = $env:USERPROFILE + "\.opencode\bin;" + $env:Path
} else {
  Write-OK "OpenCode CLI already installed"
}

# ─── STEP 11/14: OpenCode skills from eburonhub-skills ───────────────────────
Write-Step "── STEP 11/14: OpenCode skills from eburonhub-skills ──"
$skillsDir = "$INSTALL_DIR\.opencode\skills"
if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }
$eburonhubSkills = "$skillsDir\eburonhub-skills"
if (Test-Path $eburonhubSkills) {
  Push-Location $eburonhubSkills
  git pull --ff-only
  Pop-Location
} else {
  git clone --depth 1 https://github.com/lovegold120221-dot/eburonhub-skills.git $eburonhubSkills
}
if (Test-Path "$eburonhubSkills\skills") {
  Get-ChildItem "$eburonhubSkills\skills" | ForEach-Object {
    $link = "$skillsDir\$($_.Name)"
    if (-not (Test-Path $link)) { New-Item -ItemType SymbolicLink -Path $link -Target $_.FullName -Force | Out-Null }
  }
}
Write-OK "eburonhub-skills installed"

# ─── STEP 12/14: Supabase CLI (self-hosted Supabase) ────────────────────────
Write-Step "── STEP 12/14: Supabase CLI ──"
if (Get-Command supabase -ErrorAction SilentlyContinue) {
  Write-OK "Supabase CLI already present"
} else {
  Write-Step "Installing Supabase CLI via npm"
  npm install -g supabase 2>&1 | Out-Host
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
  if (Get-Command supabase -ErrorAction SilentlyContinue) { Write-OK "Supabase CLI installed" } else { Write-Warn "Supabase CLI install reported warnings" }
}

# ─── STEP 13/14: PM2 + sandbox dirs + .env + WhatsApp Cloud + build ────────
Write-Step "── STEP 13/14: PM2 + sandbox dirs + .env + WhatsApp Cloud + build ──"
if (-not (Get-Command pm2 -ErrorAction SilentlyContinue)) {
  npm install -g pm2
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
Write-OK "PM2 installed"

$dataDirs = @("$env:ProgramData\beatrice\baileys", "$env:ProgramData\beatrice\beatrice-workspace", "$env:ProgramData\beatrice\wa-media", "$env:ProgramData\beatrice\workspace", "$INSTALL_DIR\baileys_auth")
foreach ($d in $dataDirs) {
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}
Write-OK "Sandbox data directories ready"

if (-not (Test-Path ".env")) {
  if (Test-Path ".env.whatsapp") {
    Copy-Item .env.whatsapp .env
    Write-OK "Copied .env.whatsapp to .env"
  } elseif (Test-Path ".env.example") {
    Copy-Item .env.example .env
    Write-Warn "Created .env from .env.example — fill in your API keys before running"
  } else {
    Write-Fail "No .env template found"
  }
}
if (-not (Test-Path ".env.local") -and (Test-Path ".env.local.example")) {
  Copy-Item .env.local.example .env.local
}

# Add WhatsApp Cloud API env placeholders if missing
$waCloudMarker = "WHATSAPP_CLOUD_PHONE_NUMBER_ID"
if (-not (Select-String -Path ".env" -Pattern $waCloudMarker -Quiet)) {
  Add-Content -Path ".env" -Value @"

# ── WhatsApp Cloud API (optional — alternative to Baileys) ──
# WHATSAPP_CLOUD_PHONE_NUMBER_ID=
# WHATSAPP_CLOUD_ACCESS_TOKEN=
# WHATSAPP_CLOUD_BUSINESS_ACCOUNT_ID=
# WHATSAPP_CLOUD_WEBHOOK_VERIFY_TOKEN=
"@
  Write-OK "Added WhatsApp Cloud API env placeholders to .env"
}

Write-Step "Building frontend (Vite production build)"
npm run build
Write-OK "Frontend built to dist/"

$startScript = @"
@echo off
cd /d "%~dp0"
set NODE_ENV=production
set PORT=4200
set PUPPETEER_SKIP_DOWNLOAD=true
set PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
set PLAYWRIGHT_BROWSERS_PATH=%~dp0.venv\ms-playwright
node_modules\.bin\tsx server\index.ts
"@
Set-Content -Path "start.bat" -Value $startScript
Write-OK "Created start.bat launcher"

Pop-Location

# ─── STEP 14/14: Verify installation ────────────────────────────────────────
Write-Step "── STEP 14/14: Verify installation ──"
$failed = 0
foreach ($cmd in @("node", "npm", "python", "git", "docker", "psql", "ffmpeg", "ollama", "supabase", "pm2")) {
  if (Get-Command $cmd -ErrorAction SilentlyContinue) {
    Write-OK "$cmd: present"
  } else {
    Write-Warn "MISSING: $cmd"
    $failed++
  }
}
if (Test-Path "$INSTALL_DIR\.venv") { Write-OK "Python venv present" } else { Write-Warn "Python venv missing"; $failed++ }
if (Test-Path "$INSTALL_DIR\dist") { Write-OK "Frontend dist/ present" } else { Write-Warn "Frontend dist/ missing"; $failed++ }
if (Test-Path "$INSTALL_DIR\.opencode\skills\eburonhub-skills") { Write-OK "eburonhub-skills present" } else { Write-Warn "eburonhub-skills missing"; $failed++ }
if (Test-Path "$env:ProgramData\beatrice\baileys") { Write-OK "Sandbox data dirs present" } else { Write-Warn "Sandbox data dirs missing"; $failed++ }
if ($failed -gt 0) { Write-Warn "$failed warning(s) — review above. Beatrice may still run." } else { Write-OK "All required components verified" }

# ─── Done ────────────────────────────────────────────────────────────────────
Write-Host "`n`n"
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Beatrice is live at http://localhost:4200  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  • Open http://localhost:4200 in your browser" -ForegroundColor White
Write-Host "  • Edit $INSTALL_DIR\.env to add API keys (Supabase, Firebase, Eburon, Google OAuth)" -ForegroundColor White
Write-Host "  • Restart after editing env:  cd $INSTALL_DIR && start.bat" -ForegroundColor White
Write-Host "  • Ollama models:             ollama list" -ForegroundColor White
Write-Host "  • OpenCode skills:           $INSTALL_DIR\.opencode\skills\" -ForegroundColor White
Write-Host "  • Docker:                    docker --version" -ForegroundColor White
Write-Host "  • Supabase (self-hosted):    cd $INSTALL_DIR; supabase start" -ForegroundColor White
Write-Host "  • ffmpeg:                    ffmpeg -version" -ForegroundColor White
Write-Host ""
