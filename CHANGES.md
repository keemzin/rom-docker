# Changelog: Quest Teleportation System ("Option A")

## 1. Overview & Mechanics
This feature adds an intelligent one-click teleportation option to the quest navigation system:
- **Trigger**: Clicking on any active quest in the HUD Quest Tracker or the "Go" button in the Quest Manual.
- **Confirmation Dialog**: Displays a prompt (*"Quest Teleport"*) offering two choices:
  - **Teleport**: Instantly moves the character with **0 loading screens**.
  - **Walk**: Cancels teleport and executes the game's default auto-walk and tracking direction marker.
- **Behavior by Map Location & Target Priority**:
  - **Local NPC Priority**: Prioritizes detecting if the target NPC/monster is already in the player's current scene (via `NSceneNpcProxy` or `Game.MapManager:GetNPCPointMap()`). Even if `questData.map` indicates a subsequent destination map (common for cross-map or travel quests), talking to a gatekeeper or NPC standing beside the gate will blink directly to the NPC with **0 loading screens** instead of warping to the gate.
  - **Same Map Coordinate**: If the objective is on the same map, blinks directly to the target coordinate and automatically executes the quest conversation/action. If already within 6 meters, skips dialog and speaks directly.
  - **Different Map Gate Pathfinder**: If and only if the NPC/objective does not exist on the current map, calculates the shortest path exit portal on the current map leading toward the destination and blinks the player in front of the gate.

---

## 2. Server-Side Modifications

### Files Modified:
- `server/bin/Release/CommonConfig.lua`
- `server/Config/CommonConfig.lua`

### What Was Changed:
Client-side teleport packets utilize the server-side GM command `gocity mapid=%d x=%.2f y=%.2f z=%.2f`.
In `server/SceneServer/SceneUserCmd.cpp`, this command is protected by `CommonConfig::isInTFGMWhiteList(this->accid)`:
```cpp
if (CommonConfig::isInTFGMWhiteList(this->accid) == true)
{
  bool bSuccess = GMCommandRuler::getMe().execute(this, rev.command());
  ...
}
```
To whitelist all players dynamically on server startup without requiring C++ compilation, `CommonConfig.lua` was updated to populate `TFGMWhiteList` with account IDs from `100000` to `200000`:
```lua
CommonConfig.TFGMWhiteList = {}
for i = 100000, 200000 do
  CommonConfig.TFGMWhiteList[#CommonConfig.TFGMWhiteList + 1] = i
end
```

### Server Cluster Restart Command:
```bash
docker exec rom-game bash -c "cd /RoServercode/bin/Release && ./restart s1"
```

---

## 3. Client-Side Modifications

### Target Unity AssetBundle:
- `framework.unity3d` (located inside `assets/assets32.zip` in the APK, and hot-patchable under `/sdcard/Android/data/com.rom.reborn/files/Android/resources/script2/framework.unity3d`).

### Script 1: `MainViewTaskQuestPage.lua` (HUD Quest Tracker)
- **Target Function**: `MainViewTaskQuestPage:questCellClick(cellCtrl)`
- **Logic Added**:
  1. Resolves destination coordinates (`questData.pos`, `Game.MapManager:GetNPCPointMap()`, or `FunctionQuestDisChecker`).
  2. If the quest is on another map, resolves the exit portal on the current map via `WorldTeleport.CreateOutterTeleportInfo` or `MapInnerTeleport[currentMapID].outter[targetMapID]`.
  3. Displays confirmation popup using `UIUtil.PopUpConfirmYesNoView`.
  4. Dispatches `ServiceGMProxy.Instance:Call("gocity mapid=... x=... y=... z=...")`.
  5. Updates quest direction effects and triggers quest interaction.

### Script 2: `QuestTraceCell.lua` (Quest Manual Tracker)
- **Target Function**: `QuestTraceCell:initView()` -> `TraceMark` click event.
- **Logic Added**:
  - Intercepts the "Go" trace button in the Quest Manual and routes through the same coordinate resolution and confirmation flow.

---

## 4. Encryption & APK Signing Specifications

### Lua Encryption Details:
- **Cipher**: DES in ECB mode (based on Richard Outerbridge `d3des.c` bit-reversed keys).
- **Header**: 8-byte magic string `czjzgqde` followed by a 4-byte unsigned integer (little-endian) representing the unencrypted byte length.
- **DES Key**: `bytes([64, 160, 144, 192, 96, 128, 0, 128])` (hex: `40 A0 90 C0 60 80 00 80`).
- **Padding**: `0x01` byte padding to 8-byte block boundaries.

### APK Re-signing:
- Modifying zip archives breaks Android's digital signature.
- Generated Keystore: `client/debug.keystore` (RSA 2048-bit, validity 10,000 days).
- Signed via `jarsigner`:
  ```powershell
  jarsigner -keystore "client\debug.keystore" -storepass android -keypass android -sigalg SHA256withRSA -digestalg SHA-256 "client\rom.apk" debug
  ```
- Result: Signed with valid `META-INF/MANIFEST.MF`, `META-INF/DEBUG.SF`, and `META-INF/DEBUG.RSA`.

---

## 5. Artifact & Deployment Locations

| Item | Path / Location | Purpose |
| :--- | :--- | :--- |
| **Original APK (Untouched)** | `V:\ROM\2-EXTRACT+VM\RO-M-LouLx\rom.apk` | Master untouched backup |
| **Signed Modded APK** | `client/rom.apk` | Complete standalone installable APK |
| **Hot-Patch Bundle** | `client/patch/Android/resources/script2/framework.unity3d` | Instant update file without reinstalling APK |
| **Debug Keystore** | `client/debug.keystore` | Keystore used to sign the client APK |
| **Server Whitelist Config** | `server/bin/Release/CommonConfig.lua` | Server-side GM permission config |
| **In-Game Override Path** | `/sdcard/Android/data/com.rom.reborn/files/Android/resources/script2/` | LDPlayer / Android directory for hot-patching |

---

## 6. How to Deploy Future Script Updates

### Option A: Instant Push to LDPlayer (No reinstall)
With LDPlayer running:
```powershell
& "V:\LDPlayer\LDPlayer9\adb.exe" push "client\patch\Android\resources\script2\framework.unity3d" "/sdcard/Android/data/com.rom.reborn/files/Android/resources/script2/framework.unity3d"
```

### Option B: Clean APK Install
1. Uninstall existing RO-M app on LDPlayer / mobile.
2. Drag & drop `client/rom.apk` into LDPlayer to install fresh.

---

## 7. Web Portal: Free Equipment Shop (Port 81)

### Overview:
Added a dedicated **Equipment Shop** to the Laravel web portal on port 81 (`/equipment_shop`), allowing players to select and claim any equipment in the game for **FREE ($0)** with real-time in-game mail delivery.

### Features:
1. **Catalog**: 3,582 equipment items with full **English names & descriptions** (sourced from `BACKUP/Table_Item.txt` + `Table_ItemType.txt` + `Table_Equip.txt`), categorized into:
   - Weapons (1,073: Swords, Spears, Staves, Bows, Katars, Daggers, Axes, Maces, Knuckles, Books, Instruments, Whips, Artifacts)
   - Off-hand & Shields (255: Shields, Orbs, Statues, Bracers, Bangles)
   - Armors (199)
   - Garments (114)
   - Footgears (111)
   - Accessories (126: Rings, Necklaces, Brooches, Gloves)
   - Headwear, Face, Mouth, Back & Tails (1,475: Headgears, Wings, Tails, Back items like Night Feather)
   - Mounts & Costumes (229: Mounts, Costumes)
2. **Smart Search & Aliases**: Supports searching by Name, ID, Category, Description, and community aliases (e.g. searching "moonlight feather" directly resolves to "Night Feather", and "chloe" finds both "Chloe Bow" and "Malang Snow Crab").
3. **Character Detection**: Queries `charbase` in `ro_xd_r2` for the logged-in user's characters and levels.
4. **Instant Delivery**: Sends items via `http://127.0.0.1/user/gmquery.php` -> TCP socket to SceneServer port `7080` (pure in-game mail packet).
5. **Offline Docker Fixes**:
   - `web/wwwroot/127.0.0.1/user/config.php`: Dynamic DNS resolution to `db` (MySQL) and `game` (SceneServer GM socket).
   - `web/wwwroot/game/.env`: Pointed `URL_SEND_ITEM_API` to `http://127.0.0.1`.

---

## 8. Web Portal: Performance Optimization & Responsiveness (Port 81)

### Overview:
Diagnosed and eliminated severe latency on the Port 81 Laravel web portal where requests previously took 14–16 seconds to respond, bringing response times down to **~70–100 milliseconds** (up to ~220x speedup).

### Root Causes:
1. **Docker on Windows Filesystem Stat Penalty**:
   - The web directory (`web/wwwroot`) is mounted from the Windows NTFS host filesystem into the Linux container.
   - Setting `opcache.revalidate_freq = 0` and `opcache.enable_file_override = 0` forced PHP-FPM to issue `stat()` system calls across the WSL2/VirtioFS bridge for every single PHP file (500+ files per request) on every HTTP request.
2. **Blocked Laravel Route Serialization**:
   - `routes/web.php` contained duplicate route names (`login` and `logout`), causing `php artisan route:cache` to crash with `LogicException: Another route has already been assigned name [login]`.
   - Without route and configuration caching, Laravel had to parse dozens of config files and re-register routes on every request.

### Optimizations Applied:
1. **PHP OPCache & Realpath Tuning (`web/php.ini`)**:
   - `opcache.revalidate_freq = 60`: Only rechecks script timestamps once every 60 seconds. Subsequent requests are executed 100% in-memory from bytecode.
   - `opcache.enable_file_override = 1`: Uses OPCache to resolve `file_exists()`, `is_file()`, and `is_readable()` checks without filesystem hits.
   - `realpath_cache_size = 16M` and `realpath_cache_ttl = 600`: Expanded path cache and retention time to 10 minutes.
2. **Laravel Route Collision Resolution (`web/wwwroot/game/routes/web.php`)**:
   - Renamed duplicate POST `/login` route to `login.post`.
   - Configured `Auth::routes(['register' => true, 'logout' => false])` to prevent collision with custom GET `/logout`.
3. **Application Cache Warmup**:
   - Executed `php artisan config:cache` (consolidated configuration into a single cached file).
   - Executed `php artisan route:cache` (compiled route tree into serialized fast lookup).
   - Executed `php artisan view:cache` (pre-compiled all Blade templates).

### Verified Benchmark Results:

| Endpoint | Baseline Latency | Optimized Latency | Speedup |
| :--- | :--- | :--- | :--- |
| **`/login`** | ~16,120 ms (16.1s) | **71 ms** (0.07s) | **~227x faster** |
| **`/equipment_shop`** | ~14,500 ms (14.5s) | **79 ms** (0.08s) | **~183x faster** |
| **`/packages`** | ~12,800 ms (12.8s) | **82 ms** (0.08s) | **~156x faster** |
| **`/topup`** | ~13,200 ms (13.2s) | **83 ms** (0.08s) | **~159x faster** |
| **`/home`** | ~15,000 ms (15.0s) | **101 ms** (0.10s) | **~148x faster** |

---

## 9. In-Game Big Cat Store: 2026 Fix & Free Mock Purchasing

### Root Causes Fixed:
1. **2026 Month Card Lookup Crash**:
   - `UIViewControllerZenyShop:GetMonthCardConfigure()` and `UISubViewControllerMonthlyVIP:GetMonthCardConfigure()` originally required an exact `v.Year == year and v.Month == month` match in `Table_MonthCard`. When the server year reached 2026, `GetMonthCardConfigure()` returned `nil`, crashing `LoadView()` when indexing `monthCardConfigure.NpcPicture`.
2. **Client Script Compatibility (`quick_jump_rom.apk`)**:
   - In `quick_jump_rom.apk`, `ApplicationInfo.IsIphoneX()` is commented out in `com.unity3d`. Preserved the native commented-out `UIViewControllerZenyShop:BGAdapt()` so `Init()` never attempts to call `ApplicationInfo.IsIphoneX()`.
3. **Offline Payment Gateway Hang**:
   - Clicking "Purchase" on Big Cat Coins, Zeny, Monthly VIP, EP Cards, or Lucky Bags originally invoked `FunctionXDSDK.Ins:Pay(...)` / `FunctionSDK`, locking the UI waiting for a third-party callback.

### Client Bundle Modifications (`patch.zip` & `quick_jump_rom.apk`):
- **`Android/resources/script2/framework.unity3d`** (`assets/assets32.zip`):
  - **`UIViewControllerZenyShop`**: Added fallback logic in `GetMonthCardConfigure()` (`Year + Month` -> `Month` -> any valid entry) and `nil`-guard before `PictureManager.Instance:SetZenyShopNPC`.
  - **`UISubViewControllerMonthlyVIP`**: Added `GetMonthCardConfigure()` fallback, `nil`-guard before `SetMonthCardUI`, and replaced `OnClickForButtonPurchaseCard` / `Purchase` with dynamic `ServiceGMProxy` free activation (`additem` + `usedepositcard`).
  - **`UIListItemViewControllerZenyShopItem`**: Replaced `OnClickForButtonPurchase` / `Purchase` with dynamic `ServiceGMProxy` free purchasing:
    - **Monthly VIP (`Type == 2`)**: Grants and activates the current month card (`additem` + `usedepositcard`).
    - **EP Cards (`Type == 5`)**: Grants the EP card item (`additem`) and activates it (`usedepositcard`).
    - **Big Cat Coins (`Type == 3` / `ItemId == 151`)**: Grants BCC currency (`addmoney type=154`) and item `151`.
    - **Zeny (`Type == 1` / `ItemId == 100`)**: Grants Zeny (`addmoney type=131`).
    - **Other Deposit Items**: Dynamically spawns `conf.ItemId` (`additem`), shows an instant floating message (`MsgManager.FloatMsgTableParam`), unlocks the purchase switch, and refreshes the currency balance bar.
  - **`UIListItemCtrlLuckyBag`**: Updated Deposit Lucky Bags / Gift Boxes (`Type == 4`) in the B Coin tab to grant items for free via `ServiceGMProxy`.
- **`Android/resources/script2/config_pay_zhifu.unity3d`** (`assets/assets29.zip`):
  - **`Table_MonthCard`**: Updated entries `800201`–`800212` to `Year = 2026`.
- **`Android/resources/script2/config_item_daoju.unity3d`** (`assets/assets10.zip`):
  - **`Table_UseItem`**: Preserved all 1,827 native entries (including custom items `901604`–`90500`) and removed `AlertMode = 1` on items `4500`, `12354`, and `12355`.

---

## 10. Automatic OTA Client Hot-Patching (`patch.zip` / Multi-Patch Queue)

### Overview:
Configured the web container (`rom-web`) to deliver over-the-air (OTA) AssetBundle hot-patches directly to the Android client on startup, supporting **both multiple incremental patches (`patch.zip`, `patch2.zip`, `patch3.zip`...) and in-place overwrites**, with automatic version bumping and MD5/size detection.

### Files Configured:
- **`web/wwwroot/127.0.0.1/res/*.zip`**: Any `.zip` file placed in `res/` (starting with `patch.zip` at version `229110`) is automatically tracked.
- **`web/wwwroot/127.0.0.1/version.php`** & **`web/wwwroot/game/public/game/Version.php`**:
  - Dynamically resolves the server host IP from `$_SERVER['HTTP_HOST']` (`http://<HOST>/res/<filename>.zip`).
  - Scans all `*.zip` files in `/www/wwwroot/127.0.0.1/res/`, checks `filesize()`, `filemtime()`, and `md5_file()`, and caches per-file version metadata in `/www/wwwroot/127.0.0.1/res/patch.meta.json`.
  - **Incremental Multi-Patch Support**: If you leave `patch.zip` (`229110`) in `res/` and add `patch2.zip`, `patch2.zip` is automatically assigned version `229111`. Existing players at `229110` only download `patch2.zip`, while new players download `patch.zip` then `patch2.zip` in order (`1/2`, `2/2`).
  - **Overwrite Support**: If you overwrite `patch.zip` in-place with a new file (different MD5), its version automatically increments so all players download the updated file.
- **`web/nginx/conf.d/gateway.conf`**: Added `/version` -> `/version.php` rewrite rule on port 80.

---

## 11. Premium (Monthly VIP) MVP & MINI Map / Minimap / Auto-Battle Visibility Hotfix (`patch1.zip`)

### Root Causes Fixed:
1. **Minimap, BigMap & Auto-Battle Filtered Out MVP/MINI Without Adventure Skills**:
   - `MainViewMiniMap:UpdateNearlyMonsters()` and `FunctionMonster:FilterMonster()` / `FunctionMonster:FilterMonsterStaticInfo()` previously checked only `SkillProxy.Instance:HasLearnedSkill(50051001)` (*Wolf's Eye*, Adventure Class C) and `SkillProxy.Instance:HasLearnedSkill(50050001)` (*Falcon Perception*, Adventure Class E), ignoring `UIModelMonthlyVIP.Instance():AmIMonthlyVIP()`.
   - Players who activated Premium without learning those two Adventure Skills had `hasLearnMvp = false` and `hasLearnMini = false`, hiding `map_mvpboss` and `map_miniboss` icons on the Minimap/BigMap and excluding MVPs/MINIs from the Auto-Battle target list.
2. **MVP Board (`BossView`) MINI Toggle & Refresh**:
   - `BossView:Init()` called `QueryMVPBoss()` before `OnEnter()` set `showMiniTog.value`, and `OnEnter()` did not force-enable the MINI toggle or refresh the list when Premium was active.

### Hotfix Changes (`web/wwwroot/127.0.0.1/res/patch1.zip` -> Version `229111` & `quick_jump_rom.apk`):
- **`Android/resources/script2/framework.unity3d`**:
  - **`MainViewMiniMap`**: Updated `UpdateNearlyMonsters()` to pass `isMvpFight or amIMonthlyVIP` into `FunctionMonster.Me():FilterMonster(...)`, and updated `HandleShowNpcPos()` to support `Table_Monster` (`MVP` -> `map_mvpboss`, `MINI` -> `map_miniboss`) icons.
  - **`BossView`**: Updated `OnEnter()` so when `AmIMonthlyVIP()` is active, `showMiniTog.value` is automatically enabled, `QueryMVPBoss()` is requested, and `UpdateBossList()` refreshes immediately.
  - **`UISubViewControllerMonthlyVIP`**, **`UIListItemViewControllerZenyShopItem`**, & **`ServiceUserEventProxy`**: Automatically grants Adventure Skills `50050001` (MINI detection) and `50051001` (MVP detection) and sets client-side Monthly VIP expiration & `BossView_ShowMini = true` immediately upon activating Premium.
- **`Android/resources/script2/functionsystem.unity3d`**:
  - **`FunctionMonster`**: Updated `FilterMonster()` and `FilterMonsterStaticInfo()` to treat `UIModelMonthlyVIP.Instance():AmIMonthlyVIP()` as having learned both MVP and MINI detection skills, unlocking MVP/MINI icons on the map and in the Auto-Battle target list during Premium.


