# 🍓 EperAI FINAL FINAL

Magyar Roblox coding tool prototípus.

## Működés

```txt
Web Dashboard
   ↓ prompt
Local Node.js API
   ↓ pending command
Roblox Studio Plugin
   ↓ Apply Web Command
ServerScriptService-ben létrejön a script
```

## Web

- `web/index.html`
- `web/dashboard.html`
- `web/signin.html`

## API indítása

```bash
cd server
npm install
npm start
```

API:

```txt
http://localhost:3000
```

## Roblox Studio plugin

Másold be:

```txt
plugin/EperAI.plugin.lua
```

ide:

```txt
%LOCALAPPDATA%\Roblox\Plugins
```

Roblox Studio-ban:

```txt
Game Settings > Security > Allow HTTP Requests
```

Plugin flow:

1. Indítsd el az API-t.
2. Nyisd meg a web dashboardot.
3. Írj promptot és küldd el.
4. Roblox Studio pluginban: `Fetch Web Command`.
5. Ellenőrizd a preview-t.
6. `Apply Web Command`.

## Biztonság

A plugin csak új scriptet hoz létre. Nem töröl és nem ír át meglévő fontos scripteket.
