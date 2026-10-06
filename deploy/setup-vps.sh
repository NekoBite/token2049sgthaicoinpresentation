#!/usr/bin/env bash
# One-time VPS setup (Ubuntu/Debian). Run as root:
#   DOMAIN=film.example.com EMAIL=you@example.com \
#   DEPLOY_PUBKEY="ssh-ed25519 AAAA... github-actions-deploy" \
#   bash setup-vps.sh
# DOMAIN may be an IP address for plain HTTP; EMAIL is only needed for HTTPS (Let's Encrypt).
set -euo pipefail

: "${DOMAIN:?set DOMAIN (hostname or IP)}"
: "${DEPLOY_PUBKEY:?set DEPLOY_PUBKEY (public half of the CI deploy key)}"
BASE=/var/www/thaicoin
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update -y
apt-get install -y nginx rsync ufw
[ -n "${EMAIL:-}" ] && apt-get install -y certbot python3-certbot-nginx

# deploy user: no sudo, key-only, owns the web root
id deploy >/dev/null 2>&1 || adduser --disabled-password --gecos "" deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
grep -qxF "$DEPLOY_PUBKEY" /home/deploy/.ssh/authorized_keys 2>/dev/null \
  || echo "$DEPLOY_PUBKEY" >> /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys

install -d -o deploy -g deploy "$BASE" "$BASE/releases"
if [ ! -e "$BASE/current" ]; then
  install -d -o deploy -g deploy "$BASE/releases/placeholder"
  echo "<h1>ThaiCoin: awaiting first deploy</h1>" > "$BASE/releases/placeholder/index.html"
  chown deploy:deploy "$BASE/releases/placeholder/index.html"
  ln -sfn releases/placeholder "$BASE/current"
  chown -h deploy:deploy "$BASE/current"
fi

sed "s/__DOMAIN__/$DOMAIN/" "$DIR/nginx.conf" > /etc/nginx/sites-available/thaicoin
ln -sfn /etc/nginx/sites-available/thaicoin /etc/nginx/sites-enabled/thaicoin
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx

ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

if [ -n "${EMAIL:-}" ]; then
  certbot --nginx -d "$DOMAIN" -m "$EMAIL" --agree-tos --no-eff-email --redirect -n
fi

echo "Done. Site root: $BASE/current"
echo "Host key to pin as VPS_KNOWN_HOSTS:"
ssh-keyscan -t ed25519 localhost 2>/dev/null | sed "s/^localhost/$DOMAIN/"
