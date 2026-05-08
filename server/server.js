const express = require("express");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "2mb" }));

let pendingCommand = null;
let history = [];

function makeId() {
  return "cmd_" + Date.now().toString(36) + "_" + Math.random().toString(36).slice(2, 8);
}

function normalizePrompt(prompt) {
  return String(prompt || "").trim();
}

function generateFromPrompt(prompt) {
  const p = normalizePrompt(prompt).toLowerCase();

  if (p.includes("touch") || p.includes("hozzáér") || p.includes("reward part")) {
    return {
      type: "create_script",
      path: "Workspace/RewardPart/Script.server.lua",
      scriptName: "EperAI_TouchReward.server.lua",
      parent: "ServerScriptService",
      code: `-- EperAI generated Touch Reward script
-- Tedd ezt egy Part alá, vagy állítsd át a part változót.

local Players = game:GetService("Players")
local part = workspace:FindFirstChild("RewardPart") or script.Parent
local debounce = {}

part.Touched:Connect(function(hit)
    local character = hit.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end
    if debounce[player] then return end

    debounce[player] = true

    local leaderstats = player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins")

    if coins then
        coins.Value += 100
    end

    task.wait(1)
    debounce[player] = nil
end)`
    };
  }

  if (p.includes("remote")) {
    return {
      type: "create_script",
      path: "ServerScriptService/EperAI_CreateRemotes.server.lua",
      scriptName: "EperAI_CreateRemotes.server.lua",
      parent: "ServerScriptService",
      code: `-- EperAI generated RemoteEvent setup

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = ReplicatedStorage:FindFirstChild("Events")
if not events then
    events = Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage
end

local remote = events:FindFirstChild("UpdateCurrency")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "UpdateCurrency"
    remote.Parent = events
end

print("EperAI: RemoteEvent setup ready")`
    };
  }

  if (p.includes("teleport")) {
    return {
      type: "create_script",
      path: "Workspace/TeleportPart/Script.server.lua",
      scriptName: "EperAI_TeleportPart.server.lua",
      parent: "ServerScriptService",
      code: `-- EperAI generated Teleport Part script
-- Kell hozzá: workspace.TeleportPart és workspace.TeleportTarget

local part = workspace:WaitForChild("TeleportPart")
local target = workspace:WaitForChild("TeleportTarget")
local debounce = {}

part.Touched:Connect(function(hit)
    local character = hit.Parent
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then return end
    if debounce[character] then return end

    debounce[character] = true
    root.CFrame = target.CFrame + Vector3.new(0, 3, 0)

    task.wait(1)
    debounce[character] = nil
end)`
    };
  }

  if (p.includes("harc") || p.includes("combat") || p.includes("fegyver") || p.includes("gun")) {
    return {
      type: "create_script",
      path: "ServerScriptService/EperAI_Combat.server.lua",
      scriptName: "EperAI_Combat.server.lua",
      parent: "ServerScriptService",
      code: `-- EperAI generated simple combat template
-- Ezt később Tool alá érdemes átrakni.

local DAMAGE = 20
local RANGE = 8

print("EperAI combat template loaded")
print("Damage:", DAMAGE, "Range:", RANGE)`
    };
  }

  return {
    type: "create_script",
    path: "ServerScriptService/EperAI_Leaderstats.server.lua",
    scriptName: "EperAI_Leaderstats.server.lua",
    parent: "ServerScriptService",
    code: `-- EperAI generated Leaderstats script

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local Coins = Instance.new("IntValue")
    Coins.Name = "Coins"
    Coins.Value = 0
    Coins.Parent = leaderstats
end)`
  };
}

app.get("/", (req, res) => {
  res.json({
    name: "EperAI Web-Studio Bridge API",
    version: "1.0.0",
    status: "online",
    hasPendingCommand: Boolean(pendingCommand)
  });
});

app.post("/queue", (req, res) => {
  const prompt = normalizePrompt(req.body.prompt);

  if (!prompt) {
    return res.status(400).json({ ok: false, error: "Missing prompt" });
  }

  const generated = generateFromPrompt(prompt);

  pendingCommand = {
    id: makeId(),
    prompt,
    createdAt: new Date().toISOString(),
    ...generated
  };

  history.push(pendingCommand);
  if (history.length > 25) history = history.slice(-25);

  res.json({ ok: true, command: pendingCommand });
});

app.get("/pending", (req, res) => {
  res.json({
    ok: true,
    command: pendingCommand
  });
});

app.post("/complete", (req, res) => {
  const id = String(req.body.id || "");

  if (pendingCommand && pendingCommand.id === id) {
    pendingCommand = null;
  }

  res.json({ ok: true });
});

app.get("/history", (req, res) => {
  res.json({ ok: true, history });
});

app.listen(PORT, () => {
  console.log(`EperAI Bridge API running on http://localhost:${PORT}`);
});
