# Deploying GlobeTrotter (Phase 1) to a Contabo VPS

This covers taking the Dockerized Flask monolith from your machine to a
running Contabo VPS reachable over the internet.

## 1. Order / access the VPS

- If you don't have one yet: at contabo.com, order a **Cloud VPS** (the
  cheapest "VPS S" tier is enough for Phase 1). Choose **Ubuntu 22.04 LTS**
  as the image. Contabo emails you the root password and the server's public IP.
- If you already have one: you just need its public IP and root/SSH access.

## 2. First login and basic hardening

From your machine:

```bash
ssh root@YOUR_VPS_IP
```

Once in, create a non-root sudo user (don't operate as root day-to-day) and enable the firewall:

```bash
adduser deploy
usermod -aG sudo deploy

# Basic firewall: allow SSH, HTTP, HTTPS, and the API port
apt update && apt install -y ufw
ufw allow OpenSSH
ufw allow 5000/tcp    # GlobeTrotter API (Phase 1)
ufw allow 80/tcp      # reserved for later (nginx/HTTPS)
ufw allow 443/tcp
ufw enable
```

Log out and back in as `deploy` from now on: `ssh deploy@YOUR_VPS_IP`.

## 3. Install Docker & Docker Compose on the VPS

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker          # refresh group membership without re-login

docker --version
docker compose version
```

## 4. Get the project onto the VPS

Simplest path — push your local repo to GitHub, then clone it on the VPS:

```bash
# on the VPS
git clone https://github.com/<your-username>/globetrotter-capstone.git
cd globetrotter-capstone
```

(No GitHub yet? You can instead `scp -r` the folder from your machine:
`scp -r globetrotter-capstone deploy@YOUR_VPS_IP:~/`.)

## 5. Configure production secrets

Never run with the default `SECRET_KEY`. Generate one and pass it in:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Create a `.env` file on the VPS (already gitignored) and reference it from
`docker-compose.yml`:

```bash
echo "SECRET_KEY=<paste the generated value>" > .env
```

Edit `docker-compose.yml` to load it:

```yaml
services:
  globetrotter:
    build: .
    container_name: globetrotter_app
    ports:
      - "5000:5000"
    volumes:
      - .:/globetrotter
    env_file:
      - .env
    environment:
      - PORT=5000
    restart: unless-stopped
```

## 6. Build and run

```bash
docker compose up --build -d
docker compose ps
docker compose logs -f          # Ctrl+C to stop tailing (container keeps running)
```

Test from your own machine:

```bash
curl http://YOUR_VPS_IP:5000/destinations
```

`restart: unless-stopped` makes the container survive VPS reboots.

## 7. Point the Flutter app at the VPS

Run/build the frontend with the VPS IP instead of localhost:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://YOUR_VPS_IP:5000
# or for a production web build:
flutter build web --dart-define=API_BASE_URL=http://YOUR_VPS_IP:5000
```

## 8. (Optional, recommended before Phase 3) Domain + HTTPS

Phase 1 only requires "deployed on a single server," so plain HTTP on the
VPS IP is enough. When you're ready for a real domain:

1. Point an A record for e.g. `api.yourdomain.com` at `YOUR_VPS_IP`.
2. Put `nginx` + `certbot` in front of the container as a reverse proxy, or
   add `nginx-proxy` + `acme-companion` containers to `docker-compose.yml`.
3. Update `API_BASE_URL` to `https://api.yourdomain.com`.

This is a good task to fold into Phase 3 ("Cloud Deployment") since it's
about load balancing / ingress rather than the monolith itself.

## Redeploying after code changes

```bash
cd ~/globetrotter-capstone
git pull
docker compose up --build -d
```
