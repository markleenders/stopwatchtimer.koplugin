# StopWatch & Timer for KoReader

A clean and reliable stopwatch + countdown timer plugin for [KoReader](https://koreader.rocks/).

## Features

- **Stopwatch** with millisecond-accurate timing
- **Countdown Timer** (5, 10, 15, 20, 25, 30 minute presets — cycles with "Set Time")
- **Background support** — continue running while reading
- **Pause / Resume / Start / Restart** functionality
- Large, easy-to-read display
- Works well on e-ink devices (minimal flashing)
- Keeps device awake while the plugin is open

## Installation

1. Download the latest release (`stopwatchtimer.koplugin-v1.0.5.zip`)
2. Unzip it into your KoReader `plugins/` folder:   plugins/stopwatchtimer.koplugin/
3. Restart KoReader
4. The plugin will appear in the menu under **More tools → StopWatch / Timer**

You can also assign a gesture or use the Dispatcher to create a quick shortcut.

## Usage

- **Start** — begins the stopwatch or timer
- **Pause / Resume** — pauses or continues the current session
- **Restart** — resets and immediately starts again
- **Background** — sends the timer to the background (notification shown)
- **Stop & Exit** — stops everything and closes the plugin
- **Timer mode** — use "Set Time" to cycle through preset minutes

## Screenshots

Stopwatch running:
<img width="400" height="600" alt="StopWatch-Running" src="https://github.com/user-attachments/assets/3068854b-667c-4bf1-8267-aea62e3dfce8" />

Stopwatch paused:
<img width="400" height="600" alt="StopWatch-Paused" src="https://github.com/user-attachments/assets/dda778de-b663-46b0-902a-a9fd9bcfdf46" />)

Timer running:
<img width="400" height="600" alt="Timer-Running" src="https://github.com/user-attachments/assets/0a2a5c1c-bb5b-4700-ac1e-72e88c59dcc3" />

## Changelog

### v1.0.5 
- Improved refresh handling (1-second interval for better battery life)
- More reliable display after background / reopen
- Dynamic "Start" / "Restart" button text
- Cleaner internal code structure

### v1.0.4
- Updated and clean up code, screenshots

## License

MIT License — feel free to fork and improve!

## Credits

Developed with help from Grok (xAI).


