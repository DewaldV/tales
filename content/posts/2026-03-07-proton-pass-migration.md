+++
title = 'Migrating from 1Password to Proton Pass on NixOS'
date = 2026-03-07T10:00:00Z
draft = false
tags = ['nixos', 'linux', 'security', 'ssh', 'git']
+++

With a recent change to pricing for 1Password I've finally made the decision to migrate over to Proton Pass. It's already included in my Proton Duo subscription and Proton Pass has made strides with its features since launch.

Most of it was straightforward, import, verify, done. Three caveats though:

1. The import did not bring across any passkeys and I had to set them up again. Proton Pass did helpfully show me which of my credentials could use passkeys though.
2. Proton Pass's Linux desktop app does not support system authentication. It shows up in the UI but some digging through the app showed that it's currently not implemented.
3. Replacing 1Password's SSH agent is possible but comes with trade-offs. That's what most of this post is about.

## The 1Password SSH agent experience

1Password has first-class SSH agent support on Linux. It exposes a socket at `~/.1password/agent.sock`, you configure which vaults it serves keys from via `~/.config/1Password/ssh/agent.toml`, and SSH clients point at that socket via `IdentityAgent`. Git commit signing is done with a dedicated binary, `op-ssh-sign`, as the `gpg.ssh.program`.

The relevant SSH config looked like this:

```console
Host github.com
  IdentityAgent ~/.1password/agent.sock
```

And the git signing config:

```ini
[gpg]
  format = ssh
[gpg "ssh"]
  program = op-ssh-sign
```

Clean, integrated and very easy to set up. It's just a single option to enable in the 1Password desktop app and it plugs directly into system authentication through [polkit](https://www.freedesktop.org/software/polkit/docs/latest/polkit.8.html).

## What Proton Pass offers

Proton Pass added support for SSH agents via their Pass CLI (`pass-cli`) using `pass-cli ssh-agent`. There are two modes:

- `pass-cli ssh-agent start` - runs as a standalone SSH agent, exposing its own socket
- `pass-cli ssh-agent load` - loads keys from your vaults into an existing SSH agent

The `load` mode is simpler: it's a one-shot command that scans your vaults and injects any keys it finds into an existing SSH agent. No persistent process, no socket to manage. The trade-off is that it doesn't auto-refresh, if you add a new key to Pass you need to run it again. A bit of a faff, but it works to get started. It writes into whatever agent `SSH_AUTH_SOCK` points to, so I could switch back to good old [ssh-agent](https://www.man7.org/linux/man-pages/man1/ssh-agent.1.html).

## The system SSH agent

With `pass-cli ssh-agent load` handling the key injection, I needed to set up `ssh-agent` and NixOS makes this simple.

```nix
programs.ssh.startAgent = true;
```

That starts `ssh-agent` at login and sets `SSH_AUTH_SOCK` to `$XDG_RUNTIME_DIR/ssh-agent`.

One complication: GNOME Keyring was already running a GCR SSH agent on that socket, and NixOS prevents both from being enabled simultaneously. I was already running GNOME Keyring for secret storage but not actually using its SSH component and disabling it was easy:

```nix
services.gnome.gcr-ssh-agent.enable = false;
```

## A reboot problem

When I started testing the setup I hit a snag: after every reboot, `pass-cli test` fails with a session error and forces a re-login, even though the session files are still on disk.

As with most things secrets-related I assumed this was a GNOME Keyring issue, maybe the keyring wasn't unlocking at login, or the socket wasn't available to `pass-cli`. That turned out to be completely wrong.

Digging into it with `strace`, `pass-cli` never talks to the GNOME Keyring or D-Bus at all. It uses the [Linux kernel keyring](https://docs.kernel.org/security/keys/core.html) (`linux-keyutils`) via [keyring-rs](https://docs.rs/keyring/latest/keyring/) to store its local encryption key. The encrypted session files sit on disk at `~/.local/share/proton-pass-cli/.session/`, but they can only be decrypted with a key that lives in the kernel's in-memory keyring.

You can see this directly in `/proc/keys`:

```console
03e3bc3c I--Q---  2 perm 3f010000  1000  100 user  keyring-rs:cli-local-key@ProtonPassCLI: 32
```

The key is stored in the **user keyring** (`@u`). The user keyring is per-UID and lives in kernel memory, it survives logout and re-login within the same boot (the UID's kernel state persists across sessions), which is why logging out and back in works fine. But it is wiped completely on reboot, because it only exists in RAM.

When `pass-cli` starts after a reboot, it finds the session files on disk but cannot find the decryption key in the kernel keyring. Its response is to force a logout for security, which is the right call, you can't partially authenticate and it logs the reason clearly:

```console
Error: Local encryption key not found but session exists. Forcing logout for security.
```

## The workaround

Since `pass-cli` requires a login after every reboot before it can do anything, there's no point trying to auto-load SSH keys at startup, they'd fail silently if you reboot without re-authenticating first.

The simple solution is a shell alias that I can run myself before starting work for the day:

```nix
programs.zsh.shellAliases = {
  pass-ssh-load = "pass-cli login && pass-cli ssh-agent load";
};
```

Run `pass-ssh-load` once after each reboot. Login, then load. One command.

## Git commit signing

1Password's `op-ssh-sign` binary handled SSH-format git commit signing. Proton Pass has no equivalent. But one isn't needed, `ssh-keygen` itself can sign, and git can use it:

```nix
programs.git.settings = {
  gpg.format = "ssh";
  gpg."ssh".program = "${pkgs.openssh}/bin/ssh-keygen";
};
```

Since the signing key is already loaded into the SSH agent by `pass-ssh-load`, `ssh-keygen` can sign via the agent without touching any key files on disk. No separate binary, no special integration required.

## The result

After applying the config:

- After each reboot, I run `pass-ssh-load` to log in to Pass and load all SSH keys into the system agent
- SSH and Git access are both up and running
- Git commits are signed using `ssh-keygen` against the agent

The main limitation compared to 1Password is the manual step after reboot. 1Password's agent is always-on once the app is unlocked; `pass-cli` needs an explicit login each boot due to the kernel keyring being wiped. That's an upstream limitation worth tracking.

I'll miss some of 1Password's quality of life, its CLI is tightly integrated with the desktop app and so are its browser extensions. But this move is part of a broader shift away from US-based cloud services towards European alternatives, something I'm writing about separately in the context of de-googling. Proton Pass has a few rough edges but the trade-offs are worth it.
