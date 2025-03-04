# LG Remote Control Script for Hammerspoon

This Hammerspoon script allows you to control your LG TV using keyboard shortcuts and automate TV actions based on your Mac's sleep/wake events. It leverages the [LGWebOSRemote](https://github.com/klattimer/LGWebOSRemote) tool to communicate with the TV.

## Features

- **Automatic Initialization**: The script automatically scans for your LG TV and authenticates it if no configuration is found.
- **Keyboard Shortcuts**: Control TV power, input source, and volume using customizable keyboard shortcuts.
- **Sleep/Wake Automation**: Automatically turns off the TV when your Mac goes to sleep and turns it on when your Mac wakes up.
- **Input Source Management**: Automatically sets the TV input to "PC" after waking up.
- **Device Connection Check**: Prevents input changes if multiple devices are connected to the TV.

## Prerequisites

- **Hammerspoon**: Ensure Hammerspoon is installed on your Mac. You can download it from [Hammerspoon](https://www.hammerspoon.org/).

## Installation Steps

1. **Download the Archive File**: Download the archive file containing the `lg_remote.lua` script.

2. **Unzip the Archive**: Unzip the downloaded archive file into your Hammerspoon configuration directory (`~/.hammerspoon`).

3. **Load the Script**: Add the following line to your `~/.hammerspoon/init.lua` file to load the `lg_remote.lua` script:
    ```lua
    local LGRemote = require("lg_remote")

    LGRemote.init()

    hs.alert.show("LG TV Remote Loaded in Hammerspoon")
    ```

4. **Set TV Input Name**: Ensure the input name on your LG TV is set to "PC".

## Usage

The script will automatically initialize and start controlling your TV based on the defined keyboard shortcuts and sleep/wake events.

### Keyboard Shortcuts

- `cmd+ctrl+p`: Power On
- `cmd+ctrl+o`: Power Off
- `cmd+ctrl+1`: Set Input to HDMI 1
- `cmd+ctrl+2`: Set Input to HDMI 2
- `cmd+ctrl+3`: Set Input to HDMI 3
- `cmd+ctrl+4`: Set Input to HDMI 4
- `cmd+ctrl+up`: Volume Up
- `cmd+ctrl+down`: Volume Down
- `cmd+ctrl+m`: Mute Toggle

## License

This project is licensed under the MIT License.