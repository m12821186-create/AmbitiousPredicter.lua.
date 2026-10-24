-- Ambitious Predicter | Android-friendly edition
-- LocalScript para tu propia experiencia de Roblox
-- Las predicciones son estimaciones estadísticas, no garantías.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
    Red = Color3.fromRGB(222, 53, 58),
    Orange = Color3.fromRGB(255, 151, 35),
    Yellow = Color3.fromRGB(255, 211, 55),
    Green = Color3.fromRGB(48, 181, 83),
    Blue = Color3.fromRGB(65, 132, 255),
    Purple = Color3.fromRGB(157, 62, 211)
}

local ORDER = {"Red", "Orange", "Yellow", "Green", "Blue", "Purple"}
local diceColors = {"Red", "Orange", "Yellow", "Green"}
local history = {}
local prediction = nil
local hits, misses = 0, 0
local betAmount = 1

local old = playerGui:FindFirstChild("AmbitiousPredicterUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "AmbitiousPredicterUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0.92, 0, 0, 510)
frame.Position = UDim2.new(0.04, 0, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 13, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize = Vector2.new(300, 450)
sizeLimit.MaxSize = Vector2.new(430, 510)
sizeLimit.Parent = frame

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(130, 100, 210)
stroke.Thickness = 1
stroke.Parent = frame

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = frame

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function label(text, pos, size, parent, textSize, color)
    return make("TextLabel", {
        Position = pos,
        Size = size,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = textSize or 13,
        TextWrapped = true
    }, parent)
end

local function button(text, pos, size, parent, color)
    local b = make("TextButton", {
        Position = pos,
        Size = size,
        BackgroundColor3 = color or Color3.fromRGB(42, 36, 58),
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true
    }, parent)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
    return b
end

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = Color3.fromRGB(24, 19, 37),
    BorderSizePixel = 0
}, frame)

label("Ambitious Predicter", UDim2.new(0, 15, 0, 8),
    UDim2.new(0.62, 0, 0, 23), header, 16)

label("Historical color estimator", UDim2.new(0, 16, 0, 32),
    UDim2.new(0.65, 0, 0, 16), header, 10,
    Color3.fromRGB(165, 155, 190))

local close = button("×", UDim2.new(1, -42, 0, 12),
    UDim2.new(0, 30, 0, 30), header,
    Color3.fromRGB(100, 45, 60))

close.Activated:Connect(function()
    gui:Destroy()
end)

local minimize = button("–", UDim2.new(1, -80, 0, 12),
    UDim2.new(0, 30, 0, 30), header)

local content = make("Frame", {
    Position = UDim2.new(0, 12, 0, 68),
    Size = UDim2.new(1, -24, 1, -80),
    BackgroundTransparency = 1
}, frame)

local diceTitle = label("SELECT THE LAST FOUR RESULTS",
    UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 22),
    content, 10, Color3.fromRGB(160, 150, 180))

local diceHolder = make("Frame", {
    Position = UDim2.new(0, 0, 0, 26),
    Size = UDim2.new(1, 0, 0, 75),
    BackgroundTransparency = 1
}, content)

local diceButtons = {}
local diceLabels = {}

for i = 1, 4 do
    local x = (i - 1) * 0.25
    local d = button(tostring(i),
        UDim2.new(x, 3, 0, 0),
        UDim2.new(0.25, -7, 0, 48),
        diceHolder, COLORS[diceColors[i]])

    d.Text = "●"
    d.TextSize = 22

    local name = label(diceColors[i],
        UDim2.new(x, 0, 0, 49),
        UDim2.new(0.25, 0, 0, 20),
        diceHolder, 10, Color3.fromRGB(210, 205, 220))

    diceButtons[i] = d
    diceLabels[i] = name

    d.Activated:Connect(function()
        local index = table.find(ORDER, diceColors[i]) or 1
        index = (index % #ORDER) + 1
        diceColors[i] = ORDER[index]
        d.BackgroundColor3 = COLORS[diceColors[i]]
        name.Text = diceColors[i]
    end)
end

local record = button("REGISTER FOUR RESULTS",
    UDim2.new(0, 0, 0, 108),
    UDim2.new(1, 0, 0, 38), content,
    Color3.fromRGB(107, 72, 190))

local predict = button("PREDICT NEXT ROLL",
    UDim2.new(0, 0, 0, 154),
    UDim2.new(1, 0, 0, 42), content,
    Color3.fromRGB(124, 91, 225))

local panel = make("Frame", {
    Position = UDim2.new(0, 0, 0, 205),
    Size = UDim2.new(1, 0, 0, 91),
    BackgroundColor3 = Color3.fromRGB(30, 25, 42)
}, content)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

label("NEXT ROLL ESTIMATE", UDim2.new(0, 12, 0, 8),
    UDim2.new(0.7, 0, 0, 16), panel, 10,
    Color3.fromRGB(155, 145, 175))

local result = label("—", UDim2.new(0, 12, 0, 29),
    UDim2.new(0.55, 0, 0, 29), panel, 22)

local confidence = label("No data", UDim2.new(0.58, 0, 0, 31),
    UDim2.new(0.38, 0, 0, 25), panel, 13,
    Color3.fromRGB(130, 220, 160))

local status = label("Register results to begin.",
    UDim2.new(0, 12, 0, 63), UDim2.new(1, -24, 0, 18),
    panel, 10, Color3.fromRGB(165, 155, 180))

local stats = make("Frame", {
    Position = UDim2.new(0, 0, 0, 305),
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = Color3.fromRGB(30, 25, 42)
}, content)
Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 10)

local rate = label("Accuracy: no results",
    UDim2.new(0, 12, 0, 7), UDim2.new(1, -24, 0, 18),
    stats, 12)

local historyLabel = label("Recorded rolls: 0",
    UDim2.new(0, 12, 0, 30), UDim2.new(1, -24, 0, 17),
    stats, 11, Color3.fromRGB(165, 155, 180))

local betPanel = make("Frame", {
    Position = UDim2.new(0, 0, 0, 370),
    Size = UDim2.new(1, 0, 0, 43),
    BackgroundTransparency = 1
}, content)

label("BET AMOUNT", UDim2.new(0, 0, 0, 0),
    UDim2.new(0.35, 0, 1, 0), betPanel, 10,
    Color3.fromRGB(165, 155, 180))

local betText = label("1", UDim2.new(0.37, 0, 0, 0),
    UDim2.new(0.18, 0, 1, 0), betPanel, 15)

local minus = button("−", UDim2.new(0.58, 0, 0, 4),
    UDim2.new(0.16, 0, 0, 32), betPanel)

local plus = button("+", UDim2.new(0.78, 0, 0, 4),
    UDim2.new(0.16, 0, 0, 32), betPanel)

local reset = button("RESET HISTORY",
    UDim2.new(0, 0, 0, 420),
    UDim2.new(1, 0, 0, 32), content,
    Color3.fromRGB(75, 42, 60))

local minimized = false
local savedSize = frame.Size

minimize.Activated:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    frame.Size = minimized
        and UDim2.new(savedSize.X.Scale, savedSize.X.Offset, 0, 60)
        or savedSize
    minimize.Text = minimized and "+" or "–"
end)

local function updateStats()
    local total = hits + misses
    if total == 0 then
        rate.Text = "Accuracy: no results"
    else
        rate.Text = string.format(
            "Accuracy: %.1f%% (%d/%d)",
            hits / total * 100, hits, total
        )
    end
    historyLabel.Text = "Recorded rolls: " .. #history
end

local function recordRoll(color)
    -- Check the previous prediction before adding the new result.
    if prediction then
        if prediction == color then
            hits = hits + 1
        else
            misses = misses + 1
        end
        prediction = nil
    end

    table.insert(history, color)

    -- Keep the most recent 100 results.
    if #history > 100 then
        table.remove(history, 1)
    end
    updateStats()
end

record.Activated:Connect(function()
    for i = 1, 4 do
        recordRoll(diceColors[i])
    end
    status.Text = "Four results added to history."
end)

predict.Activated:Connect(function()
    if #history == 0 then
        result.Text = "No data"
        confidence.Text = "—"
        status.Text = "Register results first."
        return
    end

    local counts = {}
    for _, color in ipairs(ORDER) do
        counts[color] = 0
    end

    for _, color in ipairs(history) do
        counts[color] = counts[color] + 1
    end

    local best = {}
    local highest = 0

    for _, color in ipairs(ORDER) do
        if counts[color] > highest then
            highest = counts[color]
            best = {color}
        elseif counts[color] == highest then
            table.insert(best, color)
        end
    end

    -- Break ties randomly; this does not predict randomness.
    local chosen = best[math.random(1, #best)]
    prediction = chosen

    result.Text = chosen
    result.TextColor3 = COLORS[chosen]

    local frequency = counts[chosen] / #history * 100
    confidence.Text = string.format("%.1f%%", frequency)
    status.Text = "Historical frequency, not future certainty."
end)

minus.Activated:Connect(function()
    betAmount = math.max(1, betAmount - 1)
    betText.Text = tostring(betAmount)
end)

plus.Activated:Connect(function()
    betAmount = math.min(1000000, betAmount + 1)
    betText.Text = tostring(betAmount)
end)

reset.Activated:Connect(function()
    table.clear(history)
    hits, misses = 0, 0
    prediction = nil
    result.Text = "—"
    result.TextColor3 = Color3.new(1, 1, 1)
    confidence.Text = "No data"
    status.Text = "History cleared."
    updateStats()
end)

-- Drag the panel with touch or mouse.
local dragging = false
local dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

updateStats()
