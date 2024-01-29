#!/bin/bash
#
# Script to clean your old branches.
# This script will filter your branch that already been pushed to remote repository 
# and now the branch already deleted from remote repository.
# If you never pushed the branch, it won't be listed and/or deleted by this script.
#

deleted_only=false

while getopts ":adh" OPTION; do
  case ${OPTION} in
    a)
      # When user passing option -a, will delete all the old branches.
      printf "Start to delete all old branches..."
      if git fetch -p; then
        echo ""
        echo "=================="
        echo "Deleted branches: "
        echo "=================="
        git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D
      fi
      exit 0
      ;;
    d)
      deleted_only=true
      ;;
    h)
      echo "Cleaning your repository from old branches."
      echo "This script will filter your branch that already been pushed to remote repository and now the branch already deleted from remote repository."
      echo "If you never pushed the branch, it won't be listed and/or deleted by this script."
      echo "Run the script and select which branch do you want to delete from the list."
      echo ""
      echo "Syntax: ./tools/git-clean-branch.sh [-a|h]"
      echo "options:"
      echo "  -a    delete all old branches"
      echo "  -d    show only local branches that already deleted on remote repository"
      echo "  -h    help (this output)"
      echo ""
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done

echo "Start fetching git..."
# Try to run "git fetch", if failed will just stop the process
if git fetch -p; then
    echo ""
else
    exit 1
fi

# Based on Bash Checkbox by @HadiDotSh
# https://github.com/HadiDotSh/bash-checkbox

if [ $deleted_only == true ]; then
    options=($(git branch -vv | awk '/: gone]/{print $1}'))
else
    options=($(git branch -vv | awk '{ if (index($1, "*")) { print ($0 ~ /: gone/ ? "[DELETED]-"$2 : ($0 ~ /\[origin\// ? "[REMOTE]-"$2 : "[LOCAL]-"$2 )) } else { print ($0 ~ /: gone/ ? "[DELETED]-"$1 : ($0 ~ /\[origin\// ? "[REMOTE]-"$1 : "[LOCAL]-"$1 )) } }'))
fi

# Loop through each options element to modify it
for ((i=0; i<${#options[@]}; i++)); do
    # Add proper space, since on awk command we use whitespace as separator to create the array
    initialstring=${options[i]}
    if [[ $initialstring == "[DELETED]-"* ]]; then
        old_sequence="\[DELETED\]-"
        new_sequence="[DELETED] - "
    elif [[ $initialstring == "[REMOTE]-"* ]]; then
        old_sequence="\[REMOTE\]-"
        new_sequence="[REMOTE]  - "
    elif [[ $initialstring == "[LOCAL]-"* ]]; then
        old_sequence="\[LOCAL\]-"
        new_sequence="[LOCAL]   - "
    else
        old_sequence=""
        new_sequence=""
    fi

    result="${initialstring//$old_sequence/$new_sequence}"
    options[i]=$result
done

max=${#options[@]}

if [ max == 0 ]; then
    printf "\e[32mNo branch!\e[0m\n"
    exit 0
fi

clear
printf "Select old branches that you want to delete using \e[1;32marrow keys\e[0m and \e[1;32mspacebar\e[0m.\n"
printf "And press \e[1;32mENTER\e[0m to submit your selection.\n"
printf "\e[3;90mIf you want to delete all old branches, you could use './tools/git-clean-branch.sh -a'\e[0m\n"
printf "\e[3;90mOr, if you want to show only remote-deleted branches, you could use './tools/git-clean-branch.sh -d'\e[0m\n"
printf "=====================================================================\n"
current=0
tput sc

for (( i=0 ; i<max ; i++ ));do
    selected[${i}]=false
done

function keyboard(){
    IFS= read -r -sn1 t
    if [[ $t == A ]]; then
        [[ "$current" == "0" ]] || current=$((current - 1))
        
    elif [[ $t == B ]]; then
        [[ "$current" == "$1" ]] || current=$((current + 1))
    
    elif [[ $t == " " ]];then
        [[ "${selected[${current}]}" == false ]] && selected[${current}]=true || selected[${current}]=false
    
    elif [[ $t == "" ]];then
        break
    fi
}

function display(){
    tput rc
    for (( i=0 ; i<max ; i++ ));do
        if [[ ${current} == "${i}" && ${selected[${i}]} == true ]];then
            printf "\e[0;90m[\e[0;93m*\e[0;90m] \e[0m\e[0;93m%s\e[0m\n" "${options[$i]}"

        elif [[ ${current} == "${i}" && ${selected[${i}]} == false ]];then
            printf "\e[0;90m[ ] \e[0m\e[0;93m%s\e[0m\n" "${options[$i]}"

        elif [[ ${selected[${i}]} == true ]];then
            printf "\e[0;90m[\e[0;93m*\e[0;90m] \e[0m\e[1;77m%s\e[0m\n" "${options[$i]}"

        elif [[ ${selected[${i}]} == false ]];then
            printf "\e[0;90m[ ] \e[0m\e[1;77m%s\e[0m\n" "${options[$i]}"
        fi
    done
}

while true;do
    display "$@"
    keyboard $((max-1))
done
current=-1
display "$@"

# End of Bash Checkbox

count_selected=0
branch_name=""
for (( i=0 ; i<max ; i++ ));do
    if [ ${selected[$i]} == true ];then
        if [ ${count_selected} == 0 ];then
            printf "\nList of branches:\n"
        fi

        echo "--> ${options[$i]}"
        count_selected=$((count_selected+1))
        branch_name="${branch_name} ${options[$i]}"
    fi
done

# If user not select any branch, just exit the program.
if [ ${count_selected} == 0 ];then
    echo "No branch is selected :("
    exit 0
fi

# User confirmation before deleting the branch
question_text=""
if [ ${count_selected} == 1 ];then
    question_text="Are you sure you want to delete this branch? [Y/n] "
else
    question_text="Are you sure you want to delete these branches? [Y/n] "
fi
printf "\e[3;91m${question_text}\e[0m"
read -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]];then
    printf "\nDeleting selected branch...\n"

    # Remove occurrences of the string
    selected_branches=$(echo "$branch_name" | sed "s/\[DELETED\] - //g")
    selected_branches=$(echo "$selected_branches" | sed "s/\[REMOTE\]  - //g")
    selected_branches=$(echo "$selected_branches" | sed "s/\[LOCAL\]   - //g")

    git branch -D ${selected_branches}
    printf "\e[1;32mDONE!\e[0m"
else
    printf "\nProcess is aborted!"
    printf "\nPlease reply with Y or y if you want to delete the branches that you already selected."
    exit 0
fi
