#!/bin/bash

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to display colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_color $RED "Error: Not a git repository!"
        return 1
    fi
    return 0
}

# Function to get current branch
get_current_branch() {
    git branch --show-current 2>/dev/null || echo "detached-head"
}

# Function to show current status
show_status() {
    print_color $CYAN "=== Current Repository Status ==="
    if check_git_repo; then
        current_branch=$(get_current_branch)
        if [ "$current_branch" = "detached-head" ]; then
            print_color $RED "⚠️  DETACHED HEAD STATE"
            echo "Current commit: $(git log --oneline -1 2>/dev/null)"
        else
            print_color $GREEN "✓ On branch: $current_branch"
        fi
        echo "Repository: $(basename $(git rev-parse --show-toplevel 2>/dev/null))"
        git status --short 2>/dev/null
    else
        print_color $YELLOW "Not in a Git repository"
    fi
    echo
}

# Function to setup GitHub credentials
setup_github_credentials() {
    print_color $CYAN "=== GitHub Credentials Setup ==="
    read -p "Enter GitHub Username: " GITHUB_USERNAME
    read -s -p "Enter GitHub Token: " GITHUB_TOKEN
    echo
    
    export GITHUB_USERNAME="$GITHUB_USERNAME"
    export GITHUB_TOKEN="$GITHUB_TOKEN"
    
    print_color $GREEN "✓ GitHub credentials exported successfully!"
    echo
}

# Category 1: Start a working area
start_working_area() {
    while true; do
        print_color $PURPLE "=== Start a Working Area ==="
        echo "1. Clone a repository"
        echo "2. Initialize new repository"
        echo "3. Back to main menu"
        read -p "Select option (1-3): " choice
        
        case $choice in
            1)
                read -p "Enter repository URL to clone: " repo_url
                if [ -n "$repo_url" ]; then
                    git clone "$repo_url"
                    if [ $? -eq 0 ]; then
                        print_color $GREEN "✓ Repository cloned successfully!"
                    fi
                fi
                ;;
            2)
                read -p "Enter directory name (or press Enter for current): " dir_name
                if [ -z "$dir_name" ]; then
                    git init
                else
                    git init "$dir_name"
                fi
                if [ $? -eq 0 ]; then
                    print_color $GREEN "✓ Git repository initialized!"
                fi
                ;;
            3) break ;;
            *) print_color $RED "Invalid option!" ;;
        esac
        echo
    done
}

# Category 2: Work on current change
work_on_change() {
    while true; do
        print_color $PURPLE "=== Work on Current Change ==="
        echo "1. Add files to index"
        echo "2. Move/rename files"
        echo "3. Reset changes"
        echo "4. Remove files"
        echo "5. Show changes (diff)"
        echo "6. Back to main menu"
        read -p "Select option (1-6): " choice
        
        case $choice in
            1)
                echo "Select files to add:"
                echo "1. All changes"
                echo "2. Specific file"
                echo "3. Interactive add"
                read -p "Choose (1-3): " add_choice
                case $add_choice in
                    1) git add . ;;
                    2) 
                        read -p "Enter filename: " filename
                        git add "$filename" 
                        ;;
                    3) git add -i ;;
                    *) print_color $RED "Invalid choice!" ;;
                esac
                print_color $GREEN "✓ Files added to index"
                ;;
            2)
                read -p "Enter source file: " source
                read -p "Enter destination: " dest
                git mv "$source" "$dest" 2>/dev/null && print_color $GREEN "✓ File moved" || print_color $RED "Move failed"
                ;;
            3)
                echo "Reset type:"
                echo "1. Soft (keep changes in working directory)"
                echo "2. Mixed (keep changes but not staged)"
                echo "3. Hard (discard all changes)"
                read -p "Choose (1-3): " reset_type
                case $reset_type in
                    1) git reset --soft HEAD~1 ;;
                    2) git reset HEAD~1 ;;
                    3) git reset --hard HEAD~1 ;;
                    *) print_color $RED "Invalid choice!" ;;
                esac
                ;;
            4)
                read -p "Enter file to remove: " file
                git rm "$file" 2>/dev/null && print_color $GREEN "✓ File removed" || print_color $RED "Remove failed"
                ;;
            5)
                git diff
                ;;
            6) break ;;
            *) print_color $RED "Invalid option!" ;;
        esac
        echo
    done
}

# Category 3: Examine history and state
examine_history() {
    while true; do
        print_color $PURPLE "=== Examine History and State ==="
        echo "1. Show status"
        echo "2. Show commit log"
        echo "3. Show specific commit"
        echo "4. Search in commits (grep)"
        echo "5. Binary search for bugs (bisect)"
        echo "6. Back to main menu"
        read -p "Select option (1-6): " choice
        
        case $choice in
            1) git status ;;
            2)
                echo "Log format:"
                echo "1. Simple (oneline)"
                echo "2. Detailed"
                echo "3. With graph"
                read -p "Choose (1-3): " log_choice
                case $log_choice in
                    1) git log --oneline -20 ;;
                    2) git log -10 ;;
                    3) git log --oneline --graph -20 ;;
                    *) git log --oneline -10 ;;
                esac
                ;;
            3)
                read -p "Enter commit hash: " commit_hash
                git show "$commit_hash"
                ;;
            4)
                read -p "Enter search pattern: " pattern
                git grep "$pattern"
                ;;
            5)
                print_color $YELLOW "Starting git bisect..."
                git bisect start
                read -p "Is the current commit good or bad? (g/b): " bisect_choice
                if [[ $bisect_choice == "b" ]]; then
                    git bisect bad
                else
                    git bisect good
                fi
                ;;
            6) break ;;
            *) print_color $RED "Invalid option!" ;;
        esac
        echo
    done
}

# Category 4: Grow, mark and tweak history
manage_history() {
    while true; do
        print_color $PURPLE "=== Grow, Mark and Tweak History ==="
        echo "1. Branch operations"
        echo "2. Checkout/switch"
        echo "3. Commit changes"
        echo "4. Merge branches"
        echo "5. Rebase branches"
        echo "6. Tag operations"
        echo "7. Back to main menu"
        read -p "Select option (1-7): " choice
        
        case $choice in
            1)
                echo "Branch operations:"
                echo "1. List branches"
                echo "2. Create branch"
                echo "3. Delete branch"
                read -p "Choose (1-3): " branch_choice
                case $branch_choice in
                    1) git branch -a ;;
                    2) 
                        read -p "Enter branch name: " branch_name
                        git branch "$branch_name" 
                        ;;
                    3)
                        read -p "Enter branch to delete: " del_branch
                        git branch -d "$del_branch" 2>/dev/null || git branch -D "$del_branch"
                        ;;
                esac
                ;;
            2)
                git branch -a
                read -p "Enter branch to checkout: " branch
                git checkout "$branch" 2>/dev/null && print_color $GREEN "✓ Checked out to $branch" || print_color $RED "Checkout failed"
                ;;
            3)
                git status
                read -p "Enter commit message: " commit_msg
                if [ -n "$commit_msg" ]; then
                    git commit -m "$commit_msg"
                else
                    git commit
                fi
                ;;
            4)
                git branch -a
                read -p "Enter branch to merge: " merge_branch
                git merge "$merge_branch"
                ;;
            5)
                git branch -a
                read -p "Enter branch to rebase onto: " rebase_branch
                git rebase "$rebase_branch"
                ;;
            6)
                echo "Tag operations:"
                echo "1. List tags"
                echo "2. Create tag"
                echo "3. Delete tag"
                read -p "Choose (1-3): " tag_choice
                case $tag_choice in
                    1) git tag ;;
                    2)
                        read -p "Enter tag name: " tag_name
                        git tag "$tag_name"
                        ;;
                    3)
                        read -p "Enter tag to delete: " del_tag
                        git tag -d "$del_tag"
                        ;;
                esac
                ;;
            7) break ;;
            *) print_color $RED "Invalid option!" ;;
        esac
        echo
    done
}

# Category 5: Collaborate
collaborate() {
    while true; do
        print_color $PURPLE "=== Collaborate ==="
        echo "1. Fetch from remote"
        echo "2. Pull from remote"
        echo "3. Push to remote"
        echo "4. Show remotes"
        echo "5. Add remote"
        echo "6. Back to main menu"
        read -p "Select option (1-6): " choice
        
        case $choice in
            1) 
                git fetch
                print_color $GREEN "✓ Fetched from remote"
                ;;
            2)
                git pull
                print_color $GREEN "✓ Pulled from remote"
                ;;
            3)
                current_branch=$(get_current_branch)
                if [ "$current_branch" = "detached-head" ]; then
                    print_color $RED "Cannot push from detached HEAD"
                else
                    git push origin "$current_branch"
                    print_color $GREEN "✓ Pushed to remote"
                fi
                ;;
            4)
                git remote -v
                ;;
            5)
                read -p "Enter remote name: " remote_name
                read -p "Enter remote URL: " remote_url
                git remote add "$remote_name" "$remote_url"
                print_color $GREEN "✓ Remote added"
                ;;
            6) break ;;
            *) print_color $RED "Invalid option!" ;;
        esac
        echo
    done
}

# Function to show git configuration
show_config() {
    print_color $CYAN "=== Git Configuration ==="
    echo "1. Show all config"
    echo "2. Show user config"
    echo "3. Set user config"
    echo "4. Back to main menu"
    read -p "Select option (1-4): " choice
    
    case $choice in
        1) git config --list ;;
        2)
            echo "User name: $(git config user.name)"
            echo "User email: $(git config user.email)"
            ;;
        3)
            read -p "Enter user name: " user_name
            read -p "Enter user email: " user_email
            git config user.name "$user_name"
            git config user.email "$user_email"
            print_color $GREEN "✓ User config updated"
            ;;
        4) return ;;
        *) print_color $RED "Invalid option!" ;;
    esac
}

# Main menu
main_menu() {
    while true; do
        clear
        print_color $BLUE "========================================="
        print_color $BLUE "           Git Dynamic Helper"
        print_color $BLUE "========================================="
        echo
        
        show_status
        
        print_color $CYAN "Main Menu:"
        echo "1.  Start a Working Area (clone, init)"
        echo "2.  Work on Current Change (add, reset, rm, mv, diff)"
        echo "3.  Examine History and State (status, log, show, grep, bisect)"
        echo "4.  Grow, Mark and Tweak History (branch, checkout, commit, merge, rebase, tag)"
        echo "5.  Collaborate (fetch, pull, push, remote)"
        echo "6.  Setup GitHub Credentials"
        echo "7.  Git Configuration"
        echo "8.  Exit"
        echo
        
        read -p "Select an option (1-8): " choice
        
        case $choice in
            1) start_working_area ;;
            2) work_on_change ;;
            3) examine_history ;;
            4) manage_history ;;
            5) collaborate ;;
            6) setup_github_credentials ;;
            7) show_config ;;
            8)
                print_color $GREEN "Goodbye! Happy coding!"
                exit 0
                ;;
            *)
                print_color $RED "Invalid option! Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Initial setup
clear
print_color $BLUE "========================================="
print_color $BLUE "           Git Dynamic Helper"
print_color $BLUE "========================================="
echo
print_color $YELLOW "This script provides an interactive interface for common Git operations"
echo

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_color $RED "Git is not installed! Please install git first."
    exit 1
fi

# Start the main menu
main_menu
