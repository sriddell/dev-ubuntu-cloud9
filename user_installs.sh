
#!/bin/bash
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

sudo apt-get install -y curl git mercurial make binutils bison gcc build-essential
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
gvm install go1.4 -B

sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
curl https://pyenv.run | bash

cat <<EOF >> ~/.bashrc
export PATH="/home/ubuntu/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
cat <<EOF > ~/.bash_profile
if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi
EOF

pip3 install https://github.com/dlenski/vpn-slice/archive/master.zip

# gvm install go1.4 -B
# gvm use go1.4
# export GOROOT_BOOTSTRAP=$GOROOT
# gvm install go1.12.1