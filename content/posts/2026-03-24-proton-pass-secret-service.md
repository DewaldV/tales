+++
title = 'Proton Pass CLI: switching to the Secret Service keyring'
date = 2026-03-24T09:00:00Z
draft = true
tags = ['nixos', 'linux', 'security', 'ssh']
+++

In my [previous post](/posts/2026-03-07-proton-pass-migration/) I documented the migration from 1Password to Proton Pass and landed on a workaround for the main annoyance: `pass-cli` stores its local encryption key in the Linux kernel keyring, which is wiped on every reboot, forcing a manual `pass-cli login` before SSH keys could be loaded each morning.

Proton has now merged a change that makes this unnecessary.

## The change

`pass-cli` now supports a `PROTON_PASS_LINUX_KEYRING` environment variable that selects which keyring backend it uses to store the encryption key ([docs](https://protonpass.github.io/pass-cli/get-started/configuration/#1-keyring-storage-default)):

| Value | Backend | Persists across reboots |
|---|---|---|
| `kernel` (default) | Linux kernel user keyring | No |
| `dbus` | D-Bus Secret Service | Yes |

Setting it to `dbus` makes `pass-cli` use the D-Bus Secret Service instead of the kernel keyring. On a desktop machine with GNOME Keyring running and unlocked at login, the encryption key now survives reboots.

## The NixOS config change

My setup already had GNOME Keyring running and unlocked at login via PAM, so no additional plumbing was needed. The full change in my NixOS config was:

```nix
# profiles/base/proton-pass/home.nix

home.sessionVariables = {
  PROTON_PASS_LINUX_KEYRING = "dbus";
};

programs.zsh.shellAliases = {
  # login step is no longer needed after reboot
  pass-ssh-load = "pass-cli ssh-agent load";
};
```

`home.sessionVariables` is picked up by login shells and PAM sessions, so the variable is available to `pass-cli` wherever it runs.

The `pass-ssh-load` alias still exists, as loading SSH keys into the agent is still a manual step since `pass-cli ssh-agent load` is a one-shot command rather than a persistent process, but the `pass-cli login` prefix is gone.

## Auto-loading SSH keys on login

With the authentication problem solved, I can now auto-load SSH keys into the agent at session start. `pass-cli ssh-agent load` is a one-shot command, so a systemd user service is the right fit. It runs after login, has access to the D-Bus session bus, and can be ordered after both the keyring and the SSH agent are ready.

```nix
# profiles/base/proton-pass/home.nix

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
    ExecStart = "${pkgs-unstable.proton-pass-cli}/bin/pass-cli ssh-agent load";
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};
```

The `After` ordering ensures the service waits for GNOME Keyring to be unlocked (so `pass-cli` can retrieve its encryption key via D-Bus) and for the SSH agent to be running (so there is a socket to load keys into). The store path is used directly in `ExecStart` rather than relying on `$PATH`, since systemd services don't inherit the user's shell environment.

Keys injected by `pass-cli ssh-agent load` live only in the agent's memory for the session. The keyring has no record of them, so the service needs to run on every login, which is exactly what `WantedBy = graphical-session.target` gives you.

## One caveat

When `PROTON_PASS_LINUX_KEYRING=dbus` is set and the Secret Service is unreachable (e.g. in a headless SSH session without a D-Bus session bus), `pass-cli` fails hard rather than silently falling back to the kernel keyring. That is fine for a desktop setup where the keyring is always unlocked at login, but worth keeping in mind if you use `pass-cli` in a non-GUI context.
