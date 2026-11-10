# 🗡️ Ragnarok M: Eternal Love - Docker Server Stack

Containerized RO server from this subforum:  
https://forum.ragezone.com/threads/ragnarok-m-english-patch-99-rom-mobile-korea-cn-2x-apk-vm-video-tutorial.1250510/

Special thanks to [SkyArc](https://forum.ragezone.com/members/skyarc.2000434324/).

📦 **Download Server Files & APK:**  
👉 [**huggingface.co/datasets/johnsdoes/docker-rom/tree/main**](https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main)

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
* **🐱 Free In-Game Big Cat Store**: Fixed for 2026+ and patched for instant, free ($0) in-game purchasing — click any Big Cat Coin pack, Zeny pack, Monthly VIP card, EP card, or Lucky Bag to receive it immediately in real-time without third-party payment SDKs.
* **🔄 Automatic OTA Client Hot-Patching (`patch.zip`)**: Drop any updated `patch.zip` into `web/wwwroot/127.0.0.1/res/patch.zip` and the web server automatically calculates the new MD5/size, bumps the patch version, and pushes the update to players on their next game launch (no APK reinstall required).
* **🛍️ Free Equipment Shop (Port 81)**: Web portal store at `/equipment_shop` allowing players to browse and claim **3,580+ items for free ($0)** delivered straight to their in-game mailbox in real-time. Includes instant live search and translation aliases.
* **🚀 Fast 70ms Web Portal**: Optimized PHP OPCache and Laravel route/config caching for instant, snappy page loads.
* **🔌 Docker Networking & Resilience**: Pre-configured internal bridges and friendly offline status handling.

*(For technical implementation details and patch history, see [`CHANGES.md`](./CHANGES.md).)*

---

## 🚀 Quick Start

### 1. Download & Extract Assets
Download the pre-configured asset archives from Hugging Face: [**`huggingface.co/datasets/johnsdoes/docker-rom/tree/main`**](https://huggingface.co/datasets/johnsdoes/docker-rom/tree/main):
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

## 🔄 Applying Client Hot-Patch Updates (`patch.zip` / `patch2.zip` ...)

You do **not** need to reinstall the APK or restart Docker to push client script/config updates:
1. Drop your patch archive(s) into:
   ```text
   web/wwwroot/127.0.0.1/res/
   ```
   - **Option A (Multiple Incremental Patches):** Leave `patch.zip` (`229110`) in place and drop new patch zips beside it (e.g., `patch2.zip`, `patch3.zip`).
     - Players who already downloaded `patch.zip` will **only** download the new `patch2.zip`.
     - Brand-new players will automatically download `patch.zip` and `patch2.zip` in chronological order (`1/2`, `2/2`).
   - **Option B (Single Cumulative Patch):** Overwrite `patch.zip` directly.
2. `version.php` and `Version.php` automatically scan all `*.zip` files in `res/`, calculate their MD5 and byte size, increment version numbers in `patch.meta.json`, and serve any new patches to the Android client on its next startup.

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

## 💾 Database Backup & Restore

The MySQL container (`rom-mysql`, default root password `123456`) uses two databases:
- **`ro_global`**: Accounts, server list, and global state
- **`ro_xd_r2`**: Characters, inventory, guilds, and Exchange/Trade data

> **Note for Windows PowerShell:** Character and inventory data are stored as binary Protobuf `BLOB`s (`charbase`, `accbase`, etc.). Always use `--hex-blob` and `-r /tmp/...` with `docker cp` instead of PowerShell `>` redirection (which re-encodes output as UTF-16 and corrupts binary blobs).

### 1. Backup Database

**Option A: Full Backup (`ro_global` + `ro_xd_r2`) into a Single File**
```powershell
# Dump both databases safely inside the container
docker exec rom-mysql mysqldump -uroot -p123456 --hex-blob --single-transaction --routines --triggers --databases ro_global ro_xd_r2 -r /tmp/rom_backup.sql

# Copy the backup file to your host machine
docker cp rom-mysql:/tmp/rom_backup.sql ./rom_backup.sql
```

**Option B: Separate Backups into `db/init/` (Same Structure as `init.rar`)**
```powershell
docker exec rom-mysql mysqldump -uroot -p123456 --hex-blob --single-transaction --databases ro_global -r /tmp/01_ro_global.sql
docker exec rom-mysql mysqldump -uroot -p123456 --hex-blob --single-transaction --databases ro_xd_r2 -r /tmp/02_ro_xd_r2.sql

docker cp rom-mysql:/tmp/01_ro_global.sql ./db/init/01_ro_global.sql
docker cp rom-mysql:/tmp/02_ro_xd_r2.sql ./db/init/02_ro_xd_r2.sql
```

### 2. Restore Database

**Restore from `rom_backup.sql`:**
```powershell
# 1. Stop game server so it does not write while restoring
docker stop rom-game

# 2. Copy the SQL file into the container and import
docker cp ./rom_backup.sql rom-mysql:/tmp/rom_backup.sql
docker exec rom-mysql sh -c "mysql -uroot -p123456 < /tmp/rom_backup.sql"

# 3. Start game server again
docker start rom-game
```

**Restore from `db/init/01_ro_global.sql` & `db/init/02_ro_xd_r2.sql`:**
```powershell
docker stop rom-game
docker exec rom-mysql sh -c "mysql -uroot -p123456 ro_global < /docker-entrypoint-initdb.d/01_ro_global.sql"
docker exec rom-mysql sh -c "mysql -uroot -p123456 ro_xd_r2 < /docker-entrypoint-initdb.d/02_ro_xd_r2.sql"
docker start rom-game
```

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
