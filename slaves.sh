#! /bin/bash

# Skrip ini menjalankan perintah untuk pemasangan perangakat lunak sebagai berikut
# * NVM, Node.js
# * SDKMAN, Java
# * Pengunduhan Android Studio
# * Pengunduhan Maviskeleton yang terdapat di Github
# * Pembuatan "Folder" Tertentu

cd $HOME

# Welcome Banner
clear
cat << EOM
Maviskeleton scaffolder
by BSTKA
28 May 2023
EOM
echo -e "\n"

# Membaca masukan untuk nama perangkat
# Tersimpan sebagai namaPerangkat
read -p "Nama perangkat: " DEVICE_NAME
echo -e "\n"

# Membaca kode unik untuk perangkat
# Tersimpan sebagai kodeUnik
read -p "Kode unik perangkat: " DEVICE_UNIQUE_KEY
echo -e "\n"

# Membaca username perangkat
# Tersimpan sebagai unPerangkat
read -p "Username perangkat: " DEVICE_USERNAME
echo -e "\n"

# Membaca kode rahasia perangkat
# Tersimpan sebagai krPerangkat
read -p "Kode rahasia perangkat: " DEVICE_SECRET
echo -e "\n"

# Membaca username github
# Tersimpan sebagai unGithub
read -p "Masukan Username Github: " unGithub
echo -e "\n"

# Membaca token github
# Tersimpan sebagai tknGithub
read -s -p "Masukan Token Github: " tknGithub
echo -e "\n"

# Membaca kata sandi sudo
# Kata Sandi tersimpan sebagai sudoKS
read -s -p "Masukan kata sandi sebagai sudo: " sudoKS
echo -e "\n"

# Deklarasi Variabel
NVM_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh"
ANDROID_STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2022.2.1.20/android-studio-2022.2.1.20-linux.tar.gz"
ANDROID_PATH_STR="export ANDROID_HOME=\$HOME/Android/Sdk"
NEW_PATH_STR="export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
SDKMAN_URL="https://get.sdkman.io"
START_SH_CONTENT=$(
cat << EOM
#!/bin/bash
source $HOME/.nvm/nvm.sh
export ANDROID_HOME=\$HOME/Android/Sdk
export PATH=\$PATH:\$ANDROID_HOME/platform-tools
npm run start
EOM
)

START_APPIUM_SH_CONTENT=$(
cat << EOM
#!/bin/bash
source $HOME/.nvm/nvm.sh
export ANDROID_HOME=\$HOME/Android/Sdk
export PATH=\$PATH:\$ANDROID_HOME/platform-tools
appium
EOM
)

MAVISKELETON_SERVICE_STR=$(
cat << EOM
[Unit]
Description=Maviskeleton Services
After=network.target
[Install]
WantedBy=multi-user.target
[Service]
ExecStartPre=-$HOME/Android/Sdk/platform-tools/adb start-server
ExecStart=$HOME/.apps/maviskeleton/start.sh
WorkingDirectory=$HOME/.apps/maviskeleton
LimitNOFILE=4096
IgnoreSIGPIPE=false
KillMode=control-group
Restart=always
EOM
)

APPIUM_SERVICE_STR=$(
cat << EOM
[Unit]
Description=Appium Services
After=network.target
[Install]
WantedBy=multi-user.target
[Service]
ExecStartPre=-$HOME/Android/Sdk/platform-tools/adb start-server
ExecStart=$HOME/.apps/maviskeleton/appium-start.sh
WorkingDirectory=$HOME/.apps/maviskeleton
LimitNOFILE=4096
IgnoreSIGPIPE=false
KillMode=control-group
Restart=always
EOM
)

ANDROID_SERVICE_STR=$(
cat << EOM
[Unit]
Description=Android AVD Services
After=graphical.target
[Install]
WantedBy=multi-user.target
[Service]
ExecStartPre=-$HOME/Android/Sdk/platform-tools/adb start-server
ExecStart=$HOME/Android/Sdk/emulator/emulator -avd Pixel_4_XL_API_27
LimitNOFILE=4096
IgnoreSIGPIPE=false
KillMode=control-group
Restart=always
EOM
)

MAVISKELETON_ENV_STR=$(
cat << EOM
BASIC_USERNAME=$DEVICE_USERNAME
BASIC_PASSWORD=$DEVICE_SECRET
UNIQUE_KEY=$DEVICE_UNIQUE_KEY
WS_URL=wss://\${BASIC_USERNAME}:\${BASIC_PASSWORD}@ws.mavigenic.com/?key=\${UNIQUE_KEY}
REGION=$DEVICE_REGION
DEVICE_NAME=$DEVICE_NAME
EOM
)

# Menonaktifkan Brltty
echo "$sudoKS" | sudo -S systemctl disable brltty
echo "$sudoKS" | sudo -S systemctl mask brltty.path
echo "$sudoKS" | sudo -S apt purge brltty -y

# Menambahkan user ke group dialout
echo "$sudoKS" | sudo -S usermod -aG dialout "$USER"

echo "$sudoKS" | sudo -S apt-get update

# --------------
# Pemasangan Java JRE & Java JDK
# Dan keperluan lainya
# --------------
if ! command -v git > /dev/null ; then
  echo "Installing gil"
  echo "========================="

  echo "$sudoKS" | sudo -S apt install git
  echo -e "\n"
fi

if ! command -v unzip > /dev/null ; then
  echo "Installing Unzip"
  echo "========================="

  echo "$sudoKS" | sudo -S apt install unzip
  echo -e "\n"
fi

if ! command -v zip > /dev/null; then
  echo "Installing zip"
  echo "========================="

  echo "$sudoKS" | sudo -S apt install zip
  echo -e "\n"
fi

if ! command -v curl > /dev/null; then
  echo "Installing curl"
  echo "========================="

  echo "$sudoKS" | sudo -S apt install curl
  echo -e "\n"
fi

# --------------
# Pemasangan NVM
# --------------
if [ ! -f "$HOME/.nvm/nvm.sh" ]; then 
  echo "Installing NVM"
  echo "========================="

  curl -o- $NVM_URL | bash
  
  # "Sourcing" NVM
  source "$HOME"/.nvm/nvm.sh
  
  # Pemasangan Node.js LTS
  echo -e "\n"
  echo "Installing Node.JS LTS"
  echo "========================="
  nvm install --lts
  
  
  # Pemasangan Appium & appium-doctor
  echo -e "\n"
  echo "Installing Appium"
  echo "========================="
  npm install @appium/doctor appium@1.22 -g
fi


if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
  echo "Installing SDKMAN"
  echo "========================="
  
  curl -s $SDKMAN_URL | bash

  source "$HOME/.sdkman/bin/sdkman-init.sh"

  sdk install java 17.0.0-tem
  echo -e "\n"
fi

# --------------
# Pengunduhan Android Studio
# --------------
if [ ! -d "/usr/local/android-studio" ]; then
  echo "Installing Android Studio"
  echo "========================="

  wget $ANDROID_STUDIO_URL

  # Ekstrak Android Studio ke /usr/local/
  echo "$sudoKS" | sudo -S tar -xzf "$HOME/android-studio-2022.2.1.20-linux.tar.gz" -C /usr/local

  # Memasukan Env baru ke .bashrc
  echo -e "\n"
  echo "Inserting Path to .bashrc"
  echo "========================="
  echo "$ANDROID_PATH_STR" >> "$HOME"/.bashrc
  echo "$NEW_PATH_STR" >> "$HOME"/.bashrc
  echo -e "\n"
fi

# --------------
# Pemasangan Maviskeleton
# --------------
if [ ! -d "$HOME/.apps/maviskeleton" ]; then
  echo "Installing Maviskeleton"
  echo "========================="
  echo -e "\n"
  
  mkdir "$HOME"/.apps
  cd "$HOME/.apps" || exit

  # Kloning maviskeleton
  git clone "https://${unGithub}:${tknGithub}@github.com/mavigen-jogja/maviskeleton.git"

  # Masuk ke "folder" maviskeleton
  cd maviskeleton || exit

  # pemasangan kebutuhan
  npm install

  # Membuat file .env
  touch .env
  echo "$MAVISKELETON_ENV_STR" > .env

  # membuat file service
  touch "$HOME"/.config/systemd/user/maviskeleton.service
  echo "$MAVISKELETON_SERVICE_STR" >> "$HOME"/.config/systemd/user/maviskeleton.service

  touch "$HOME"/.config/systemd/user/appium-start.service
  echo "$APPIUM_SERVICE_STR" >> "$HOME"/.config/systemd/user/appium-start.service

  touch "$HOME"/.config/systemd/user/avd-start.service
  echo "$ANDROID_SERVICE_STR" >> "$HOME"/.config/systemd/user/avd-start.service

  # Membuat file start.sh
  touch start.sh
  echo "$START_SH_CONTENT" > start.sh

  touch appium-start.sh
  echo "$START_APPIUM_SH_CONTENT" > appium-start.sh

  # Buat start.sh dapat dijalankan
  chmod +x start.sh

  systemctl enable --user maviskeleton.service
fi
