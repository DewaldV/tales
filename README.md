# Tales

Static blog site build with [Hugo](https://github.com/gohugoio/hugo).

## Requirements

Development is done using Nix to manage the installed software. Check usage below for more details and a list of tools to help with this.

- [Nix](https://nixos.org/download)

## Usage
 
```shellsession
nix shell
make build
```

## Using Nix and direnv

For some nice automation, install the following tools and then allow `direnv` to load the nix flake.

- [direnv](https://direnv.net/)
- [nix-direnv](https://github.com/nix-community/nix-direnv)
 
```shellsession
direnv allow
```

