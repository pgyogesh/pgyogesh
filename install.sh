# Install git

echo -n "Do you want to install git? [y/n]: "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Installing git"
    sudo yum install git -y
else
    echo "Skipping git installation"
fi

# Install ZSH
echo -n "Do you want to install ZSH? [y/n]: "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Installing ZSH"
    sudo yum install zsh -y
    echo "ZSH installed"
else
    echo "Skipping ZSH installation"
fi

# Install oh-my-zsh
echo -n "Do you want to install ohmyzsh? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Exiting..."
    exit 1
fi

# Install powerlevel10k
echo -n "Do you want to install powerlevel10k? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install powerlevel10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo "Exiting..."
    exit 1
fi

# Install zsh-autosuggestions
echo -n "Do you want to installzsh-autosuggestions? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
    echo "Exiting..."
    exit 1
fi

# backup existing dotfiles

if [ -f ~/.zshrc ]; then
    echo "Backing up existing .zshrc"
    mv ~/.zshrc ~/.zshrc.bak
fi

if [ -f ~/.p10k.zsh ]; then
    echo "Backing up existing .p10k.zsh"
    mv ~/.p10k.zsh ~/.p10k.zsh.bak
fi

if [ -f ~/.profile.aliases ]; then
    echo "Backing up existing .profile.aliases"
    mv ~/.profile.aliases ~/.profile.aliases.bak
fi

if [ -f ~/.profile.functions ]; then
    echo "Backing up existing .profile.functions"
    mv ~/.profile.functions ~/.profile.functions.bak
fi

if [ -f ~/.myprofile ]; then
    echo "Backing up existing .myprofile"
    mv ~/.myprofile ~/.myprofile.bak
fi


# Create symlink to the dotfiles in the home directory
ln -s ${PWD}/dotfiles/.zshrc ~/.zshrc
ln -s ${PWD}/dotfiles/.profile.aliases ~/.profile.aliases
ln -s ${PWD}/dotfiles/.profile.functions ~/.profile.functions
ln -s ${PWD}/dotfiles/.p10k.zsh ~/.p10k.zsh
ln -s ${PWD}/dotfiles/.myprofile ~/.myprofile

# Create bin directory in HOME
mkdir -p ~/bin

# Create symlink to the scripts in the bin directory

ln -s ${PWD}/scripts/gcp ~/bin/gcp
ln -s ${PWD}/scripts/gke ~/bin/gke
ln -s ${PWD}/scripts/collect-k8spod-logs.sh ~/bin/collect-k8spod-logs.sh
