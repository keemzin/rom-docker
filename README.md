# 🗡️ Ragnarok M: Eternal Love - Docker Server Stack

Containerized RO server from this subforum:  
https://forum.ragezone.com/threads/ragnarok-m-english-patch-99-rom-mobile-korea-cn-2x-apk-vm-video-tutorial.1250510/

Special thanks to [SkyArc](https://forum.ragezone.com/members/skyarc.2000434324/).

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

## ✨ Custom Features Overview

* **⚡ Quick Quest Teleport**: Click any active quest in the HUD or Quest Manual to instantly blink to the objective with **0 loading screens** (includes smart cross-map pathfinding and local NPC priority).
* **🛍️ Free Equipment Shop (Port 81)**: Web portal store at `/equipment_shop` allowing players to browse and claim **3,580+ items for free ($0)** delivered straight to their in-game mailbox in real-time. Includes instant live search and translation aliases.
* **🚀 Fast 70ms Web Portal**: Optimized PHP OPCache and Laravel route/config caching for instant, snappy page loads.
* **🔌 Docker Networking & Resilience**: Pre-configured internal bridges and friendly offline status handling.

*(For technical implementation details and patch history, see [`CHANGES.md`](./CHANGES.md).)*

---

## 🚀 Quick Start

### 1. Download & Extract Assets
Download the pre-configured asset archives from Hugging Face: [**`huggingface.co/datasets/johnsdoes/docker-rom`**](https://huggingface.co/datasets/johnsdoes/docker-rom):
- **`server.rar`** (or `server_code.tar.gz`) -> Extract into `./server/`
- **`wwwroot.rar`** (or `web_wwwroot.tar.gz`) -> Extract into `./web/wwwroot/`
- **`init.rar`** (or `db_init.tar.gz`) -> Extract into `./db/init/`
- **`rom.apk`** -> Install on Android or drag-and-drop into LDPlayer!

### 2. Start the Server Stack
```bash
docker compose up -d
```
> Docker will launch MySQL, Redis, the Web Portal (port 81), and all 21 game server processes.  
> Wait ~45–60 seconds on initial startup for `SceneServer1` to finish loading maps and NPCs.  
> Check status with:
> ```bash
> docker exec rom-game tail -n 20 /RoServercode/bin/Release/log/xd/r2_s1/SuperServer.log
> ```
> *(When you see `[初始化完成],state: 3`, the server is ready for client logins!)*

### 3. Connect & Play
* Install `client/rom.apk` on your Android device or drag-and-drop into LDPlayer.
* Open the game, register an account on `http://<SERVER_IP>:81`, and connect!

---

---

## 🛍️ Equipment Shop Configuration (Port 81)

The web portal on port 81 includes an **Equipment Shop** allowing players to browse 3,580+ items and claim gear for free directly to their in-game mailbox.

### Enable / Disable Store

#### Method 1: Via `.env` (Standard)
In `web/wwwroot/game/.env`:
```env
EQUIPMENT_SHOP_ENABLED=true   # Store is active (default)
# or
EQUIPMENT_SHOP_ENABLED=false  # Store is disabled
```

* **When `false`**:
  * The "Equipment Shop" and "Free Equipment" links automatically disappear from the navigation bar.
  * Direct access to `/equipment_shop` or any claim attempts will safely redirect back with:  
    `"The Equipment Shop is currently closed for maintenance."`
* **After editing `.env`**, refresh the configuration cache:
  ```powershell
  docker exec rom-web php /www/wwwroot/game/artisan config:cache
  ```

#### Method 2: Instant File Flag (0-Second Toggle)
To toggle the store instantly without editing files or running commands:
* **To Disable**: Create an empty file at `web/wwwroot/game/storage/equipment_shop_disabled`
* **To Re-Enable**: Delete `web/wwwroot/game/storage/equipment_shop_disabled`

---

## 🛠️ Building & Pushing Base Images (`johnsdoes`)

```bash
# Build base images
docker build -t johnsdoes/rom-game:base ./game
docker build -t johnsdoes/rom-web:base ./web

# Push to Docker Hub
docker push johnsdoes/rom-game:base
docker push johnsdoes/rom-web:base
```

---

## 📁 Backup & Asset Distribution

Pre-built archives and the patched APK are hosted on Hugging Face:  
🔗 [**`huggingface.co/datasets/johnsdoes/docker-rom`**](https://huggingface.co/datasets/johnsdoes/docker-rom)

- **`server.rar`** (1.33 GB): 21 C++ game server binaries, maps, navmeshes, and Lua scripts.
- **`wwwroot.rar`** (156 MB): Web portal, registration engine, equipment catalog, and GM tools.
- **`init.rar`** (10.8 MB): Seed database dumps (`ro_global`, `ro_xd_r2`).
- **`rom.apk`** (1.54 GB): Pre-patched Android game client with the Quest Teleportation system baked in.

---

## 🔍 Useful Commands

| Action | Command |
| :--- | :--- |
| **Stop Entire Stack (Graceful)** | `docker compose down` |
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
