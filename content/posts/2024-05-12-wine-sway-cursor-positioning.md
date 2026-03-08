+++
title = 'A sway misclick'
date = 2024-05-12T12:48:00Z
draft = false
tags = ['linux', 'sway', 'gaming', 'wayland', 'debugging']
+++

On a Sunday morning I sat down to start playing a Steam game via Proton on my Framework 13 laptop. Upon booting into the game I noticed that the cursor tracked perfectly, moving exactly where I expected it to, but clicks never registered. I could hover over a button in the game, click, and nothing would happen.

I hadn't used the laptop for gaming in a long while, the Steam Deck had mostly taken over that role, but I had a hankering for a more mouse-driven game and the Framework 13 has plenty of power for these cases.

## The setup

I run [Sway](https://swaywm.org/) as my tiling window manager of choice and have multiple outputs defined for when the laptop is docked at my desk. I had a suspicion that this had something to do with my multi-monitor setup since the game I was playing had worked great on my Desktop (where I only have 1 monitor) on the exact same NixOS setup.

My sway config looked like this:

```console
output "eDP-1" {
  scale = "1.5";
  pos = "760 1440";
}

output "HDMI-A-1" {
  mode = "3440x1440@100Hz";
  pos = "0 0";
}
```

The `pos` on `eDP-1` offsets the laptop display below and to the right of my desk monitor, so when both are connected the layout makes sense. The problem is that this config is always active, even when the laptop is undocked and `eDP-1` is the only display.

## What was happening

This turns out to be a [known Sway bug](https://github.com/swaywm/sway/issues/6651). With `eDP-1` positioned at `(760, 1440)` in the compositor's coordinate space, the game's cursor rendering and click coordinates diverge. The cursor draws at the correct visual position on screen, but Xorg applications (including games running via Proton/Wine) send click events using coordinates that include the `pos` offset. So the compositor receives a click at `(760 + x, 1440 + y)` when the game intended `(x, y)`. With no other display connected, those offset coordinates land outside the visible area.

Wayland-native applications are unaffected, this only hits Xorg applications running through XWayland.

## The fix

I set `eDP-1` to `pos = "0 0"`. Since I don't frequently use the laptop display alongside the desktop monitor, there's no need for the offset to be permanently set:

```console
output "eDP-1" {
  scale = "1.5";
  pos = "0 0";
}
```

After applying the config, clicks registered immediately.

For a proper solution that handles both docked and undocked layouts, [Kanshi](https://wiki.archlinux.org/title/Kanshi) can switch output profiles automatically based on which displays are connected. Something to set up if I start hotplugging displays more regularly.
