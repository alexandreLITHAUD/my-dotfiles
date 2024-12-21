# Custom theme based on robbyrussell with git branch warning and k8s context
PROMPT=''

# Function to get current kubernetes context
function get_k8s_context() {
  if command -v kubectl &> /dev/null; then
    echo "%F{magenta}($(kubectl config current-context 2>/dev/null))%f "
  fi
}

# Function to get git info with warning for main/master
function custom_git_prompt() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
    local git_status=$(git_prompt_status)
    
    # Add warning symbol for main/master branches
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
      echo "%{$fg[blue]%}git:(%{$fg_bold[red]%}ÔÜá´©Å ${branch}%{$fg[blue]%})${git_status}%{$reset_color%} "
    else
      echo "%{$fg[blue]%}git:(%{$fg[blue]%}${branch}%{$fg[blue]%})${git_status}%{$reset_color%} "
    fi
  fi
}

# Build the prompt - arrow first, then path, then git info
PROMPT+='%(?:%{$fg_bold[green]%}Ô×£  :%{$fg_bold[red]%}Ô×£  )%{$reset_color%}'
PROMPT+='%{$fg[cyan]%}%~%{$reset_color%} '
PROMPT+='$(custom_git_prompt)'
PROMPT+='$(get_k8s_context)'
