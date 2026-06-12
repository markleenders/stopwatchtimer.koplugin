# Stopwatch & Timer for KOReader

A [koreader][1] plugin to display a stopwatch or a timer in a fullscreen widget.
A clean, fullscreen, perfectly centered stopwatch with Pause / Resume and Restart buttons.
And a timer which you can set in 5 minute increments from 5 up to 30 minutes with a Restart button.

## Motivation

I sometimes need a stopwatch or a timer, so why not use my ereader?
You can even send it to the background.
Should work on every KOReader device (Kobo, PocketBook, Android, Linux…).

## Installation

The quickest way is to install (and update) the plugin with the [App Store](https://github.com/omer-faruq/appstore.koplugin).
Or you can do it manually:

1. Go to the [releases page](https://github.com/markleenders/stopwatchtimer.koplugin/releases).
2. Download the `stopwatchtimer.koplugin.zip` file from the latest release.
3. Extract and copy the `stopwatchtimer.koplugin` folder into the `plugins` directory of your KOReader installation.
4. Restart KOReader to load the plugin.

## Usage

Navigate to `Plugins -> More tools -> StopWatch / Timer` to open the widget. Tap
anywhere on the screen (outside of the buttons) to close the widget. Use the buttons to pause/resume or restart.
Or use the toggle button to switch between the stopwatch and the timer. In Timer mode there's a button to add 5 minutes to 
the timer.

## Testing

Tested with Koreader 2025.10 on a Kobo Clara 2E and linux.

[1]: https://github.com/koreader/koreader

## Quick Action
You can link a gesture to the stopwatch or in Simple-UI create a quick action.
Select the action stopwatch_timer_show and for an icon select EC1A from the Nerd Font

## Screenshots

Stopwatch Running:

<img width="1072" height="1448" alt="StopWatch-Running" src="https://github.com/user-attachments/assets/3068854b-667c-4bf1-8267-aea62e3dfce8" />

Stopwatch Paused:
<img width="1072" height="1448" alt="StopWatch-Paused" src="https://github.com/user-attachments/assets/dda778de-b663-46b0-902a-a9fd9bcfdf46" />

Timer Running:
<img width="1072" height="1448" alt="Timer-Running" src="https://github.com/user-attachments/assets/0a2a5c1c-bb5b-4700-ac1e-72e88c59dcc3" />



