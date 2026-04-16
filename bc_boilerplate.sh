#!/bin/bash
set -euo pipefail
INFO_COLOR="\033[36;1m"
ERROR_COLOR="\033[31;1m"
SUCCESS_COLOR="\033[32;1m"
NO_COLOR="\033[0m"

check_prerequisites() {
    local errors=0

    echo -e "${INFO_COLOR}🔍 Checking prerequisites...${NO_COLOR}"

    # Git
    if ! command -v git &>/dev/null; then
        echo -e "${ERROR_COLOR}❌ git is not installed${NO_COLOR}"
        errors=$((errors + 1))
    else
        echo -e "${SUCCESS_COLOR}✅ git found: $(git --version)${NO_COLOR}"
    fi

    # Node.js
    if ! command -v node &>/dev/null; then
        echo -e "${ERROR_COLOR}❌ node is not installed${NO_COLOR}"
        errors=$((errors + 1))
    else
        echo -e "${SUCCESS_COLOR}✅ node found: $(node --version)${NO_COLOR}"
    fi

    # npm
    if ! command -v npm &>/dev/null; then
        echo -e "${ERROR_COLOR}❌ npm is not installed${NO_COLOR}"
        errors=$((errors + 1))
    else
        echo -e "${SUCCESS_COLOR}✅ npm found: $(npm --version)${NO_COLOR}"
    fi

    # VS Code
    if ! command -v code &>/dev/null; then
        echo -e "${ERROR_COLOR}❌ VS Code (code) is not in PATH${NO_COLOR}"
        errors=$((errors + 1))
    else
        echo -e "${SUCCESS_COLOR}✅ VS Code found${NO_COLOR}"
    fi

    # SSH key
    local ssh_key_found=0
    for key in ~/.ssh/id_ed25519 ~/.ssh/id_rsa ~/.ssh/id_ecdsa; do
        if [ -f "$key" ]; then
            echo -e "${SUCCESS_COLOR}✅ SSH key found: $key${NO_COLOR}"
            ssh_key_found=1
            break
        fi
    done
    if [ "$ssh_key_found" -eq 0 ]; then
        echo -e "${ERROR_COLOR}❌ No SSH key found in ~/.ssh/ (expected id_ed25519, id_rsa or id_ecdsa)${NO_COLOR}"
        errors=$((errors + 1))
    fi

    # SSH connection to GitHub
    local ssh_output
    ssh_output=$(ssh -T git@github.com -o StrictHostKeyChecking=no -o ConnectTimeout=5 2>&1) || true
    if echo "$ssh_output" | grep -q "successfully authenticated"; then
        echo -e "${SUCCESS_COLOR}✅ SSH connection to GitHub OK${NO_COLOR}"
    else
        echo -e "${ERROR_COLOR}❌ Cannot authenticate to GitHub via SSH (check your key is added on github.com)${NO_COLOR}"
        errors=$((errors + 1))
    fi

    if [ "$errors" -gt 0 ]; then
        echo -e "${ERROR_COLOR}\n❌ $errors prerequisite(s) failed. Fix them before running this script.${NO_COLOR}"
        exit 1
    fi

    echo -e "${SUCCESS_COLOR}\n✅ All prerequisites OK${NO_COLOR}\n"
}

create_local_git_repo() {
    local name="$1"
    

    echo -e "${INFO_COLOR}🚀 Running create_local_git_repo function ... ${NO_COLOR}"
    new_repo="bc_sign_$name"
    if [ -d "$new_repo" ]; then 
        echo -e "⚠️ The $new_repo already exists"
        exit 1
    fi
    mkdir "$new_repo"
    cd "$new_repo"
    code . 
    sleep 3

    if [ -d ".git" ]; then 
        echo -e "${ERROR_COLOR}⚠️ This folder is already a git repository ${NO_COLOR}"
        exit 1
    fi

    git init 
    { 
        echo "node_modules/" 
        echo ".env"

    } >> .gitignore
    if [ -z "$(git config --global user.name)" ]; then 
        read -r -p "What is your github user.name: " user_name
        if [ -z "$user_name" ]; then 
            echo -e "${ERROR_COLOR}❌ You need to provide a username ${NO_COLOR}"
            exit 1
        fi
        read -r -p "What is your github user.email: " user_email
        if [ -z "$user_email" ]; then 
            echo -e "${ERROR_COLOR}❌ You need to provide a user email ${NO_COLOR}"
            exit 1
        fi
        git config --global user.name "$user_name"
        git config --global user.email "$user_email"
        if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then 
            echo -e "${ERROR_COLOR}❌ Error while configuring your user_name and user_email ${NO_COLOR}"
            exit 1
        fi 
        echo -e "${INFO_COLOR}✅ Configuration of the user.name and user.email has been done successfully ${NO_COLOR}"
    fi
    username="$(git config --global user.name)"
    git remote add origin git@github.com:"${username}"/bc_sign_"${name}".git 
    git branch -M master
    echo "------------VERIFY INFO----------------"
    git remote -v
    echo "---------------------------------------"
    echo "# BC Sign Test Code Repo of ${name}" > README.md 
    git add .
    git commit -m "feat/README.md"
    if git push origin master; then 
        echo -e "${INFO_COLOR}✅ First push successfull${NO_COLOR}"
        echo -e "${INFO_COLOR}🚀 Creating branch dev for you ${NO_COLOR}"
        git branch dev
        echo -e "${INFO_COLOR}🚀 Creating branch product_owner for you ${NO_COLOR}"
        git branch product_owner
        echo -e "${INFO_COLOR}➡️ You will now work on the dev branch ${NO_COLOR}"
        git checkout dev 
        echo -e "${INFO_COLOR}➡️ You will now work on the dev branch ${NO_COLOR}"
        echo -e "${INFO_COLOR}➡️ All push must be to the dev branch now ex: git push origin dev ${NO_COLOR}"
        npm init -y 
        npm pkg set scripts.dev="node index.js"
        mkdir -p basics/utils
        touch basics/utils/data-format.js
        touch basics/utils/user-input.js
        touch index.js
        git add .
        git commit -m "feat/dev/basics"
        if git push origin dev; then 
            echo -e "${INFO_COLOR}✅ Dev First push successfull${NO_COLOR}"
        else 
            echo -e "${ERROR_COLOR}❌ Dev First push failed ${NO_COLOR}"
            exit 1 
        fi
    else 
        echo -e "${ERROR_COLOR}❌ First push failed ${NO_COLOR}" 
        exit 1
    fi

}


user_arg=${1:-""}

if [ -z "$user_arg" ]; then
    echo -e "${ERROR_COLOR}You must write a name ex: ./bc_boilerplate.sh boris ${NO_COLOR}"
    exit 1
else
    check_prerequisites
    create_local_git_repo "$1";
fi

