# Custom theme based on robbyrussell with git branch warning and k8s context
PROMPT=''

# Function to get current kubernetes context
function get_k8s_context() {
  if command -v kubectl &> /dev/null; then
    echo "%F{magenta}($(kubectl config current-context 2>/dev/null))%f "
  fi
}

# Function to get detailed git status
function custom_git_prompt() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local branch=$(git symbolic-ref HEAD 2>/dev/null | cut -d"/" -f 3)
    local git_status=""
    
    # Check for unstaged changes
    if [[ -n $(git status -s) ]]; then
      git_status+="Ô£ù"
    fi
    
    # Check for unpushed commits
    if [[ -n $(git log @{upstream}..HEAD 2>/dev/null) ]]; then
      git_status+="Ô¼å"
    fi
    
    # Add warning symbol for main/master branches
    if [[ "$branch" == "main" || "$branch" == "master" ]]; then
      echo "%{$fg[blue]%}git:(%{$fg_bold[red]%}ÔÜá´©Å ${branch}${git_status}%{$fg[blue]%})%{$reset_color%} "
    else
      echo "%{$fg[blue]%}git:(%{$fg_bold[red]%}${branch}${git_status}%{$fg[blue]%})%{$reset_color%} "
    fi
  fi
}

# Build the prompt - arrow first, then path, then git info
PROMPT+='%(?:%{$fg_bold[green]%}Ô×£ :%{$fg_bold[red]%}Ô×£ )%{$reset_color%}'
PROMPT+='%{$fg[cyan]%}%~%{$reset_color%} '
PROMPT+='$(custom_git_prompt)'
PROMPT+='$(get_k8s_context)'
