# BSYSTEM theme

A visual-only reskin of Redmine using its standard theme mechanism
(`lib/redmine/themes.rb` scans `themes/*` alongside the bundled themes in
`app/assets/themes/*`) — nothing outside `themes/bsystem/` is modified.
Selectable in **Administration → Settings → Display → Theme** once the
server has picked it up (see below).

The palette is copied verbatim from
[`bsystem-hub`](https://github.com/ekucher/bsystem-hub)'s
`src/styles.css` `:root` dark tokens, so a user moving from the HUB
launcher into Redmine (opened via its `launch_url`) lands somewhere
visually consistent rather than on an unrelated product.

## What this is not

- Not a fork of Redmine's Ruby/Rails behavior — no `app/`, `lib/`, or
  `config/` file is touched.
- Not a light-theme; this reskin is dark-only, matching bsystem-hub's own
  default. A `prefers-color-scheme`-aware light variant is future work if
  ever needed, not part of this pass.
- Not wired into any real BSYSTEM deployment — see the repo root for the
  local-only Docker preview stack this was verified against.

## Applying the theme after adding/changing it

Redmine's official Docker image runs in `RAILS_ENV=production`, which
serves precompiled assets from `public/assets` rather than compiling
`themes/` on the fly. After editing this theme, assets must be recompiled
and the server restarted for the change to be visible:

```bash
docker exec -e SECRET_KEY_BASE=<your-secret> <container> \
  sh -c "cd /usr/src/redmine && bin/rails assets:precompile"
docker compose restart redmine
```

Then select **Bsystem** under Administration → Settings → Display → Theme
(or set it directly: `bin/rails runner 'Setting.ui_theme = "bsystem"'`).

## Known gaps

- The Gantt chart's own grid (`gantt.css`, drawn as its own inline
  SVG/canvas layer) keeps its default light background — it isn't part of
  the `application.css` cascade this theme overrides, and re-theming it
  was out of scope for this pass.
