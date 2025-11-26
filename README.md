# MusicApp (self-host)

A self-hostable music library UI (Vue) with a Gin backend. This repo now avoids hardcoded secrets and is ready for packaging (brew/winget/Linux). Discogs metadata is optional via env vars.

## Prerequisites
- Go (build backend)
- Node + npm/yarn (build frontend)
- PostgreSQL (database)
- TagLib dev libraries (for `go-taglib`): `brew install taglib`, `apt-get install libtag1-dev`, or `pacman -S taglib`

## Configuration
1) Copy env template and edit:
```
cp .env.example .env
# set DATABASE_URL, and optionally DISCOGS_KEY/DISCOGS_SECRET
```
2) Optional Discogs: set `DISCOGS_KEY` / `DISCOGS_SECRET` (leave blank to disable Discogs lookups).

## Database
- Initialize schema (requires `psql` in PATH):
```
./sql/init_db.sh
```
- Or manually: `psql "$DATABASE_URL" -f sql/schema.sql`

## Build & Run
Backend:
```
cd Gin
go mod tidy
DATABASE_URL=postgres://... go run main.go
```
Frontend (dev):
```
cd vue
npm install   # or yarn install
npm run dev
```
Frontend (build): `npm run build`

## Packaging notes
- Do not ship `node_modules` in packages; build from lockfile instead.
- Ensure TagLib and PostgreSQL client/server are listed as dependencies in brew/winget/linux packages.
- Provide a service file (systemd/launchd) if distributing as a daemon.
- A starter Homebrew formula is in `packaging/brew/musicapp.rb`; update the `homepage`, `url`, and `sha256` to match your release/tap, then install locally with `brew install --build-from-source packaging/brew/musicapp.rb`.

## Env vars
- `DATABASE_URL` (required): Postgres connection string.
- `DISCOGS_KEY` / `DISCOGS_SECRET` (optional): enable Discogs metadata.

## Security
- No hardcoded Discogs keys remain; credentials come from env.
- Schema ownership is generic (musicuser); adjust per your environment.
