#!/bin/bash

if [ ! -f ".env" ]; then
  echo ".env file does not exist."
  exit
fi

source .env

export TERMINAL_COLUMNS="$(stty -a 2>/dev/null | grep -Po '(?<=columns )\d+' || echo 0)"

print_separator() {
  for ((i = 0; i < "$TERMINAL_COLUMNS"; i++)); do
    printf $1
  done
}

echo_run() {
  line_count=$(wc -l <<<$1)
  echo -n ">$(if [ ! -z ${2+x} ]; then echo "($2)"; fi)_ $(sed -e '/^[[:space:]]*$/d' <<<$1 | head -1 | xargs)"
  if (($line_count > 1)); then
    echo -n "(command truncated....)"
  fi
  echo
  if [ -z ${2+x} ]; then
    eval $1
  else
    FUNCTIONS=$(declare -pf)
    echo "$FUNCTIONS; $1" | sudo --preserve-env -H -u $2 bash
  fi
  print_separator "+"
  echo -e "\n"
}

function gcf() {
  export GCF_ED='$'
  envsubst <$1
}

function gcfc() {
  gcf $PROJECT_CONFIGS/$1
}

server_initial_setup() {
  echo_run "ln -fs /usr/share/zoneinfo/Asia/Tehran /etc/localtime"
  echo_run "dpkg-reconfigure -f noninteractive tzdata"
  echo_run "apt update -y"
  echo_run "apt install -y docker.io docker-compose docker-buildx certbot nginx python3-certbot-nginx"
}

run_cocalc() {
  echo_run "docker-compose up -d --build --remove-orphans"
}

config_nginx_certbot() {
  echo_run "certbot certonly -d $DOMAIN --standalone --agree-tos"
  echo_run "gcf nginx.conf > /etc/nginx/sites-available/$DOMAIN.conf"
  echo_run "ln -s /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/"
  echo_run "systemctl restart nginx"
  echo_run "certbot --nginx -d $DOMAIN --noninteractive"
  echo "Open https://$DOMAIN/auth/sign-up in your browser and create an account."
}

config_cocalc() {
  read -p "Enter your email registered in cocalc: " EMAIL
  echo_run "docker exec -it cocalc bash -ic '/cocalc/src/scripts/make-user-admin $EMAIL'"
}

ACTIONS=(
  "server_initial_setup"
  "run_cocalc"
  "config_nginx_certbot"
  config_cocalc
)

# READ ACTIONS
while true; do
  echo "Which action? $(if [ ! -z ${LAST_ACTION} ]; then echo "($LAST_ACTION)"; fi)"
  for i in "${!ACTIONS[@]}"; do
    if [ $i -eq $((OLD_ACTIONS_START - 1)) ]; then echo -e "\n\t- Old Actions: (No need to run)"; fi
    echo -e "\t$((i + 1)). ${ACTIONS[$i]}"
  done
  read ACTION
  LAST_ACTION=$ACTION
  print_separator "-"
  $ACTION
  print_separator "-"
done
