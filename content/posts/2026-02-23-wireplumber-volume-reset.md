+++
title = 'Debugging a WirePlumber volume reset on boot'
date = 2026-02-23T09:00:00Z
draft = true
tags = ['nixos', 'linux', 'audio', 'pipewire', 'debugging']
+++

Every boot, my volume came up at 100%. I could turn it down during a session and it would stay put, but the next reboot it was back to blasting. Annoying enough to actually dig into.

## First hypothesis: stale state files

WirePlumber saves volume state to `~/.local/state/wireplumber/`. The obvious first suspect was a stale or corrupt state file. Checking the files, `restore-stream` hadn't been modified since June 2024 — a clear sign something was off. This turned out to be an old WirePlumber 0.4.x format file that 0.5.x no longer writes to, but was still reading from on boot. It had `volume=1.0` baked in.

Cleared the whole state directory and restarted WirePlumber. Set the volume, rebooted. Still 100%.

## The pavucontrol clue

The most useful observation came from restarting WirePlumber manually:

```
systemctl --user restart wireplumber
```

Volume goes to 100%. Then opening `pavucontrol` — without touching any controls — silently drops it back to 50%.

That told me the saved state was fine and the restore mechanism worked. It just wasn't triggering at init time. The volume was only being applied when a PulseAudio client connected.

## ALSA mixer failures

Looking at the WirePlumber journal with debug logging enabled, every restart showed the same errors: `spa.alsa: Unable to load mixer: Broken pipe`. With verbose output, all 12 errors were exclusively on `hw:3` — the Schiit Fulla DAC — across four retry cycles during ACP profile probing. The other three cards (HDMI, onboard, webcam) attached to their mixers without issue.

This matters because WirePlumber uses the ALSA mixer handle to apply saved route volumes to the device. No mixer, no volume restore. The fallback is the hardware default — 1.0.

The `pavucontrol` workaround worked because it goes through the PipeWire/PA compat layer rather than the ALSA mixer path, which successfully applied the saved state.

## Tracing it to the kernel

The kernel log had one relevant line, logged 9 seconds after the Schiit enumerated:

```
usb 1-5.4.3: 17:0: failed to get current value for ch 0 (-32)
```

Error `-32` is `EPIPE` — Broken Pipe at the USB level. The `snd_usb_audio` driver tried to send a `GET_CUR` control request to read the current volume from the device's feature unit, the USB endpoint stalled, and that permanently broke the ALSA mixer handle for the rest of the session.

Confirmed this by running `amixer -c 3 info` later in the session — still returning `Broken pipe`, long after boot. Not a timing issue, a permanent stall.

## The fix

`snd_usb_audio` has a module parameter for exactly this: `ignore_ctl_error=1`. It tells the driver to log and continue when a USB audio control request fails, rather than stalling the endpoint. With it set, the EPIPE is recorded but the mixer handle stays usable, WirePlumber can attach to it, and volume state is saved and restored correctly.

In NixOS this goes in `boot.extraModprobeConfig`:

```nix
boot.extraModprobeConfig = ''
  options snd_usb_audio ignore_ctl_error=1
'';
```

Reboot, volume came up at 50%. Fixed.

## What was actually happening

The Schiit Fulla stalls on a `GET_CUR` USB audio control request during `snd_usb_audio` initialisation at boot. That stall breaks the ALSA mixer handle. WirePlumber then fails to attach its mixer API to the device, falls back to the hardware default volume (1.0 = 100%), and has no way to apply or persist volume state through the normal route. The `ignore_ctl_error` parameter suppresses the stall, keeps the mixer handle alive, and everything downstream works as expected.
