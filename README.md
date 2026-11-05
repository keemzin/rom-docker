# 🗡️ Ragnarok M: Eternal Love - Docker Server Stack

A containerized, portable Docker environment for running the complete Ragnarok M: Eternal Love private server stack anywhere (Ubuntu, Debian, CentOS, AlmaLinux, Windows, or macOS with Docker Desktop).

Official Docker Hub Registry: [hub.docker.com/r/johnsdoes](https://hub.docker.com/r/johnsdoes)  
🩺 **Architecture & Troubleshooting Guide for AI Agents & Developers:** [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md)

---

## 🏛️ Stack Architecture

```
                    +-----------------------------+
                    |       Incoming Traffic      |
                    +--------------+--------------+
                                   |
         +-------------------------+-------------------------+
         |                         |                         |
         v                         v                         v
+-----------------+       +-----------------+       +-----------------+
|   rom-web       |       |   rom-game      |       |   rom-mysql     |
|   (Ports 80/81/ |       |   (Ports 7080-  |       |   (Port 3306)   |
|    5556)        |       |    7082, 7050,  |       |   ro_global     |
| Nginx + PHP 8.2 |       |    6091, etc.)  |       |   ro_xd_r2      |
| GM & Reg Portal |       | 21 C++ Servers  |       +--------+--------+
+-----------------+       | + Trade Server  |                ^
         |                +--------+--------+                |
         |                         | (socat bridge)          |
         +-------------------------+-------------------------+
                                   |
                          +--------v--------+
                          |   rom-redis     |
                          |   (Port 6379)   |
                          |   Session/Cache |
                          +-----------------+
```

### Included Services:
1. **`rom-mysql` (MySQL 5.7)**: Configured with `sql_mode=""`, `max_allowed_packet=512M`, and `innodb_buffer_pool_size=1G`.
2. **`rom-redis` (Redis 6-alpine)**: Fast in-memory cache for game sessions and trade manager.
3. **`rom-web` (Nginx + PHP 8.2 FPM + OPcache)**: Optimized web portal (Port 81), GM Tools (Port 5556), and HTTP gateway (Port 80) with 70ms response time.
4. **`rom-game` (CentOS 7 Base)**: Runs the 21 C++ game cluster binaries (`SuperServer`, `SceneServer1-2`, `GateServer1-3`, `RecordServer`, etc.) and the PHP 7.0 Swoole Trade Server daemon (`6091`).

---

## 🚀 Choose Your Mode: Full vs. Base

| Mode | Target Audience | What is Baked in Docker Hub? | How It Runs |
| :--- | :--- | :--- | :--- |
| **🎮 Full Mode** | **Players & Server Hosts** | All 21 servers, web portal, & database tables are pre-baked into `johnsdoes/rom-*:full` | **1-Click**: `docker compose -f docker-compose.full.yml up -d` (No zip files needed!) |
| **🛠️ Base Mode** | **Developers & Modders** | Runtime environments (PHP, GCC, libs, socat) baked into `johnsdoes/rom-*:base` | **Hot-Reload**: Local `./server` and `./web/wwwroot` mounted into container so edits apply instantly. |

---

### Option A: 1-Click Play (Full Mode)

No manual file downloads or code extraction required:

```bash
# 1. Start the complete stack
docker compose -f docker-compose.full.yml up -d

# 2. Wait ~45-60 seconds for SceneServer1 to finish loading maps and NPCs
# Check status:
docker exec rom-game tail -n 20 /RoServercode/bin/Release/log/xd/r2_s1/SuperServer.log
```
*When you see `[初始化完成],state: 3`, you can open the APK and connect!*

---

### Option B: Developer Mode (Base Mode)

For modders editing Lua scripts, drop tables, or C++ server configs:

```bash
# 1. Download large asset archives (from BACKUP/ or Hugging Face):
#    - server_code.tar.gz -> extract into ./server/
#    - web_wwwroot.tar.gz -> extract into ./web/wwwroot/
#    - db_init.tar.gz     -> extract into ./db/init/

# 2. Start Developer Mode
docker compose up -d

# 3. Edit any file in ./server/ or ./web/wwwroot/ on your host PC!
# 4. Restart only the game servers to apply changes:
docker exec -it rom-game bash -c "cd /RoServercode/bin/Release && ./restart s1"
```

---

## 🛠️ Building & Pushing to Docker Hub (`johnsdoes`)

### 1. Build Base Images (Developer Runtime)
```bash
# Build base images
docker build -t johnsdoes/rom-game:base ./game
docker build -t johnsdoes/rom-web:base ./web

# Push to Docker Hub
docker push johnsdoes/rom-game:base
docker push johnsdoes/rom-web:base
```

### 2. Build Full Images (All-in-One Play)
```bash
# Build full images with pre-baked code and DB seeds
docker build -f game/Dockerfile.full -t johnsdoes/rom-game:full .
docker build -f web/Dockerfile.full -t johnsdoes/rom-web:full .
docker build -f db/Dockerfile.full -t johnsdoes/rom-db:full .

# Push to Docker Hub
docker push johnsdoes/rom-game:full
docker push johnsdoes/rom-web:full
docker push johnsdoes/rom-db:full
```

---

## 📁 Backup & Hugging Face Assets

Large binary archives are preserved inside [`BACKUP/`](file:///V:/ROM/docker-rom/BACKUP/):
- **`BACKUP/server_code.tar.gz`**: 21 C++ binaries, maps, navmeshes, and Lua scripts.
- **`BACKUP/web_wwwroot.tar.gz`**: Web portal, registration engine, and GM tools.
- **`BACKUP/db_init.tar.gz`**: Seed database dumps (`ro_global`, `ro_xd_r2`).

To distribute via Hugging Face:
```bash
# Upload BACKUP/*.tar.gz to your Hugging Face dataset repo:
huggingface-cli upload johnsdoes/rom-server-assets ./BACKUP/ .
```

---

## 🔍 Useful Commands

| Action | Command |
| :--- | :--- |
| **Stop Entire Stack (Graceful)** | `docker compose down` *(or `-f docker-compose.full.yml down`)* |
| **Start Stack** | `docker compose up -d` |
| **Quick-Restart Game Servers** | `docker exec -it rom-game bash -c "cd /RoServercode/bin/Release && ./restart s1"` |
| **Check Active Processes (21 Servers)** | `docker exec rom-game bash -c "ps -u root \| grep Server"` |
| **Check Redis Gateways** | `docker exec rom-redis redis-cli hgetall "10002:gateinfo:100020001:default:data"` |
| **View SuperServer Cluster Log** | `docker exec rom-game tail -n 25 /RoServercode/bin/Release/log/xd/r2_s1/SuperServer.log` |
| **View Client Gateway Log** | `docker exec rom-game tail -n 25 /RoServercode/bin/Release/log/proxy/1/ProxyServer.log` |

---

## 🛡️ Firewall & Port Forwarding

If hosting for players over LAN or VPS, forward these ports:

| Port | Protocol | Purpose |
| :---: | :---: | :--- |
| **`80`** | TCP | GM Web Tools / HTTP |
| **`81`** | TCP | Player Registration Portal |
| **`5556`** | TCP | Web API Gateway |
| **`7050`** | TCP | SuperServer |
| **`7080 - 7082`** | TCP | GateServer 1, 2, 3 (Client Gateway) |
| **`6091` / `26091`** | TCP | Exchange (Trade Server) |
| **`12053` / `14288`** | TCP | Proxy Services |
