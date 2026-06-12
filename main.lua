-- stopwatchtimer.koplugin/main.lua
-- StopWatch & Timer for KoReader

local Device = require("device")
local Screen = Device.screen
local Geom = require("ui/geometry")
local InputContainer = require("ui/widget/container/inputcontainer")
local TextBoxWidget = require("ui/widget/textboxwidget")
local ButtonTable = require("ui/widget/buttontable")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local Font = require("ui/font")
local Blitbuffer = require("ffi/blitbuffer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local LuaSettings = require("frontend/luasettings")
local DataStorage = require("datastorage")
local Datetime = require("frontend/datetime")
local T = require("ffi/util").template
local _ = require("gettext")
local PowerD = Device.powerd
local Notification = require("ui/widget/notification")
local Dispatcher = require("dispatcher")

local StopWatchTimerDisplay = InputContainer:extend{ props = {} }

function StopWatchTimerDisplay:init()
    self.now = os.time()
    self.paused = true
    self.mode = "stopwatch"
    self.timer_minutes = 5
    self.timer_end_time = nil
    self.pause_offset = 0
    self.alarmed = false
    self.paused_remaining = nil
    self.running_in_background = false
    self.refresh_scheduled = false

    self.ges_events = {}
    self.covers_fullscreen = true
    self.modal = true

    -- Do NOT create time_widget here anymore
    self[1] = self:render()
end

function StopWatchTimerDisplay:onShow()
    self[1] = self:render()
    UIManager:setDirty(self, "full")

    -- Device awake / Kindle / frontlight code (keep your existing block) ...

    if Device.powerd and Device.powerd.setSuspendTimeout then
        self.old_suspend_timeout = Device.powerd.setSuspendTimeout(math.huge)
    end

    -- Kindle T1 and frontlight code here (unchanged)...

    -- Refresh logic
    if self.refresh_scheduled then
        UIManager:unschedule(self.autoRefresh)
        self.refresh_scheduled = false
    end

    self:update()   -- initial paint

    -- Only start live updating if currently running
    if not self.paused and not self.refresh_scheduled then
        self.refresh_scheduled = true
        UIManager:scheduleIn(0.3, self.autoRefresh, self)
    end
end

function StopWatchTimerDisplay:onCloseWidget()
    if self.running_in_background then return end

    -- Full cleanup only on real exit
    if Device.powerd and Device.powerd.setSuspendTimeout and self.old_suspend_timeout then
        Device.powerd.setSuspendTimeout(self.old_suspend_timeout)
    end
    if self.kindle_t1_task then
        UIManager:unschedule(self.kindle_t1_task)
        self.kindle_t1_task = nil
    end
    if self.refresh_scheduled then
        UIManager:unschedule(self.autoRefresh)
        self.refresh_scheduled = false
    end
end

function StopWatchTimerDisplay:getTimeText()
    if self.mode == "stopwatch" then
        local elapsed = self.paused and self.pause_offset or (self.pause_offset + (os.time() - self.now))
        local _, m, s = Datetime.secondsToClock(elapsed, false, false):match("(%d+):(%d+):(%d+)")
        return T("%1:%2", m, string.format("%02d", s))
    else
        if not self.timer_end_time then
            self.timer_end_time = os.time() + self.timer_minutes * 60
        end
        local remaining = self.paused and (self.paused_remaining or math.max(0, self.timer_end_time - os.time())) or math.max(0, self.timer_end_time - os.time())
        if remaining == 0 then
            self:alarm()
            return "00:00"
        end
        local _, m, s = Datetime.secondsToClock(remaining, false, false):match("(%d+):(%d+):(%d+)")
        return T("%1:%2", m, string.format("%02d", s))
    end
end

function StopWatchTimerDisplay:alarm()
    if self.alarmed then return end
    self.alarmed = true
    UIManager:setDirty(nil, "flashui")
    if Device.canVibrate then Device:vibrate(500) end
end

function StopWatchTimerDisplay:update()
    local current_time_widget = self[1] and self[1][1] and self[1][1][3]  -- safe access to time_widget

    if not current_time_widget or not current_time_widget.setText then
        self[1] = self:render()
        UIManager:setDirty(self, "ui")
        return
    end

    local txt = self:getTimeText()
    if current_time_widget.text ~= txt then
        current_time_widget:setText(txt)
        -- Use light refresh when possible
        UIManager:setDirty(self, "ui")
    end
end

function StopWatchTimerDisplay:autoRefresh()
    self:update()
    UIManager:scheduleIn(0.5, self.autoRefresh, self)
end

function StopWatchTimerDisplay:onTogglePause()
    self.paused = not self.paused
    if self.paused then
        if self.mode == "stopwatch" then
            self.pause_offset = self.pause_offset + (os.time() - self.now)
        else
            self.paused_remaining = math.max(0, self.timer_end_time - os.time())
        end
    else
        if self.mode == "stopwatch" then
            self.now = os.time()
        else
            if self.paused_remaining and self.paused_remaining > 0 then
                self.timer_end_time = os.time() + self.paused_remaining
                self.paused_remaining = nil
            end
        end
    end

    self[1] = self:render()
    UIManager:setDirty(self, "full")
    
    -- Restart refresh loop only if now running
    if not self.paused and not self.refresh_scheduled then
        self.refresh_scheduled = true
        self:autoRefresh()
    end
end

function StopWatchTimerDisplay:onRestart()
    self.now = os.time()
    self.pause_offset = 0
    self.paused = false
    self.timer_end_time = nil
    self.alarmed = false
    self.paused_remaining = nil

    -- Force full rebuild + paint
    self[1] = self:render()
    UIManager:setDirty(self, "full")
    self:update()                    -- force immediate text update

    -- Ensure refresh loop is running
    if self.refresh_scheduled then
        UIManager:unschedule(self.autoRefresh)
    end
    self.refresh_scheduled = true
    UIManager:scheduleIn(0.2, self.autoRefresh, self)
end

function StopWatchTimerDisplay:goBackground()
    self.running_in_background = true
    if self.refresh_scheduled then
        UIManager:unschedule(self.autoRefresh)
        self.refresh_scheduled = false
    end
    UIManager:close(self)

    local mode_text = self.mode == "stopwatch" and _("Stopwatch") or _("Timer")
    UIManager:show(Notification:new{
        text = T(_("%1 running in background"), mode_text),
        timeout = 3,
    })

    UIManager:setDirty(nil, "flashpartial")
end

function StopWatchTimerDisplay:stopAndExit()
    self.running_in_background = false

    -- Fully stop the timing loop
    if self.refresh_scheduled then
        UIManager:unschedule(self.autoRefresh)
        self.refresh_scheduled = false
    end
    
    -- Reset state
    self.now = os.time()
    self.pause_offset = 0
    self.paused = true
    self.timer_end_time = nil
    self.alarmed = false
    self.paused_remaining = nil
    self.mode = "stopwatch"

    -- Update the displayed time BEFORE closing
	if self.time_widget then
		self.time_widget:setText("00:00")
	end
	
    -- Restore sleep behavior
    if Device.powerd and Device.powerd.setSuspendTimeout and self.old_suspend_timeout then
        Device.powerd.setSuspendTimeout(self.old_suspend_timeout)
    end
    if self.kindle_t1_task then
        UIManager:unschedule(self.kindle_t1_task)
        self.kindle_t1_task = nil
    end

    UIManager:close(self)
    UIManager:setDirty(nil, "flashpartial")
end

function StopWatchTimerDisplay:render()
    local s = Screen:getSize()

    -- Always recreate the time widget fresh
    self.time_widget = TextBoxWidget:new{
        text = self:getTimeText() or "00:00",  -- Use current text immediately
        face = Font:getFace(self.props.time_widget.font_name or "cfont", self.props.time_widget.font_size or 220),
        width = Screen:getWidth(),
        height = math.floor(Screen:getHeight() * 0.6),
        alignment = "center",
        bold = true,
    }

    local mode_btn = self.mode == "stopwatch" and _("Timer") or _("Stopwatch")
    local row = {
        { text = _("← Background"), callback = function() self:goBackground() end },
        { text = mode_btn, callback = function() self:toggleMode() end },
    }

    if self.mode == "timer" then
        table.insert(row, {
            text_func = function() return self.paused and _("Resume") or _("Pause") end,
            callback = function() self:onTogglePause() end
        })
        table.insert(row, {
            text = T(_("Set Time (%1 min)"), self.timer_minutes),
            callback = function() self:setTimerMinutes() end
        })
    else
        table.insert(row, {
            text_func = function() return self.paused and _("Resume") or _("Pause") end,
            callback = function() self:onTogglePause() end
        })
    end

	table.insert(row, {
		text_func = function()
			return self.paused and _("Start") or _("Restart")
		end,
		callback = function() self:onRestart() end
	})

    table.insert(row, { text = _("Stop & Exit"), callback = function() self:stopAndExit() end })

    self.buttons = ButtonTable:new{
        width = math.floor(s.w * 0.9),
        buttons = { row },
    }

    local content = VerticalGroup:new{
        align = "center",
        VerticalSpan:new{ height = math.floor(s.h * 0.15) },
        self.time_widget,
        VerticalSpan:new{ height = math.floor(s.h * 0.1) },
        self.buttons,
    }

    local frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        dimen = s,
        CenterContainer:new{ dimen = s, content },
    }

    return frame
end

function StopWatchTimerDisplay:toggleMode()
    self.mode = self.mode == "stopwatch" and "timer" or "stopwatch"
    self.paused = false
    self.pause_offset = 0
    self.alarmed = false
    self.paused_remaining = nil
    self.now = os.time()

    if self.mode == "timer" then
        -- Immediately set a fresh timer when switching to timer mode
        self.timer_end_time = os.time() + self.timer_minutes * 60
    else
        self.timer_end_time = nil
    end

    self[1] = self:render()
	UIManager:setDirty(self, "full")
	UIManager:forceRePaint()   -- add this line (helps after background)    
end

function StopWatchTimerDisplay:setTimerMinutes()
    local options = {5, 10, 15, 20, 25, 30}
    local current_idx = 1
    for i, v in ipairs(options) do
        if v == self.timer_minutes then current_idx = i; break end
    end
    local next_idx = (current_idx % #options) + 1
    self.timer_minutes = options[next_idx]
    self.timer_end_time = os.time() + self.timer_minutes * 60
    self.alarmed = false
    self.paused = false
    self.paused_remaining = nil
    self[1] = self:render()
	UIManager:setDirty(self, "full")
	UIManager:forceRePaint()   -- add this line (helps after background)    
end

-- Plugin entry
local StopWatchTimer = WidgetContainer:extend{ name = "stopwatchtimer", config_file = "stopwatchtimer_config.lua" }

function StopWatchTimer:init()
    local path = DataStorage:getSettingsDir() .. "/" .. self.config_file
    self.settings = LuaSettings:open(path)
    if not self.settings.data.time_widget then
        self.settings:reset{
            time_widget = { font_name = "./fonts/noto/NotoSans-Bold.ttf", font_size = 220 },
        }
        self.settings:flush()
    end

    -- Create the shared display widget once
    self.display_widget = StopWatchTimerDisplay:new{ props = self.settings.data }

    self.ui.menu:registerToMainMenu(self)

    -- Register the action for Gesture Manager
    Dispatcher:registerAction("stopwatch_timer_show", {
        category = "none",
        event = "ShowStopWatchTimer",
        title = _("StopWatch / Timer"),
        general = true,
        icon = "plugins/stopwatchtimer.koplugin/stopwatch.svg",
    })
end

function StopWatchTimer:onStopwatchTimer()
    self:onShow()         
end

function StopWatchTimer:addToMainMenu(menu_items)
    menu_items.StopWatchTimer = {
        text = _("StopWatch / Timer"),
        sorting_hint = "more_tools",
        callback = function()
            UIManager:show(self.display_widget)
            self.display_widget:onShow()   -- let onShow handle everything
        end,
    }
end

function StopWatchTimer:onShowStopWatchTimer()
    UIManager:show(self.display_widget)
    self.display_widget:onShow()
end

return StopWatchTimer
