#!/bin/bash
set -e

APP_USER=${APP_USER:-petclinic}
PROJECT_DIR=${PROJECT_DIR:-/home/vagrant/petclinic}
APP_DIR=${APP_DIR:-/home/${APP_USER}}  # ← домашня тека APP_USER
DB_HOST=${DB_HOST:-192.168.56.10}
DB_PORT=${DB_PORT:-3306}
DB_NAME=${DB_NAME:-petclinic}
DB_USER=${DB_USER:-petclinic}
DB_PASS=${DB_PASS:-petclinic}

# юзер
id -u ${APP_USER} &>/dev/null || useradd -m -s /bin/bash ${APP_USER}

apt-get update -qq
apt-get install -y openjdk-17-jdk git

# Клонуємо git
if [ -d "${PROJECT_DIR}" ]; then
  rm -rf ${PROJECT_DIR}
fi
git clone --depth 1 https://github.com/spring-projects/spring-petclinic.git ${PROJECT_DIR}

# Права для юзера щоб запускати mvnw
chown -R ${APP_USER}:${APP_USER} ${PROJECT_DIR}
chmod +x ${PROJECT_DIR}/mvnw

sudo -u ${APP_USER} bash -c "
  export HOME=/home/${APP_USER}
  export MAVEN_OPTS='-Xmx512m'
  cd ${PROJECT_DIR}
  ./mvnw -DskipTests package
"

# Копіюємо jar 
mkdir -p ${APP_DIR}
cp ${PROJECT_DIR}/target/spring-petclinic-*.jar ${APP_DIR}/petclinic.jar
chown -R ${APP_USER}:${APP_USER} ${APP_DIR}

# systemd сервіс
cat > /etc/systemd/system/petclinic.service << EOF
[Unit]
Description=Spring PetClinic
After=network.target

[Service]
User=${APP_USER}
WorkingDirectory=${APP_DIR}
Environment="DB_HOST=${DB_HOST}"
Environment="DB_PORT=${DB_PORT}"
Environment="DB_NAME=${DB_NAME}"
Environment="DB_USER=${DB_USER}"
Environment="DB_PASS=${DB_PASS}"
ExecStart=/usr/bin/java \\
  -Dspring.profiles.active=mysql \\
  -Dspring.datasource.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}?useSSL=false&allowPublicKeyRetrieval=true \\
  -Dspring.datasource.username=${DB_USER} \\
  -Dspring.datasource.password=${DB_PASS} \\
  -jar ${APP_DIR}/petclinic.jar
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable petclinic
systemctl start petclinic 

echo "PetClinic встановлено успішно!"
