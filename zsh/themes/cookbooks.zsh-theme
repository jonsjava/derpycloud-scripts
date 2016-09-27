get_cookbook_version(){
  for i in $(echo ". .. ../.. ../../.. ../../../.. ../../../../.. ../../../../../.. ../../../../../../.. ../../../../../../../.. ../../../../../../../../.."); do
    if [[ -f "${i}/metadata.rb" ]]; then
      cookbook_name=$(cat ${i}/metadata.rb|grep name|awk '{print $2}'|sed -e "s/'//g")
      recipes=$(echo "[$cookbook_name@"$(cat ${i}/metadata.rb|grep "version"|awk '{print $2}'|sed -e "s/'//g")"]")
    fi
  done
  echo $recipes
}
local ret_status="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )"
PROMPT='${ret_status} %{$fg[cyan]%}%c%{$reset_color%}%{$fg_bold[green]%} $(get_cookbook_version) %{$reset_color%} $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
