# Leashed Agent pitch film

This repo holds the TOKEN2049 Origins Hackathon pitch film. `film/index.html` is the current version (Leashed Agent, 2:00). The earlier ThaiCoin film is kept at `film/thaicoin.html`.

---

# ThaiCoin (earlier version)

A Thai-baht-backed stablecoin for AI-agent payments, built on Cardano with the Masumi agent network.
Built for the Origins Hackathon at TOKEN2049 Singapore (Agentic Payments, sponsored by Cardano).

ThaiCoin is in limited use today in the [ThaiFi](https://www.thaifi.com) game top-up ecosystem.

## Pitch film

`film/thaicoin.html` is a self-contained 3-minute animated film. Open it in a browser.
Press `H` for clean mode (screen capture) and `Esc` to exit. When opened from disk, a Record WebM button appears.
Scene 13 (live demo) is a placeholder to replace with a real screen recording.

## Leashed Agent film

`film/index.html` is a 2:00 film built from the PM brief, using the passbook visual language from the product. Product screens are recreated, so swap in live captures where you have them (a chip marks those scenes outside clean mode). Same controls: `H` for clean mode, and a Record WebM button when opened from disk.

## Status

Hackathon project, work in progress.

## Deploy (GitHub Actions to a VPS)

Pushes to `main` publish `film/` to the VPS over SSH. Each deploy goes into `/var/www/thaicoin/releases/<commit>` and the `current` symlink is switched, so a release goes live all at once and the last 5 are kept for rollback. Pull requests only run checks.

### One-time setup

1. Create a dedicated key pair on your computer (no passphrase):
   `ssh-keygen -t ed25519 -f deploy_key -N "" -C github-actions-deploy`
2. On the VPS, as root, copy `deploy/` over and run:
   ```
   DOMAIN=film.example.com EMAIL=you@example.com \
   DEPLOY_PUBKEY="$(cat deploy_key.pub)" bash deploy/setup-vps.sh
   ```
   Use an IP address for `DOMAIN` and leave `EMAIL` out for plain HTTP. For HTTPS, point the domain's DNS A record at the VPS first.
3. In the Hostinger panel firewall, allow ports 22, 80 and 443.
4. In GitHub, go to Settings > Environments, create `production`, then add these secrets:

| Secret | Value |
| --- | --- |
| `VPS_HOST` | VPS IP or hostname |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | contents of `deploy_key` (the private key) |
| `VPS_KNOWN_HOSTS` | output of `ssh-keyscan -t ed25519 <VPS_HOST>` |
| `VPS_PORT` | optional, defaults to 22 |

   Optionally add a repository variable `SITE_URL` (for example `https://film.example.com/`) to enable the post-deploy smoke test.
5. Delete the local `deploy_key` files once the secret is saved.

### Rollback

On the VPS: `cd /var/www/thaicoin && ln -sfn releases/<older-commit> current.tmp && mv -Tf current.tmp current`
