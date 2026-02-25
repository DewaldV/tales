# Tales

Personal blog by Dewald Viljoen, built with [Hugo](https://gohugo.io/) and deployed to [GitHub Pages](https://pages.github.com/).

Live at [dewaldv.com](https://dewaldv.com/).

## Requirements

Development uses Nix to manage tooling. Hugo and Go are provided automatically via the flake.

- [Nix](https://nixos.org/download)

Optionally, for automatic environment loading:

- [direnv](https://direnv.net/)
- [nix-direnv](https://github.com/nix-community/nix-direnv)

```shellsession
direnv allow
```

## Development

```shellsession
# Start dev server
hugo server

# Start dev server including drafts
hugo server -D

# Production build
hugo --gc --minify

# Create a new post
hugo new content/posts/YYYY-MM-DD-slug.md
```

## Theme

The site uses a custom local theme (`themes/tales/`) derived from [smol](https://github.com/colorchestra/smol) by colorchestra. It features:

- Minimal, monospace design
- Dark/light mode (respects OS preference, with manual toggle)
- No external dependencies or tracking
- Single CSS file, no build step

## Deployment

Pushes to `main` trigger a GitHub Actions workflow that builds and deploys to GitHub Pages. See `.github/workflows/hugo.yaml`.

## Licence

[MIT](LICENSE). The theme includes attribution to its upstream sources - see `themes/tales/LICENSE`.
