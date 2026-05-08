-- EperAI FINAL FINAL Roblox Studio Plugin
-- Web -> Local API -> Studio bridge
-- The prompt is written on the web dashboard.
-- This plugin only connects and applies the pending web command.

local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local toolbar = plugin:CreateToolbar("EperAI")
local openButton = toolbar:CreateButton("EperAI Connect", "Open EperAI Web Bridge", "rbxassetid://4458901886")

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	430,
	520,
	330,
	380
)

local widget = plugin:CreateDockWidgetPluginGui("EperAIWebBridgeWidget", widgetInfo)
widget.Title = "EperAI Connect"

local apiBase = "http://localhost:3000"
local lastCommand = nil

local function make(className, props, parent)
	local obj = Instance.new(className)

	for key, value in pairs(props or {}) do
		obj[key] = value
	end

	obj.Parent = parent
	return obj
end

local root = make("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(18, 24, 42),
	BorderSizePixel = 0,
}, widget)

make("UIPadding", {
	PaddingTop = UDim.new(0, 14),
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
	PaddingBottom = UDim.new(0, 14),
}, root)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 10),
}, root)

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundTransparency = 1,
	Text = "🍓 EperAI Connect",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 22,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 1,
}, root)

make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundTransparency = 1,
	Text = "A promptot a weben írod be. A plugin csak lekéri és létrehozza a scriptet.",
	TextColor3 = Color3.fromRGB(180, 190, 210),
	TextSize = 13,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	LayoutOrder = 2,
}, root)

local apiBox = make("TextBox", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = Color3.fromRGB(12, 18, 32),
	TextColor3 = Color3.fromRGB(235, 240, 255),
	PlaceholderText = "http://localhost:3000",
	Text = apiBase,
	TextSize = 13,
	Font = Enum.Font.Code,
	ClearTextOnFocus = false,
	LayoutOrder = 3,
}, root)

local statusLabel = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundColor3 = Color3.fromRGB(28, 34, 52),
	TextColor3 = Color3.fromRGB(220, 230, 245),
	Text = "Status: not connected",
	TextSize = 13,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 4,
}, root)

make("UIPadding", {
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
}, statusLabel)

local row = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	LayoutOrder = 5,
}, root)

make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
}, row)

local connectButton = make("TextButton", {
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundColor3 = Color3.fromRGB(35, 190, 100),
	TextColor3 = Color3.fromRGB(5, 12, 8),
	Text = "Connect",
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	LayoutOrder = 1,
}, row)

local fetchButton = make("TextButton", {
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundColor3 = Color3.fromRGB(70, 170, 255),
	TextColor3 = Color3.fromRGB(5, 12, 18),
	Text = "Fetch Web Command",
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	LayoutOrder = 2,
}, row)

local applyButton = make("TextButton", {
	Size = UDim2.new(1, 0, 0, 42),
	BackgroundColor3 = Color3.fromRGB(255, 76, 128),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Apply Web Command",
	TextSize = 14,
	Font = Enum.Font.GothamBold,
	LayoutOrder = 6,
}, root)

local output = make("TextBox", {
	Size = UDim2.new(1, 0, 1, -240),
	BackgroundColor3 = Color3.fromRGB(10, 14, 24),
	TextColor3 = Color3.fromRGB(230, 240, 255),
	Text = "1. Indítsd el a local API-t: npm start\n2. Weben írj promptot\n3. Itt kattints: Fetch Web Command\n4. Apply Web Command",
	TextSize = 12,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	ClearTextOnFocus = false,
	MultiLine = true,
	LayoutOrder = 7,
}, root)

local function setStatus(text, ok)
	statusLabel.Text = "Status: " .. text
	if ok then
		statusLabel.BackgroundColor3 = Color3.fromRGB(20, 80, 45)
	else
		statusLabel.BackgroundColor3 = Color3.fromRGB(85, 40, 45)
	end
end

local function request(method, path, body)
	apiBase = apiBox.Text

	local options = {
		Url = apiBase .. path,
		Method = method,
		Headers = {
			["Content-Type"] = "application/json",
		},
	}

	if body then
		options.Body = HttpService:JSONEncode(body)
	end

	local response = HttpService:RequestAsync(options)

	if not response.Success then
		error("HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.Body))
	end

	return HttpService:JSONDecode(response.Body)
end

local function getParentForCommand(command)
	if command.parent == "ReplicatedStorage" then
		return ReplicatedStorage
	end

	return ServerScriptService
end

local function applyCommand(command)
	if not command then
		return false, "No command loaded."
	end

	if command.type ~= "create_script" then
		return false, "Unsupported command type: " .. tostring(command.type)
	end

	local parent = getParentForCommand(command)
	local scriptName = command.scriptName or "EperAI_Generated.server.lua"

	local existing = parent:FindFirstChild(scriptName)
	if existing then
		existing.Name = scriptName .. "_old_" .. os.time()
	end

	local scriptObj = Instance.new("Script")
	scriptObj.Name = scriptName
	scriptObj.Source = command.code or "-- Empty EperAI command"
	scriptObj.Parent = parent

	local ok, err = pcall(function()
		request("POST", "/complete", { id = command.id })
	end)

	if not ok then
		warn("EperAI complete request failed:", err)
	end

	return true, "Created: " .. parent.Name .. "/" .. scriptName
end

connectButton.MouseButton1Click:Connect(function()
	local ok, result = pcall(function()
		return request("GET", "/", nil)
	end)

	if ok then
		setStatus("connected", true)
		output.Text = "Connected to EperAI API.\n\n" .. HttpService:JSONEncode(result)
	else
		setStatus("failed", false)
		output.Text = "Nem sikerült csatlakozni.\n\nIndítsd el:\ncd server\nnpm install\nnpm start\n\nHiba:\n" .. tostring(result)
	end
end)

fetchButton.MouseButton1Click:Connect(function()
	local ok, result = pcall(function()
		return request("GET", "/pending", nil)
	end)

	if not ok then
		setStatus("fetch failed", false)
		output.Text = "Nem sikerült lekérni a web commandot.\n\nHiba:\n" .. tostring(result)
		return
	end

	if not result.command then
		lastCommand = nil
		setStatus("no pending command", true)
		output.Text = "Nincs várakozó command.\n\nMenj a web dashboardra, írj promptot, és küldd el."
		return
	end

	lastCommand = result.command
	setStatus("command ready", true)

	output.Text =
		"Command loaded: " .. tostring(lastCommand.id) ..
		"\n\nPrompt:\n" .. tostring(lastCommand.prompt) ..
		"\n\nPath:\n" .. tostring(lastCommand.path) ..
		"\n\nCode:\n" .. tostring(lastCommand.code)
end)

applyButton.MouseButton1Click:Connect(function()
	local ok, result = applyCommand(lastCommand)

	if ok then
		setStatus("applied", true)
		output.Text = tostring(result) .. "\n\nA command lefutott és törölve lett a queue-ból."
		lastCommand = nil
	else
		setStatus("apply failed", false)
		output.Text = tostring(result)
	end
end)

openButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

print("EperAI Final Final Plugin loaded")
