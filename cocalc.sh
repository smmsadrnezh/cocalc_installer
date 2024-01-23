mkdir -p /root/docker/cocalc/
nano /root/docker/cocalc/docker-compose.yml
version: "3.7"

services:
  cocalc:
    container_name: cocalc
    restart: always
    image: sagemathinc/cocalc-v2
    environment:
      - "NOSSL=true"
    volumes:
      - /srv/cocalc:/projects
      - /etc/localtime:/etc/localtime
      - /etc/timezone:/etc/timezone
    ports:
      - "2180:80"

cd /root/docker/cocalc/
docker-compose up -d
docker logs cocalc -f

nano /etc/nginx/sites-available/lab.conf
map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
}

# https://lab.example.com
server {
    listen 443 ssl http2;
    server_name lab.example.com;

    client_max_body_size 512M;

    location / {
        proxy_pass http://localhost:2180;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
   }

    ssl_certificate /etc/letsencrypt/live/lab.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/lab.example.com/privkey.pem; # managed by Certbot
}

# http://lab.example.com
server {
    if ($host = lab.example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    server_name lab.example.com;
}

sudo certbot --nginx -d lab.example.com

Visit CoCalc on the web at your domain and make an account.

sudo docker exec -it cocalc bash
cd /cocalc/src/scripts
./make-user-admin newuser@gmail.com

(F.3) Log back into CoCalc on your account, click "Admin" at the top, then make a registration token
Now only those with a registration token can register for accounts

sudo docker exec -it cocalc bash
ls /usr/share/texlive/texmf-dist/
apt install texlive-xetex -y
sudo sed -i 's|http://archive.ubuntu.com/ubuntu|http://old-releases.ubuntu.com/ubuntu|' /etc/apt/sources.list
apt update
apt upgrade
apt install texlive texlive-latex-recommended texlive-xetex texlive-lang-arabic texlive-lang-english texlive-pictures texlive-latex-extra texlive-extra-utils texlive-fonts-recommended texlive-pstricks


