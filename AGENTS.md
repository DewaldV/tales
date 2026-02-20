# AGENTS.md — Tales

Guidance for agentic coding assistants working in this repository.

---

## Project Overview

A personal static blog by Dewald Viljoen, built with **Hugo** and deployed to **GitHub Pages**. The theme (`themes/tales/`) is a custom local theme derived from `smol`. No npm, no bundler, no CSS framework — deliberately minimal.

---

## Build & Dev Commands

There is no Makefile or npm scripts. All commands use the Hugo CLI directly.

| Purpose | Command |
|---|---|
| Dev server (published posts only) | `hugo server` |
| Dev server (including drafts) | `hugo server -D` |
| Production build | `hugo --gc --minify` |
| Create a new post | `hugo new content/posts/YYYY-MM-DD-slug.md` |

There are **no lint, format, or test commands**. Hugo itself validates templates at build/serve time — errors are printed to the terminal.

**The dev server is the primary feedback loop.** Always verify changes by checking the running server at `http://localhost:1313`.

### Nix Dev Environment

The repo uses Nix flakes + direnv. If the Nix shell is active (via `direnv allow` or `nix develop`), `hugo` and `go` are available automatically.

### CI/CD

GitHub Actions (`.github/workflows/hugo.yaml`) builds with:
```bash
hugo --gc --minify --baseURL "${{ steps.pages.outputs.base_url }}/"
```
Pinned to **Hugo 0.155.3 extended**. Sets `HUGO_ENVIRONMENT=production`.

---

## Project Structure

```
content/
  _index.md               # Homepage (YAML front matter, no body content)
  about/_index.md         # About page (YAML, layout: about)
  posts/
    00-post-ideas.md      # Draft scratchpad — never publish
    YYYY-MM-DD-slug.md    # Blog posts
themes/tales/
  layouts/
    _default/             # Base templates (baseof, single, list, summary, about)
    about/                # About-specific layout overrides
    index.html            # Homepage layout
    partials/             # header, footer, pagination, contact
    _default/_markup/     # render-image.html (wraps images in <figure>)
  static/css/style.css    # All styles — single file, no build step
static/images/            # Site-level static assets
hugo.toml                 # Site config, params, menus
```

---

## Content Conventions

### Post Files

- **Location:** `content/posts/`
- **Filename format:** `YYYY-MM-DD-kebab-case-slug.md` — date prefix is mandatory, keeps posts sorted naturally in the filesystem.
- **Example:** `2025-02-10-nixos-setup.md`

### Front Matter

Posts use **TOML** delimiters (`+++`):

```toml
+++
title = 'Post Title Here'
date = 2025-02-10T10:00:00Z
draft = false
tags = ['nixos', 'linux']
+++
```

Section index files (`_index.md`) use **YAML** delimiters (`---`):

```yaml
---
title: "Page Title"
description: "Short description"
---
```

Rules:
- `title` and `date` are always required on posts.
- `draft = true` hides a post from the live site (`hugo server -D` still shows it locally).
- `tags` are optional, lowercase, kebab-case strings.
- Dates use ISO 8601 with time and UTC offset: `2025-02-10T10:00:00Z`.
- Do **not** set `draft = false` on `00-post-ideas.md` — it is a scratchpad, not a post.

### The `hugo new` Archetype

Running `hugo new content/posts/YYYY-MM-DD-slug.md` scaffolds a TOML front matter file from `archetypes/default.md`. The title is auto-derived from the filename.

---

## Hugo Templates

### Layout Hierarchy

- All page templates define a `{{ define "main" }}` block injected into `baseof.html`.
- `baseof.html` owns `<html>`, `<head>`, header/footer partials, and the inline JS for the theme toggle.
- Never add `<html>`, `<head>`, or `<body>` tags to layout files other than `baseof.html`.

### Indentation

Hard **tabs** throughout all `.html` template files. Do not use spaces.

### Partials

Call partials with the `.html` suffix for consistency:
```html
{{ partial "contact.html" . }}
{{ partial "pagination.html" . }}
```

Pass `.` (current context) unless a specific context is needed.

### Site Params

Social/contact links and section config live in `hugo.toml` under `[params]`. Access them in templates with `{{ .Site.Params.github }}` etc. Always wrap optional params in `{{ with }}`:

```html
{{ with .Site.Params.github }}<a href="{{ . }}">GitHub</a>{{ end }}
```

### Hugo Template Patterns

- Use `{{ $var := value }}` for local variables.
- Use `{{ range }}...{{ end }}` for iteration.
- Use `{{ with }}...{{ end }}` for nil-safe access (preferred over `{{ if }}`).
- Date formatting uses Go reference time: `"2006-01-02"` for date-only, `"2006-01-02 15:04:05"` for datetime.
- Use `| relURL` or `| relLangURL` for internal links; `| urlize` for slugifying tag names.

---

## CSS Conventions

Single file: `themes/tales/static/css/style.css`. No preprocessor, no build step.

### Custom Properties

All colours are defined as CSS custom properties on `:root`. The full set:

```css
--bgcolor, --fontcolor, --linkcolor, --visitedcolor,
--precolor, --prebgcolor, --hrcolor, --mutedcolor
```

Always use these variables — never hardcode colour values.

### Theme System

- Default: light (`:root`)
- OS dark preference: `@media (prefers-color-scheme: dark)`
- Manual override: `[data-theme="dark"]` / `[data-theme="light"]` on `<html>`

When adding new components, define colours using the existing variables so dark/light mode works automatically.

### Naming

- Kebab-case class names: `.site-header`, `.latest-post`, `.latest-post-label`
- No component prefix or BEM syntax — flat, descriptive names
- Semantic HTML elements styled directly where appropriate (`article`, `footer`, `figure`, etc.)

### File Organisation

Add new styles under a clearly commented section header:
```css
/* New component name */
.new-component { ... }
```

The existing section order is: variables → base → links → headings → code → specific components → header → footer → theme toggle → responsive.

### Typography & Layout

- Body: `14px/1.6 monospace` — the monospace aesthetic is intentional, do not change.
- Max-width: `800px`, centred with `margin: auto`.
- Single responsive breakpoint at `max-width: 600px`.

---

## Hugo Config (`hugo.toml`)

- Format: TOML throughout.
- `baseURL`: `https://dewaldv.com/`
- `languageCode`: `en-GB` — use British English in all UI strings.
- Site title: `DEWALD VILJOEN` (all caps) — do not change casing.
- `params.mainSections = ["posts"]` — required for the homepage post list and latest-post callout.
- Social params (`github`, `linkedin`, `email`) are the single source of truth for contact details. Update them here, not in templates or content.

---

## Git Conventions

Commit messages follow **Conventional Commits** with one custom type:

```
feat:   new site feature or template change
fix:    bug fix
chore:  deps, config, formatting, maintenance
post:   adding or updating a blog post or content file
```

Format: `<type>: <short imperative description>` (no capital, no period).

Examples:
```
feat: add latest post callout to homepage
fix: use list layout for about page
chore: update flake dependencies
post: start nixos setup post
```

---

## Common Pitfalls

- **`_index.md` uses the list layout**, not single — section index files are branch bundles. Use `layout:` front matter or a section-specific layout file in `layouts/<section>/` to override.
- **`mainSections` must be set** in `hugo.toml` — without it, the homepage and latest-post callout will be empty.
- **Drafts require `-D` flag** — `hugo server` without `-D` will not show draft posts.
- **Post filename must have a date prefix** — `YYYY-MM-DD-slug.md` is the established convention; do not create posts without it.
- **Do not publish `00-post-ideas.md`** — it is a scratchpad and must remain `draft = true`.
