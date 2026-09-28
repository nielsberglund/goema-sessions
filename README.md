# The Goema Sessions — play along

*GitHub Copilot Dev Days Cape Town, 3 October 2026*

In the session we point **GitHub Copilot CLI** at a database it has never seen and improvise a data analysis with it — live, no script. This repo lets you do the same on your own laptop: a small local database and a read-only connector that lets Copilot query it.

**Following along is optional.** Nothing in the talk depends on your laptop working. If you'd rather watch, watch — this repo stays up, so you can replay the whole thing tonight.

All the data is **local and synthetic**: a sample digital music store (the classic *Chinook* dataset), plus a sprinkling of deliberate mess, plus a few made-up Cape Town gigs. No real people.

---

## What you need

1. **Docker Desktop**, installed and **running**. The database and the connector both run as containers. <https://www.docker.com/products/docker-desktop/>
2. **GitHub Copilot CLI**, and a **Copilot subscription that lets you use it** (if your organisation manages your Copilot seat, it may have the CLI switched off).

   ```bash
   npm install -g @github/copilot       # needs Node 22+
   brew install --cask copilot-cli      # macOS / Linux
   winget install GitHub.Copilot        # Windows
   ```
   Docs: <https://docs.github.com/en/copilot/how-tos/copilot-cli>

---

## Set up (do this before the session — venue wifi is not your friend)

**1. Clone this repo and go into it.**

```bash
git clone <this-repo-url> goema-sessions
cd goema-sessions
```

**2. Start the database.** The first start loads the data automatically (give it
~20 seconds).

```bash
docker compose up -d
```

> **NOTE:** The PostgreSQL MCP connector is automatically pulled and started by Docker Compose. You don't need to do anything manually.

**3. Log in to Copilot CLI once.**

```bash
copilot
```

Then type `/login`, follow the prompts, and `/exit` when you're done.

**4. Check the data loaded.**

```bash
docker compose exec postgres psql -U goema -d goema -c "select count(*) from artist;"
```

You should see **278**. If you do, you're ready to play.

---

## Launch Copilot with the database attached

From the **root of this repo**:

```bash
copilot
```

The first time Copilot wants to use the connector it will ask for permission. Say yes.
Then try:

> What's in this database? Use the goema-db connector. Take a look around and tell me what it's about.

If Copilot answers with tables about artists, albums, tracks and invoices, you're connected.

---

## During the session

When I say **"your turn"**, type the prompt on screen. These are the two:

> Where are our customers based? Show me the top countries by revenue — and show me the SQL you used.

> The USA is our biggest market. Pull every US sale and give me the exact total.

Then compare notes with the person next to you. You'll probably get different SQL and maybe different numbers. That's not a bug; it's the point of the session.

After that, ask it anything you like. It's your database now.

---

## What's in this repo

| File | What it is |
|---|---|
| `docker-compose.yml` | The local PostgreSQL 17 database and the MCP server. User, password and database are all `goema`, on port `5432`. |
| `init/01-chinook.sql` | The **Chinook** sample dataset: a digital music store. Loaded automatically on first start. |
| `init/02-messy-rows.sql` | Some deliberately messy data. Real data is never clean, so this one isn't either. (No spoilers: see what Copilot finds before you read it.) |
| `init/03-cape-town-gigs.sql` | A small, made-up Cape Town layer: venues, gigs, ticket sales. |
| `.mcp.json` | The connector config. It tells Copilot how to start the database connector, `goema-db`. |


### How the connector works

Copilot doesn't talk to Postgres directly. `.mcp.json` tells Copilot to start **[Postgres MCP Pro](https://github.com/crystaldba/postgres-mcp)** in a container. That connector runs the SQL on Copilot's behalf and hands back the results.

- **It is read-only.** `--access-mode=restricted` means the connector *cannot* change the database, whatever you ask. Ask it to delete something and watch it refuse.
- **`host.docker.internal`** is how the connector's container reaches the database port on your machine. The `--add-host` flag makes that name work on Linux as well.

---

## If something goes wrong

| Symptom | Fix |
|---|---|
| `Cannot connect to the Docker daemon` | Start Docker Desktop, wait for it to settle, try again. |
| Port 5432 is already in use | Run on another port (see below). |
| Copilot says it has no `goema-db` connector | Launch it with `--additional-mcp-config "@.mcp.json"`, from the repo root. |
| The connector fails to start and mentions `python3` | **Windows:** Python is usually `python` or `py`, not `python3`. Change `"command": "python3"` in `.mcp.json` to whichever works for you. |
| The connector fails to start and mentions `mcp-stdio-proxy.py` | You launched Copilot from outside the repo root. `cd` into the repo and launch again. |
| The first query is slow | The connector image is still downloading. `docker pull crystaldba/postgres-mcp` before the session. |
| A query is rejected as read-only | That's working as designed. |
| `copilot: command not found` | Install it (see [What you need](#what-you-need)). The npm route needs Node 22+. |
| Copilot says you're not entitled / not allowed | Your Copilot plan or organisation policy doesn't include the CLI. Watch this one, and try again later with a plan that does. |

### Port 5432 already taken

If you already run Postgres locally, pick another port.

**macOS / Linux**

```bash
GOEMA_PG_PORT=5433 docker compose up -d
```

**Windows (PowerShell)**

```powershell
$env:GOEMA_PG_PORT = "5433"; docker compose up -d
```

Then change the port in `.mcp.json` to match:

```json
"DATABASE_URI": "postgresql://goema:goema@host.docker.internal:5433/goema"
```

---

## Look at the data yourself

```bash
docker compose exec postgres psql -U goema -d goema
```

Or use your favourite SQL client on `postgresql://goema:goema@localhost:5432/goema`.

## Clean up afterwards

```bash
docker compose down        # stop the database, keep the data
docker compose down -v     # stop it and wipe the data (a fresh reload next time)
```
