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
1. **Catalog**: 3,141 equipment items categorized into:
   - Weapons (Swords, Spears, Staves, Bows, Katars, Daggers, Axes, Maces, Knuckles, Books, Instruments, Whips)
   - Off-hand & Shields
   - Armors
   - Garments
   - Footgears
   - Accessories (Rings, Necklaces, Brooches, Gloves)
   - Headwear, Face, Mouth, Back & Tails
   - Mounts & Costumes
2. **Character Detection**: Queries `charbase` in `ro_xd_r2` for the logged-in user's characters and levels.
3. **Instant Delivery**: Sends items via `http://127.0.0.1/user/gmquery.php` -> TCP socket to SceneServer port `7080` (pure in-game mail packet).
4. **Offline Docker Fixes**:
   - `web/wwwroot/127.0.0.1/user/config.php`: Dynamic DNS resolution to `db` (MySQL) and `game` (SceneServer GM socket).
   - `web/wwwroot/game/.env`: Pointed `URL_SEND_ITEM_API` to `http://127.0.0.1`.
   - `web/php.ini`: Enabled OPCache revalidation for dynamic Blade rendering across Docker volume mounts.
