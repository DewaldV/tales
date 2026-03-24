+++
title = 'Proton Pass CLI: switching to the Secret Service keyring'
date = 2026-03-24T09:00:00Z
draft = false
tags = ['nixos', 'linux', 'security', 'ssh']
+++

In my [previous post](/posts/2026-03-07-proton-pass-migration/) I documented the migration from 1Password to Proton Pass and landed on a workaround for the main annoyance: `pass-cli` stores its local encryption key in the Linux kernel keyring, which is wiped on every reboot, forcing a manual `pass-cli login` before SSH keys could be loaded each morning.

Fortunately, Proton has now merged a change that makes this unnecessary and allows for a setup much closer to that of 1Password.

## The change

`pass-cli` now supports a `PROTON_PASS_LINUX_KEYRING` environment variable that selects which keyring backend it uses to store the encryption key ([docs](https://protonpass.github.io/pass-cli/get-started/configuration/#1-keyring-storage-default)):

| Value              | Backend                   | Persists across reboots |
|--------------------|---------------------------|-------------------------|
| `kernel` (default) | Linux kernel user keyring | No                      |
| `dbus`             | D-Bus Secret Service      | Yes                     |

Setting it to `dbus` makes `pass-cli` use the D-Bus Secret Service instead of the kernel keyring. On a desktop machine with GNOME Keyring running and unlocked at login, the encryption key now survives reboots.

This opens up the option for automatically loading our SSH keys on startup once the keyring is unlocked.

## The NixOS config change

My setup already had GNOME Keyring running and unlocked at login via PAM, so no additional plumbing was needed. If you're setting up from scratch check the [NixOS wiki](https://wiki.nixos.org/wiki/Secret_Service) for more information on setting this up.

Here is the full `profiles/base/proton-pass/home.nix` after all the changes:

```nix
# profiles/base/proton-pass/home.nix
{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  # Version 1.8.0 introduces PROTON_PASS_LINUX_KEYRING support.
  # Remove this override once 1.8.0 reaches nixpkgs-unstable.
  proton-pass-cli = pkgs-unstable.proton-pass-cli.overrideAttrs (old: {
    version = "1.8.0";
    src = pkgs-unstable.fetchurl {
      url = "https://proton.me/download/pass-cli/1.8.0/pass-cli-linux-x86_64";
      hash = "sha256-M7zWxVYHHjM86/l3K+0AR8QceiydP0n0sXj9rSctaeI=";
    };
  });
in

{
  home.packages = [ proton-pass-cli ];

  # Use the D-Bus Secret Service (GNOME Keyring) as the keyring backend so
  # that the pass-cli encryption key persists across reboots.
  home.sessionVariables = {
    PROTON_PASS_LINUX_KEYRING = "dbus";
  };

  # Auto-load SSH keys into the agent at login.
  systemd.user.services.proton-pass-ssh-load = {
    Unit = {
      Description = "Load Proton Pass SSH keys into agent";
      After = [
        "graphical-session.target"
        "gnome-keyring-daemon.service"
        "ssh-agent.service"
      ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "PROTON_PASS_LINUX_KEYRING=dbus"
        "SSH_AUTH_SOCK=%t/ssh-agent"
      ];
      ExecStart = "${proton-pass-cli}/bin/pass-cli ssh-agent load";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
```

The `overrideAttrs` block pins `pass-cli` to 1.8.0, the first release with `PROTON_PASS_LINUX_KEYRING` support. It can be removed once 1.8.0 reaches `nixpkgs-unstable` and `pkgs-unstable.proton-pass-cli` can be used directly.

The systemd service sets `PROTON_PASS_LINUX_KEYRING` and `SSH_AUTH_SOCK` directly in the `Service` block because user units don't inherit the session environment. `%t` is the systemd specifier for the user runtime directory (`/run/user/<uid>`), so `%t/ssh-agent` resolves to the same socket that `programs.ssh.startAgent` creates without hardcoding a UID.

The `After` ordering ensures the service waits for GNOME Keyring to be unlocked (so `pass-cli` can retrieve its encryption key via D-Bus) and for the SSH agent to be running (so there is a socket to load keys into). The store path is used directly in `ExecStart` rather than relying on `$PATH`, since systemd services don't inherit the user's shell environment.

Keys injected by `pass-cli ssh-agent load` live only in the agent's memory for the session. The keyring has no record of them, so the service needs to run on every login, which is exactly what `WantedBy = graphical-session.target` provides.

## One caveat

When `PROTON_PASS_LINUX_KEYRING=dbus` is set and the Secret Service is unreachable (e.g. in a headless SSH session without a D-Bus session bus), `pass-cli` fails hard rather than silently falling back to the kernel keyring. That is fine for a desktop setup where the keyring is always unlocked at login, but worth keeping in mind if you use `pass-cli` in a non-GUI context.
