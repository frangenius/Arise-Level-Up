# Walkthrough

## What has been implemented

- **PWA (Progressive Web App)**
  - Core files: `index.html`, `styles.css`, `app.js`, `db.js`, `missions.js`, `rpg.js`, `skills.js`, `manifest.json`, `sw.js`.
  - Modern **Solo Leveling**‑inspired visual theme (glassmorphism, neon accents, custom fonts).
  - IndexedDB storage for settings, missions, inventory, calendar, achievements.
  - Service worker for offline capability and installability.
  - Local HTTP server (`server.js`) and convenient Windows batch script (`start_server.bat`).

- **Flutter native skeleton** (`/flutter_app`)
  - `pubspec.yaml` with all required dependencies (Riverpod, Hive, sqflite, fl_chart, lottie, etc.).
  - **Theme** (`core/theme/app_theme.dart`) matching the PWA dark neon aesthetic.
  - **Hive model** (`core/utils/user_profile.dart`) and **Riverpod notifier** (`core/utils/user_provider.dart`).
  - **SQLite helper** (`core/database/db_helper.dart`).
  - **Screens**
    - Splash (`features/auth/presentation/splash_screen.dart`).
    - Calibration/onboarding (`features/auth/presentation/calibration_screen.dart`).
    - Home with navigation bar (`features/home/presentation/home_screen.dart`).
    - Missions management with tab view, create‑mission bottom sheet, focus‑timer, reward handling (`features/missions/presentation/missions_screen.dart`).
    - Profile overview with stats, class info, achievements (`features/profile/presentation/profile_screen.dart`).
    - Inventory grid with rarity styling (`features/inventory/presentation/inventory_screen.dart`).
    - **RPG placeholder** (`features/rpg/presentation/rpg_screen.dart`).
  - All screens respect the same dark/neon color palette and use reusable glass‑panel decorations.

## How to run / test

### 1️⃣ Run the PWA locally (quick mobile test)

1. Open a terminal in the project root (`c:\Users\damet\Desktop\arise level up`).
2. Execute the batch script:
   ```
   .\start_server.bat
   ```
   This launches `node server.js` on **port 8080**.
3. On your computer, open a browser and navigate to `http://localhost:8080` – you should see the LEVEL UP UI.
4. To test on a mobile device, connect the device to the same Wi‑Fi network, find your PC’s local IP (run `Get-NetIPAddress`), and open `http://<YOUR_IP>:8080` on the phone’s browser. The PWA will prompt to *Add to Home Screen* for a native‑like experience.

> **Tip:** If the server fails to start, verify that `node.exe` is reachable at `F:\node\node.exe` (the path used when we originally generated `server.js`). Adjust the batch file accordingly.

### 2️⃣ Run the Flutter app (native build)

1. Open a terminal in the Flutter folder:
   ```
   cd "c:\Users\damet\Desktop\arise level up\flutter_app"
   ```
2. Fetch the dependencies:
   ```
   flutter pub get
   ```
3. (Optional) **Add the app logo** – copy the generated logo image `levelup_logo_1785444896175.jpg` from the artifact directory into:
   ```
   flutter_app/assets/images/logo.png
   ```
   If you prefer a different icon, replace the file accordingly and run `flutter pub run flutter_launcher_icons` (not required for functionality).
4. Run the app on a connected device or emulator:
   ```
   flutter run
   ```
   The app will start with the splash screen, then proceed to the calibration flow if no profile exists, or straight to the home screen otherwise.

### 3️⃣ Verify core flows

- **Calibration** – enters name, selects avatar, chooses physical/mental habits, and sets a primary goal. This creates a `UserProfile` entry in Hive.
- **Home** – shows level, XP bar, streak, gold, energy, attribute summary, and today’s missions (pulled from SQLite).
- **Missions** – create custom missions, start a focus timer, complete missions, earn XP/gold, and see attribute gains.
- **Profile** – displays avatar, rank, detailed stats, class bonuses, and a grid of achievements.
- **Inventory** – placeholder grid ready to show items once the game logic populates them.
- **RPG** – currently a placeholder screen stating “coming soon”.

## Next steps (if you want to extend)

1. **Implement combat engine** in `features/rpg/presentation/rpg_screen.dart` – reuse the JavaScript combat logic (`rpg.js`) as a Dart model.
2. **Add shop & crafting** screens that interact with the SQLite `inventory` table.
3. **Populate the inventory** from mission rewards (e.g., when a mission finishes, insert a new item).
4. **Create a stats radar chart** using `fl_chart` for a visual summary on the Home tab.
5. **Add push notifications** (`flutter_local_notifications`) for daily‑mission reminders.
6. **Polish UI** – add Lottie animations, refine glass‑panel shadows, and adjust text scaling for accessibility.

---
*All code resides under `c:\Users\damet\Desktop\arise level up`. Feel free to open any file for further tweaks or ask for additional features.*
