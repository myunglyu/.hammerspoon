local LGRemote = {}
local json = require("hs.json")

LGRemote.config_path = os.getenv("HOME") .. "/.hammerspoon/lg_remote/config.json"
LGRemote.remote_binary = os.getenv("HOME") .. "/.hammerspoon/lg_remote/lg_remote"

-- Function to initialize TV control
function LGRemote.init()
    -- Check if config file exists
    local tvConfig = io.open(LGRemote.config_path, "r")

    if not tvConfig then
        local found_ip = LGRemote.scanForTV()
        if found_ip then
            LGRemote.authenticateTV(found_ip)
        else
            hs.alert.show("Failed to find LG TV.")
            return
        end
    end

    -- Load the config file
    local input_id = io.open(os.getenv("HOME") .. "/.hammerspoon/lg_remote/pc_input_id.txt", "r")
    
    if not input_id then
        LGRemote.getInputId()
    end

    LGRemote.bindKeys()

    -- Start the watcher
    LGRemote.watcher:start()

end

-- Function to scan for LG TVs if no config is found
function LGRemote.scanForTV()
    hs.alert.show("Scanning for LG TV...")

    -- Use absolute path for reliability
    local scan_cmd = LGRemote.remote_binary .. " scan"
    
    -- Execute scan command and capture JSON output
    local output = hs.execute(scan_cmd, true)

    if output and output ~= "" then
        -- Parse JSON output
        local parsed_output = json.decode(output)
        
        if parsed_output and parsed_output.result == "ok" and parsed_output.count > 0 then
            local tv_info = parsed_output.list[1]  -- Get first TV in the list
            if tv_info and tv_info.address then
                hs.alert.show("LG TV found at " .. tv_info.address)
                return tv_info.address
            end
        end
    end

    hs.alert.show("No LG TV found.")
    return nil
end

-- Function to run authentication
function LGRemote.authenticateTV(ip)
    hs.alert.show("Authenticating with LG TV...")
    local auth_cmd = string.format("%s --ssl auth %s TV", LGRemote.remote_binary, ip)
    hs.execute(auth_cmd, true)
    hs.alert.show("Authentication complete!")
end

-- Function to get input ID for PC
function LGRemote.getInputId()
    local cmd = LGRemote.remote_binary .. " -n TV --ssl listInputs"
    local handle = io.popen(cmd)  -- Run command and capture output
    local output = handle:read("*a")
    handle:close()

    -- Pattern match to extract the HDMI ID for "PC"
    local hdmi_id = output:match('"id"%s*:%s*"([^"]+)"%s*,%s*"label"%s*:%s*"PC"')

    if hdmi_id then
        hs.alert.show("PC input ID: " .. hdmi_id)
        
        -- Save the HDMI ID to a file
        local file_path = os.getenv("HOME") .. "/.hammerspoon/lg_remote/pc_input_id.txt"
        local file = io.open(file_path, "w")  -- Open file for writing
        if file then
            file:write(hdmi_id)
            file:close()
            hs.alert.show("Saved PC input ID to file: " .. file_path)
        else
            hs.alert.show("Error: Could not write to file!")
        end

        return hdmi_id
    end

    hs.alert.show("No matching input found for label: PC")
    return nil
end

-- Function to set input source to PC
function LGRemote.setInput()

    local file_path = os.getenv("HOME") .. "/.hammerspoon/lg_remote/pc_input_id.txt"

    -- Attempt to load the saved input ID from file
    local file = io.open(file_path, "r")
    local input_id

    if file then
        input_id = file:read("*a")  -- Read the saved HDMI ID
        file:close()
    else
        hs.alert.show("PC input ID file not found. Running scan...")
        input_id = LGRemote.getInputId()  -- Run scan if file does not exist
    end


    -- If input_id was retrieved, set the input
    if input_id then
        LGRemote.tvCommand("setInput " .. input_id)
        -- hs.alert.show("Input set to PC: " .. input_id)
    else
        hs.alert.show("Error: Could not determine PC input ID.")
    end
end


-- Function to send commands to the TV
function LGRemote.tvCommand(command)
    local cmd = LGRemote.remote_binary .. " -n TV --ssl " .. command
    hs.execute(cmd, false)

end

function LGRemote.bindKeys()

    -- Command key combinations
    local hotkey_map = {
        -- TV Power Control
        ['cmd+ctrl+p'] = { command = "on", message = "TV Powering On" },
        ['cmd+ctrl+o'] = { command = "off", message = "TV Powering Off" },
        ['cmd+ctrl+1'] = { command = "setInput HDMI_1", message = "" },
        ['cmd+ctrl+2'] = { command = "setInput HDMI_2", message = "" },
        ['cmd+ctrl+3'] = { command = "setInput HDMI_3", message = "" },
        ['cmd+ctrl+4'] = { command = "setInput HDMI_4", message = "" },
        
        -- Volume Control with Command key
        ['cmd+ctrl+up'] = { command = "volumeUp", message = "Volume Up" },
        ['cmd+ctrl+down'] = { command = "volumeDown", message = "Volume Down" },
        ['cmd+ctrl+m'] = { command = "mute", message = "Mute Toggle" }
    }

    -- Bind hotkeys
    for key, action in pairs(hotkey_map) do
        local mods = {}
        for mod in key:gmatch("([^%+]+)%+?") do
            if mod ~= "cmd" and mod ~= "shift" and mod ~= "alt" and mod ~= "ctrl" then
                -- This is the key, not a modifier
                local k = mod
                hs.hotkey.bind(mods, k, function()
                    if action.command == "mute" then
                        -- Create task to check audio status
                        local task = hs.task.new(LGRemote.remote_binary, function(exitCode, stdOut, stdErr)
                            if exitCode == 0 and stdOut then
                                if stdOut:match('"muteStatus"%s*:%s*false') then
                                    LGRemote.tvCommand("mute true")
                                else
                                    LGRemote.tvCommand("mute false")
                                end
                                hs.alert.show(action.message)
                            else
                                hs.alert.show("Failed to get audio status")
                            end
                        end, {"-n", "TV", "--ssl", "audioStatus"})
                        
                        -- Start the task
                        if not task:start() then
                            hs.alert.show("Failed to check audio status")
                        end
                    else
                        -- For non-mute commands
                        LGRemote.tvCommand(action.command)
                        hs.alert.show(action.message)
                    end
                end)
            else
                table.insert(mods, mod)
            end
        end
    end

    -- Media Key Mapping for System Keys
    local key_actions = {
        -- SOUND_UP = "volumeUp",   -- Volume Up
        -- SOUND_DOWN = "volumeDown", -- Volume Down
        -- MUTE = "mute"            -- Mute Toggle
    }

    -- Eventtap Listener for Media Keys
    -- LGRemote.audio_event_tap = hs.eventtap.new(
    --     {hs.eventtap.event.types.systemDefined},
    --     function(event)
    --         local system_key = event:systemKey()
            
    --         -- Ensure `system_key` exists before using it
    --         if system_key and system_key.down then
    --             local pressed_key = system_key.key
    --             local command = key_actions[pressed_key]

    --             if command then
    --                 LGRemote.tvCommand(command)
    --                 return true  -- Block system volume control (optional)
    --             end
    --         end
    --         return false
    --     end
    -- )

    -- Start listening for media keys
    -- LGRemote.audio_event_tap:start()

end

-- -- Function to turn the TV off when Mac sleeps
-- function LGRemote.turnOffTV()
--     hs.alert.show("Mac is sleeping: Turning off TV...")
--     LGRemote.tvCommand("off")
-- end

-- -- Function to turn the TV on when Mac wakes
-- function LGRemote.turnOnTV()
--     LGRemote.tvCommand("on")
-- end

function LGRemote.checkOtherDevices()

    -- Fetch current inputs to check connected devices
    local cmd =  LGRemote.remote_binary .. " -n TV --ssl listInputs"
    local handle = io.popen(cmd)  -- Run command and capture output
    local output = handle:read("*a")
    handle:close()

    -- Count how many devices are currently connected
    local connected_count = 0
    for _ in output:gmatch('"connected"%s*:%s*true') do
        connected_count = connected_count + 1
    end

    -- If two or more devices are connected, prevent input change
    return connected_count < 2

end

-- Watcher for system sleep/wake events
LGRemote.watcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.screensDidSleep then
        if LGRemote.checkOtherDevices() then
            hs.timer.doAfter(15, function() 
                hs.execute(LGRemote.remote_binary .. " -n TV --ssl off", false)
            end)
        end
    elseif event == hs.caffeinate.watcher.screensDidWake then
        LGRemote.tvCommand("on")
        if LGRemote.checkOtherDevices() then 
            hs.timer.doAfter(3, function()
                LGRemote.setInput() end) -- Set input to PC after 3 seconds
        end
    end
end)

return LGRemote