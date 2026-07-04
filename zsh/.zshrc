export PATH="$HOME/.local/bin:$PATH"
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
export HERMES_HOME="$HOME/.hermes"

# === History ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# не дублировать одинаковые команды
setopt HIST_IGNORE_DUPS
# сохранять историю сразу
setopt INC_APPEND_HISTORY
# делить историю между сессиями
setopt SHARE_HISTORY
# учитывать время выполнения
setopt EXTENDED_HISTORY

venvexp() {
    export OMP_NUM_THREADS=1
    export MKL_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export NUMEXPR_NUM_THREADS=1
    export LOKY_PICKLER="pickle"
    export CUDA_VISIBLE_DEVICES=""
    echo "Environment variables set for venvexp"
}

PROMPT='%F{#f0f0f0}%n%f@%F{#4a4a4a}%m%f:%F{#8a8a8a}%~%f $ '

source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias vencord='sh -c "$(curl -sS https://vencord.dev/install.sh)"'
alias nv='nvim'
alias yamusic='nohup ~/Downloads/Zen/YandexMusicMod-5.86.0-2.2.0.linux.AppImage'
