require("hs.ipc")

local SLOT_COUNT = 9
local ALERT_DURATION = 0.35
local SLOT_OVERVIEW_DURATION = 1
local SLOT_OVERVIEW_LINE_MAX = 20
local RECALL_MODS = { "ctrl", "shift" }
local SAVE_MODS = { "ctrl", "shift", "cmd" }
local TILE_MODS = { "ctrl", "shift" }
local TILE_LETTER_MODS = { "ctrl", "shift" }
local SETTINGS_KEY = "miliddle.windowSlots"

hs.window.animationDuration = 0

local function loadSlots()
    return hs.settings.get(SETTINGS_KEY) or {}
end

local function saveSlots(slots)
    hs.settings.set(SETTINGS_KEY, slots)
end

local function alert(message, duration)
    hs.alert.show(message, nil, nil, duration or ALERT_DURATION)
end

local function findUsableFrontmostWindow()
    local candidates = {}
    local frontmostApp = hs.application.frontmostApplication()

    table.insert(candidates, hs.window.focusedWindow())
    table.insert(candidates, hs.window.frontmostWindow())

    if frontmostApp then
        table.insert(candidates, frontmostApp:focusedWindow())
        table.insert(candidates, frontmostApp:mainWindow())

        for _, window in ipairs(frontmostApp:visibleWindows()) do
            table.insert(candidates, window)
        end
    end

    for _, window in ipairs(candidates) do
        if window and window:isStandard() then
            return window
        end
    end

    alert("No usable window found. Check Accessibility permissions.")
    return nil
end

local function describeWindow(window)
    local app = window:application()
    local appName = app and app:name() or "Unknown App"
    local title = window:title()

    if title and title ~= "" then
        return string.format("%s - %s", appName, title)
    end

    return appName
end

local function frameSnapshot(window)
    local frame = window:frame()

    return {
        x = frame.x,
        y = frame.y,
        w = frame.w,
        h = frame.h,
    }
end

local function windowIndexForApp(window, app)
    if not app then
        return nil
    end

    local targetWindowId = window:id()
    local index = 0

    for _, candidate in ipairs(app:allWindows()) do
        if candidate and candidate:isStandard() then
            index = index + 1
            if candidate:id() == targetWindowId then
                return index
            end
        end
    end

    return nil
end

local function assignmentForWindow(window)
    local app = window:application()

    return {
        windowId = window:id(),
        appBundleID = app and app:bundleID() or nil,
        appName = app and app:name() or nil,
        title = window:title() or "",
        windowIndex = windowIndexForApp(window, app),
        frame = frameSnapshot(window),
    }
end

local function describeAssignment(assignment)
    if not assignment then
        return "Empty"
    end

    local appName = assignment.appName or "Unknown App"
    local title = assignment.title

    if title and title ~= "" then
        return string.format("%s - %s", appName, title)
    end

    return appName
end

local function truncateText(text, maxLength)
    if #text <= maxLength then
        return text
    end

    if maxLength <= 3 then
        return string.sub(text, 1, maxLength)
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

local function windowMatchesAssignment(window, assignment)
    if not window or not window:isStandard() then
        return false
    end

    local app = window:application()
    if not app then
        return false
    end

    if assignment.appBundleID and app:bundleID() ~= assignment.appBundleID then
        return false
    end

    if assignment.title and assignment.title ~= "" and window:title() == assignment.title then
        return true
    end

    return false
end

local function windowsForAssignment(assignment)
    if not assignment.appBundleID then
        return {}
    end

    local windows = {}

    for _, app in ipairs(hs.application.applicationsForBundleID(assignment.appBundleID)) do
        for _, window in ipairs(app:allWindows()) do
            if window and window:isStandard() then
                table.insert(windows, window)
            end
        end
    end

    return windows
end

local function frameDistance(firstFrame, secondFrame)
    return math.abs(firstFrame.x - secondFrame.x)
        + math.abs(firstFrame.y - secondFrame.y)
        + math.abs(firstFrame.w - secondFrame.w)
        + math.abs(firstFrame.h - secondFrame.h)
end

local function resolveWindow(assignment)
    local bundleWindows = windowsForAssignment(assignment)

    for _, candidate in ipairs(bundleWindows) do
        if windowMatchesAssignment(candidate, assignment) then
            return candidate
        end
    end

    if assignment.windowIndex and bundleWindows[assignment.windowIndex] then
        return bundleWindows[assignment.windowIndex]
    end

    if assignment.frame then
        local bestWindow = nil
        local bestDistance = nil

        for _, candidate in ipairs(bundleWindows) do
            local distance = frameDistance(frameSnapshot(candidate), assignment.frame)
            if not bestDistance or distance < bestDistance then
                bestWindow = candidate
                bestDistance = distance
            end
        end

        if bestWindow then
            return bestWindow
        end
    end

    if #bundleWindows == 1 then
        return bundleWindows[1]
    end

    if assignment.windowId then
        local existingWindow = hs.window.get(assignment.windowId)
        if existingWindow and existingWindow:isStandard() then
            return existingWindow
        end
    end

    return nil
end

local function launchAssignmentApplication(assignment)
    if assignment.appBundleID and hs.application.launchOrFocusByBundleID(assignment.appBundleID) then
        return true
    end

    if assignment.appName and assignment.appName ~= "" and hs.application.launchOrFocus(assignment.appName) then
        return true
    end

    return false
end

local function bindWindowToSlot(slot)
    local window = findUsableFrontmostWindow()
    if not window then
        return
    end

    local slots = loadSlots()
    slots[tostring(slot)] = assignmentForWindow(window)
    saveSlots(slots)

    alert(string.format("Saved slot %d: %s", slot, describeWindow(window)))
end

local function resizeFrontmostWindow(unit)
    local window = findUsableFrontmostWindow()
    if not window then
        return
    end

    window:moveToUnit(unit)
end

local function isPortraitScreen(screen)
    if not screen then
        return false
    end

    local frame = screen:frame()
    return frame.h > frame.w
end

local function resizeFrontmostWindowForScreen(landscapeUnit, portraitUnit)
    local window = findUsableFrontmostWindow()
    if not window then
        return
    end

    local screen = window:screen()
    if isPortraitScreen(screen) and portraitUnit then
        window:moveToUnit(portraitUnit)
        return
    end

    window:moveToUnit(landscapeUnit)
end

local function showSlotOverview()
    local slots = loadSlots()
    local lines = {}

    for slot = 1, SLOT_COUNT do
        local assignment = slots[tostring(slot)]
        table.insert(lines, string.format("%d: %s", slot, truncateText(describeAssignment(assignment), SLOT_OVERVIEW_LINE_MAX)))
    end

    alert(table.concat(lines, "\n"), SLOT_OVERVIEW_DURATION)
end

local function focusWindowSlot(slot, shouldLaunch, attemptsRemaining)
    local slots = loadSlots()
    local assignment = slots[tostring(slot)]

    if not assignment then
        alert(string.format("Slot %d is empty.", slot))
        return
    end

    local window = resolveWindow(assignment)
    if not window then
        if attemptsRemaining and attemptsRemaining > 0 then
            hs.timer.doAfter(0.4, function()
                focusWindowSlot(slot, false, attemptsRemaining - 1)
            end)
            return
        end

        if shouldLaunch and launchAssignmentApplication(assignment) then
            alert(string.format("Launching slot %d: %s", slot, describeAssignment(assignment)))
            hs.timer.doAfter(0.4, function()
                focusWindowSlot(slot, false, 8)
            end)
            return
        end

        alert(string.format("Slot %d window is unavailable.", slot))
        return
    end

    if window:isMinimized() then
        window:unminimize()
    end

    local app = window:application()
    if app then
        app:activate()
    end

    slots[tostring(slot)] = assignmentForWindow(window)
    saveSlots(slots)

    window:focus()
end

local function bindResizeHotkeys(modifiers)
    hs.hotkey.bind(modifiers, "left", function()
        resizeFrontmostWindow({ x = 0, y = 0, w = 0.5, h = 1 })
    end)

    hs.hotkey.bind(modifiers, "right", function()
        resizeFrontmostWindow({ x = 0.5, y = 0, w = 0.5, h = 1 })
    end)

    hs.hotkey.bind(modifiers, "up", function()
        resizeFrontmostWindow({ x = 0, y = 0, w = 1, h = 1 })
    end)
end

local function bindThirdResizeHotkeys(modifiers)
    hs.hotkey.bind(modifiers, "u", function()
        resizeFrontmostWindowForScreen(
            { x = 0, y = 0, w = 1 / 3, h = 1 },
            { x = 0, y = 0, w = 1, h = 1 / 3 }
        )
    end)

    hs.hotkey.bind(modifiers, "i", function()
        resizeFrontmostWindowForScreen(
            { x = 1 / 3, y = 0, w = 1 / 3, h = 1 },
            { x = 0, y = 1 / 3, w = 1, h = 1 / 3 }
        )
    end)

    hs.hotkey.bind(modifiers, "o", function()
        resizeFrontmostWindowForScreen(
            { x = 2 / 3, y = 0, w = 1 / 3, h = 1 },
            { x = 0, y = 2 / 3, w = 1, h = 1 / 3 }
        )
    end)
end

bindResizeHotkeys(TILE_MODS)
bindThirdResizeHotkeys(TILE_LETTER_MODS)

for slot = 1, SLOT_COUNT do
    local key = tostring(slot)
    hs.hotkey.bind(RECALL_MODS, key, function()
        focusWindowSlot(slot, true, nil)
    end)
    hs.hotkey.bind(SAVE_MODS, key, function()
        bindWindowToSlot(slot)
    end)
end

hs.hotkey.bind(RECALL_MODS, "0", showSlotOverview)

alert("Window slots loaded.")
