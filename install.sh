# Get OS type
os=`uname -a | awk '{print $1}'`
if [ $os == 'Linux' ]; then
    installer='yum'
elif [ $os == 'Darwin' ]; then
    installer='brew'
elif [ $os == 'FreeBSD' ]; then
    installer='pkg'
elif [ $os == 'Debian' ]; then
    installer='apt'
else
    echo "Unknown OS"
fi

# Install git

echo "Do you want to install git? [y/n]: "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Installing git"
    sudo $installer install git -y
else
    echo "Skipping git installation"
fi

# Install ZSH
echo "Do you want to install ZSH? [y/n]: "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Installing ZSH"
    sudo $installer install zsh -y
    echo "ZSH installed"
else
    echo "Skipping ZSH installation"
fi

# Install oh-my-zsh
echo "Do you want to install ohmyzsh? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install oh-my-zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Skipping ohmyzsh installation"
fi

# Install powerlevel10k
echo "Do you want to install powerlevel10k? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install powerlevel10k
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo "Skipping powerlevel10k installation"
fi

# Install zsh-autosuggestions
echo "Do you want to installzsh-autosuggestions? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
    echo "Skipping zsh-autosuggestions installation"
fi

# Install zsh-syntax-highlighting

echo "Do you want to install zsh-syntax-highlighting? [y/n] "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Installing..."
    # Install zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
    echo "Skipping zsh-syntax-highlighting installation"
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
echo "Creating symlink to the dotfiles in the home directory"

for file in ${PWD}/dotfiles/*; do
    ln -s $file ~/$(basename $file)
done

# Create bin directory in HOME
echo "Creating bin directory in HOME"
mkdir -p ~/bin

# Create symlink to the scripts in the bin directory
echo "Creating symlink to the scripts in the bin directory"

for file in ${PWD}/scripts/*; do
    ln -s $file ~/bin/$(basename $file)
done
echo "Done"

