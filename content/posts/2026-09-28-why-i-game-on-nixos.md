+++
title = 'Why I game on NixOS'
date = 2026-09-28T00:00:00Z
draft = false
tags = ['nixos', 'linux', 'gaming']
+++

I booted up Helldivers 2 one night, eager to defend managed democracy with friends. When the game launched on my NixOS desktop, the framerate had tanked: I was getting 20–30 FPS before even launching a mission. I'd updated my machine earlier that day, so I asked my friends to give me a minute while I rebooted into the previous system generation.

Back at the desktop, I launched Helldivers 2 again and it was smooth as butter. After saying goodnight to my friends, I tracked the problem down to a Mesa version bump in the last batch of updates. The update had broken the game, but rolling back meant I didn't have to fix it before we could play.

## I didn't switch for the games

I gamed on Windows for many years before making the switch to Pop!_OS around 2021. Pop!_OS was stable for me overall, but one upgrade broke a game and took a while to sort out. Trying to move away from GNOME also turned into quite a task. By then I had started using NixOS on my work laptop for development, and I really liked being able to try software, change my configuration and roll back when something went wrong. I wondered whether that approach would help on my gaming desktop and laptop too.

NixOS didn't prevent the Helldivers 2 regression. What helped was having a known-good [system generation](https://nixos.org/manual/nixos/stable/#sec-changing-config) ready: rebooting into it brought back the previous package versions and configuration together, including Mesa. Booting an older kernel alone wouldn't have undone that Mesa update. Other distros can roll back to a snapshot, but NixOS keeps previous generations available to boot into without requiring me to set up snapshots first.

## One configuration across several machines

I manage a desktop, personal and work laptops, a home server and VMs with Nix. I've also used a MacBook for work occasionally. The value grows when changes can be shared across those machines: my Sway environment, keybindings, shell tools, Doom Emacs, locale, networking, firewall, Tailscale configuration and much more all live in the same [configuration repository](https://github.com/DewaldV/nixos).

One small example is Waybar. I spent time getting the layout, icons and spacing right on my desktop. Once I changed the configuration, the same layout appeared on my laptop, with everything where I expected it. The next tweak went across too. Whether I'm at my gaming desktop or on a laptop, I don't have to rebuild a familiar environment: the choices are written down in code and shared by the machines.

I've managed machines with Babushka and a dotfiles repository before, but Nix goes further. NixOS modules let me configure services, not just install packages and then edit files by hand. [Home Manager](https://nix-community.github.io/home-manager/) extends that approach to user-level tools and configuration. A Git commit can become part of the configuration history of every machine I run, rather than a change I have to remember to make again elsewhere.

## What I actually play

This isn't a machine built around one game or one storefront. I've played Helldivers 2 and Deep Rock Galactic with friends, revisited Little Big Adventure and the King's Quest games, and spent plenty of time with CRPGs such as Pathfinder: Kingmaker, Temple of Elemental Evil and Baldur's Gate. I run Heroic Games Launcher for games from Epic and GoG and ScummVM for some of my favourite adventure games.

I run the [Sway](https://swaywm.org/) tiling window manager for my desktop. I wanted a small, keyboard-driven Wayland environment I could understand and configure myself. Xwayland has been sufficient for the games I play, and I can boot into [gamescope](https://github.com/ValveSoftware/gamescope) for HDR gaming. That setup suits me, but it isn't a requirement for playing games on Linux.

## Where it gets awkward

NixOS does add friction. A Pathfinder: Kingmaker respec mod wouldn't display its fonts in my usual Steam installation, leaving an empty interface. I eventually used Flatpak Steam, which had the fonts it needed, but keeping two Steam installations wasn't an elegant solution.

Standalone Linux binaries can be troublesome because NixOS doesn't put libraries where many binaries expect them. [Steam games](https://wiki.nixos.org/wiki/Steam) benefit from work the NixOS community has already done, but outside that path you need to understand more about how NixOS handles binaries and dependencies. I also gave up trying to install the Circle of Eight mod for Temple of Elemental Evil when its Windows JRE requirement became a hassle under Wine. That last one is more a Linux gaming problem than a NixOS problem, but it still affected what I could do on this machine.

## Who I'd recommend it to

I'd recommend NixOS for gaming if you want to configure your system in depth and manage it as code, especially if you have several machines. The learning curve pays me back in shared configuration and in the ability to return to a working system when an update goes wrong.

If the goal is simply to play games on Linux, I'd point someone towards Bazzite, Nobara or CachyOS instead. NixOS is the right gaming OS for me because it is the right way for me to manage my computers. The games come along for the ride.
