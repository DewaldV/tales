+++
title = 'A small Apple TV remote for my terminal'
date = 2026-11-13T09:00:00Z
draft = false
tags = ['apple-tv', 'python', 'linux', 'privacy']
+++

I recently got an Apple TV to replace my older Chromecast setup. As an Android user, I don't have an iPhone to take advantage of Apple's more integrated setup process, so I had to set it up manually. That meant typing logins and passwords with the included remote and an on-screen keyboard. Not the greatest user experience, especially when the passwords aren't exactly short.

My first thought was to grab a remote app from the Play Store, but the options I looked at either had ads, wanted a subscription, or had reviews raising concerns about data collection. For something that sends button presses to a box on my own network, that felt like a lot of baggage.

So I decided to build a small Android remote app of my own that I could sideload. To test the idea before tackling the Android interface, I used OpenCode to put together a terminal version on my Linux machine and test it with my Apple TV 4K.

## Getting the basics working

I used [pyatv](https://pyatv.dev/documentation/supported_features/) for pairing, navigation, and keyboard input over Apple's Companion protocol.

The remote discovers devices on the local network, pairs using a PIN displayed on the TV, and remembers the credentials for next time. Commands such as `/up`, `/down`, `/select`, and `/back` handle navigation. Once a text field is open on the TV, a line typed in the terminal replaces its contents.

## Running it

I published the code as [apple-tv-remote](https://github.com/DewaldV/apple-tv-remote) under the MIT licence. It needs Python 3.11 or newer and [uv](https://docs.astral.sh/uv/), with the computer and Apple TV on the same local network.

```console
git clone https://github.com/DewaldV/apple-tv-remote.git
cd apple-tv-remote
uv run remote.py
```

If discovery fails, supply the TV's IP address instead, replacing this example with your own:

```console
uv run remote.py --host 192.168.1.50
```

After pairing, open a search field on the TV and type at the `TV>` prompt. Enter sends the text; it does not submit the TV's form. `/append TEXT` adds to the existing text, `/clear` empties it, and `/help` lists the other commands. Text input depends on the app exposing a compatible field.

An example session, with a placeholder IP address and the command help shortened:

```console
$ uv run remote.py --host 192.168.1.50 --pair
Looking for Apple TVs on the local network…
  1. Living Room (192.168.1.50) - Apple TV 4K (gen 3), tvOS
Look for a pairing PIN on your television.
TV PIN: ****
Paired. Credentials saved locally for next time.
Connecting to Living Room…

Open a text field on the Apple TV, type a line here, and press Enter.
Each line REPLACES the field's text. Enter sends text, not a TV submit action.
...
TV> /status
Keyboard focus: Focused
TV> Severance
Text command sent. Check the field on your TV.
TV> /quit
```

## A useful first step

I now have a working remote with local pairing credentials, no analytics, and no backend service. I may not even need the Android app in the end. In fact, I'm considering a small web app running on my home server that I could open in a browser on my mobile instead.

The terminal version is useful on its own though, especially in a world of longer and longer passwords.
