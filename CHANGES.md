# Changelog: Quest Teleportation System ("Option A")

## 1. Overview & Mechanics
This feature adds an intelligent one-click teleportation option to the quest navigation system:
- **Trigger**: Clicking on any active quest in the HUD Quest Tracker or the "Go" button in the Quest Manual.
- **Confirmation Dialog**: Displays a prompt (*"Quest Teleport"*) offering two choices:
  - **Teleport**: Instantly moves the character with **0 loading screens**.
  - **Walk**: Cancels teleport and executes the game's default auto-walk and tracking direction marker.
- **Behavior by Map Location**:
  - **Same Map**: Blinks the player directly to the quest objective / NPC position (using `ServiceGMProxy:Call("gocity ...")`). Upon arrival, it automatically triggers NPC conversation / interaction. If the player is already within 6 meters, the dialog is skipped and talks to the NPC immediately.
  - **Different Map**: Queries the pathfinder system (`WorldTeleport` and `MapInnerTeleport.outter`) to calculate the exact exit portal on the *current* map leading toward the destination. Blinks the player right in front of the gate with **0 loading screens**, allowing the player to step into the portal naturally.

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
