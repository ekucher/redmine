# This fork

`ekucher/bsystem-redmine` is a fork of
[redmine/redmine](https://github.com/redmine/redmine) (`7.0-stable`,
GPLv2) whose entire purpose is one addition: **`themes/bsystem/`** — a
CSS-only visual theme matching [BSYSTEM](https://github.com/ekucher/bsystem-hub)'s
corporate palette, applied through Redmine's own theme mechanism, not by
modifying Redmine's Ruby/Rails code. See `themes/bsystem/README.md` for
what it does and how to apply it.

Nothing else in this fork diverges from upstream. Redmine's own
`README.rdoc`, licensing (`COPYING`, GPLv2), and the rest of the codebase
are unchanged.

## Local preview

`docker-compose.bsystem.yml` at the repo root runs a throwaway local stack
(official `redmine` image + Postgres) to see the theme against a real
instance — not a deployment topology, just how this theme was reviewed
during development. See `themes/bsystem/README.md` for the
recompile-and-restart step the official image's production mode requires
after any theme change.

`seed_demo.rb` is a one-off `bin/rails runner` script that seeds a demo
project with a handful of issues, a version, and a wiki page — enough
real data to actually see the theme across more of the app than an empty
install shows. Not meant to run against anything but the local preview
stack above.
