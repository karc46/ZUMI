#!/bin/bash

# ──────────────────────────────────────────────
# Colors for output
# ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# ──────────────────────────────────────────────
# Git Context Detection
# ──────────────────────────────────────────────
detect_environment() {
    # Get current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    # Get all branches
    ALL_BRANCHES=$(git branch -a 2>/dev/null)
    
    # Detect role based on branch name and directory
    if [[ "$CURRENT_BRANCH" == *"Developer"* ]] || [[ "$PWD" == *"Developer"* ]]; then
        ROLE="developer"
        DEVELOPER_NAME=$(echo "$CURRENT_BRANCH" | cut -d'/' -f2)
    elif [[ "$CURRENT_BRANCH" == *"QA"* ]] || [[ -d "QA_Team" ]] || [[ "$PWD" == *"QA_Team"* ]]; then
        ROLE="qa"
    elif [[ "$CURRENT_BRANCH" == *"F_Release"* ]] || [[ -d "F_Release" ]] || [[ "$PWD" == *"F_Release"* ]]; then
        ROLE="manager"
    else
        ROLE="unknown"
    fi
    
    # Print current context
    print_info "Current branch: $CURRENT_BRANCH"
    print_info "Detected role: $ROLE"
    if [[ -n "$DEVELOPER_NAME" ]]; then
        print_info "Developer: $DEVELOPER_NAME"
    fi
}

list_developer_branches() {
    print_info "Available Developer Branches:"
    git branch -a | grep -E "Developer/|developer/" | while read branch; do
        if [[ "$branch" == *"*"* ]]; then
            echo -e "${GREEN}  ➤ $branch${NC}"
        else
            echo "    $branch"
        fi
    done
    
    git branch -a | grep -v -E "Developer/|developer/" | while read branch; do
        if [[ "$branch" == *"*"* ]]; then
            echo -e "${YELLOW}  ➤ $branch${NC}"
        else
            echo "    $branch"
        fi
    done
}

# ──────────────────────────────────────────────
# Developer Functions (Enhanced)
# ──────────────────────────────────────────────
developer_branch_manager() {
    local action=""
    local branch_name=""
    local switch_branch=""
    local commit_message=""
    local file_path=""
    local developer_name=""

    # Auto-detect developer name from current branch
    if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" == *"Developer"* ]]; then
        developer_name=$(echo "$CURRENT_BRANCH" | cut -d'/' -f2)
        print_info "Auto-detected developer: $developer_name"
    fi

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --create)
                action="create"
                if [[ -n "$2" && "$2" != *"Developer"* ]]; then
                    branch_name="Developer/$2"
                else
                    branch_name="$2"
                fi
                shift 2
                ;;
            --delete)
                action="delete"
                branch_name="$2"
                shift 2
                ;;
            --switch)
                switch_branch="$2"
                shift 2
                ;;
            --commit)
                action="commit"
                file_path="$2"
                commit_message="$3"
                shift 3
                ;;
            --push-to-qa)
                action="push_to_qa"
                if [[ -n "$2" ]]; then
                    branch_name="$2"
                elif [[ -n "$CURRENT_BRANCH" ]]; then
                    branch_name="$CURRENT_BRANCH"
                    print_info "Auto-using current branch: $branch_name"
                fi
                shift 2
                ;;
            --list-branches)
                action="list_branches"
                shift
                ;;
            --auto-setup)
                action="auto_setup"
                if [[ -n "$2" ]]; then
                    developer_name="$2"
                fi
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                developer_usage
                return 1
                ;;
        esac
    done

    [[ -z "$action" ]] && developer_usage && return 1

    case "$action" in
        create)
            create_branch "$branch_name"
            ;;
        delete)
            delete_branch "$branch_name" "$switch_branch"
            ;;
        commit)
            commit_changes "$file_path" "$commit_message"
            ;;
        push_to_qa)
            push_to_qa "$branch_name"
            ;;
        list_branches)
            list_developer_branches
            ;;
        auto_setup)
            auto_setup_developer "$developer_name"
            ;;
    esac
}

developer_usage() {
    echo "Developer Usage:"
    echo "  $0 --list-branches                    # List all branches with developer branches highlighted"
    echo "  $0 --auto-setup [developer_name]      # Auto-setup developer environment"
    echo "  $0 --create <branch_name>             # Create developer branch (auto-prefixes with Developer/)"
    echo "  $0 --delete <branch_name> [--switch <other_branch>]"
    echo "  $0 --commit <file_path> \"<commit_message>\""
    echo "  $0 --push-to-qa [branch_name]         # Push current branch to QA (auto-detects branch)"
    echo
    echo "Examples:"
    echo "  $0 --auto-setup karthi               # Auto setup for developer karthi"
    echo "  $0 --create karthi                    # Creates Developer/karthi branch"
    echo "  $0 --commit \"bluetooth\" \"Added bluetooth source code\""
    echo "  $0 --push-to-qa                      # Auto-push current branch to QA"
}

auto_setup_developer() {
    local developer_name="$1"
    
    if [[ -z "$developer_name" ]]; then
        read -p "Enter your developer name: " developer_name
    fi
    
    if [[ -z "$developer_name" ]]; then
        print_error "Developer name is required"
        return 1
    fi
    
    local developer_branch="Developer/$developer_name"
    
    print_info "Setting up developer environment for: $developer_name"
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$developer_branch"; then
        print_info "Branch $developer_branch already exists. Switching to it..."
        git checkout "$developer_branch"
    else
        print_info "Creating new developer branch: $developer_branch"
        git checkout -b "$developer_branch"
    fi
    
    print_success "Developer setup complete! You are now on branch: $developer_branch"
    print_info "You can now start developing and use: $0 --push-to-qa to send to QA team"
}

create_branch() {
    local branch_name="$1"
    
    # Auto-prefix with Developer/ if not already
    if [[ "$branch_name" != *"Developer"* ]]; then
        branch_name="Developer/$branch_name"
    fi
    
    print_info "Creating new branch '$branch_name'..."
    
    git checkout -b "$branch_name" || { 
        print_error "Failed to create branch '$branch_name'"
        return 1
    }
    
    git push -u origin "$branch_name" && 
    print_success "Branch '$branch_name' created and pushed to origin"
}

delete_branch() {
    local branch_name="$1"
    local switch_branch="$2"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [[ "$current_branch" == "$branch_name" ]]; then
        if [[ -z "$switch_branch" ]]; then
            print_warning "You are on '$branch_name'. Use --switch <branch> to switch first."
            return 1
        fi
        print_info "Switching to '$switch_branch' before deleting..."
        git checkout "$switch_branch" || {
            print_error "Failed to switch branch"
            return 1
        }
    fi

    # Delete local branch
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        git branch -D "$branch_name"
        print_success "Local branch '$branch_name' deleted"
    else
        print_warning "No local branch named '$branch_name'"
    fi

    # Delete remote branch
    if git ls-remote --exit-code origin "$branch_name" &>/dev/null; then
        git push origin --delete "$branch_name"
        print_success "Remote branch '$branch_name' deleted"
    else
        print_warning "No remote branch named '$branch_name' found"
    fi
}

commit_changes() {
    local file_path="$1"
    local commit_message="$2"
    
    # Check if file exists
    if [[ ! -e "$file_path" ]]; then
        print_error "File or directory '$file_path' does not exist"
        return 1
    fi
    
    print_info "Adding file: $file_path"
    git add "$file_path" || {
        print_error "Failed to add file: $file_path"
        return 1
    }
    
    print_info "Committing changes: $commit_message"
    git commit -m "$commit_message" || {
        print_error "Failed to commit changes"
        return 1
    }
    
    print_success "Changes committed successfully"
}

push_to_qa() {
    local branch_name="$1"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Use current branch if no branch specified
    if [[ -z "$branch_name" ]]; then
        branch_name="$current_branch"
        print_info "Auto-using current branch: $branch_name"
    fi
    
    # Ensure we're on the right branch
    if [[ "$current_branch" != "$branch_name" ]]; then
        print_info "Switching to branch: $branch_name"
        git checkout "$branch_name" || {
            print_error "Failed to switch to branch $branch_name"
            return 1
        }
    fi
    
    print_info "Pushing branch '$branch_name' to origin..."
    git push -u origin "$branch_name" || {
        print_error "Failed to push branch '$branch_name'"
        return 1
    }
    
    print_success "Branch '$branch_name' pushed to origin"
    print_info "Data copied to QA team for testing"
    print_info "QA team can now test your changes using: $0 --test-branch $branch_name"
}

# ──────────────────────────────────────────────
# QA Team Functions (Enhanced)
# ──────────────────────────────────────────────
qa_team() {
    local action=""
    local branch_name=""
    local file_path=""
    local commit_message=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clone)
                action="clone"
                shift
                ;;
            --commit)
                action="commit"
                file_path="$2"
                commit_message="$3"
                shift 3
                ;;
            --push)
                action="push"
                branch_name="$2"
                shift 2
                ;;
            --approve)
                action="approve"
                branch_name="$2"
                shift 2
                ;;
            --reject)
                action="reject"
                branch_name="$2"
                shift 2
                ;;
            --test-branch)
                action="test_branch"
                branch_name="$2"
                shift 2
                ;;
            --list-developer-branches)
                action="list_developer_branches"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                qa_usage
                return 1
                ;;
        esac
    done

    [[ -z "$action" ]] && qa_usage && return 1

    case "$action" in
        clone)
            qa_clone
            ;;
        commit)
            qa_commit "$file_path" "$commit_message"
            ;;
        push)
            qa_push "$branch_name"
            ;;
        approve)
            qa_approve "$branch_name"
            ;;
        reject)
            qa_reject "$branch_name"
            ;;
        test_branch)
            qa_test_branch "$branch_name"
            ;;
        list_developer_branches)
            list_developer_branches
            ;;
    esac
}

qa_usage() {
    echo "QA Team Usage:"
    echo "  $0 --clone"
    echo "  $0 --commit <file_path> \"<commit_message>\""
    echo "  $0 --push <branch_name>"
    echo "  $0 --approve <branch_name>"
    echo "  $0 --reject <branch_name>"
    echo "  $0 --test-branch <branch_name>      # Test a developer branch"
    echo "  $0 --list-developer-branches        # List available developer branches"
    echo
    echo "Examples:"
    echo "  $0 --clone"
    echo "  $0 --test-branch Developer/karthi   # Test developer karthi's branch"
    echo "  $0 --approve Developer/karthi       # Approve for release"
    echo "  $0 --reject Developer/karthi        # Reject and send for bugfix"
}

qa_clone() {
    if [[ -d "QA_Team" ]]; then
        print_warning "QA_Team directory already exists"
        cd QA_Team
        return 0
    fi
    
    print_info "Cloning repository for QA Team..."
    git clone https://github.com/karc46/ZUMI.git QA_Team || {
        print_error "Failed to clone repository"
        return 1
    }
    
    cd QA_Team
    print_success "Repository cloned successfully to QA_Team/"
}

qa_commit() {
    local file_path="$1"
    local commit_message="$2"
    
    if [[ ! -d "QA_Team" ]]; then
        qa_clone
    else
        cd QA_Team
    fi
    
    commit_changes "$file_path" "$commit_message"
}

qa_push() {
    local branch_name="$1"
    
    if [[ ! -d "QA_Team" ]]; then
        print_error "QA_Team directory not found. Run --clone first."
        return 1
    fi
    
    cd QA_Team
    
    # Check if branch exists, if not create it
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        git checkout -b "$branch_name" || {
            print_error "Failed to create branch '$branch_name'"
            return 1
        }
    else
        git checkout "$branch_name" || {
            print_error "Failed to switch to branch '$branch_name'"
            return 1
        }
    fi
    
    print_info "Pushing to branch '$branch_name'..."
    git push -u origin "$branch_name" || {
        print_error "Failed to push to branch '$branch_name'"
        return 1
    }
    
    print_success "Successfully pushed to QA branch: $branch_name"
}

qa_test_branch() {
    local branch_name="$1"
    
    print_info "Testing developer branch: $branch_name"
    
    if [[ ! -d "QA_Team" ]]; then
        qa_clone
    else
        cd QA_Team
    fi
    
    # Fetch the latest changes
    git fetch origin
    
    # Check if branch exists remotely
    if ! git ls-remote --exit-code origin "$branch_name" &>/dev/null; then
        print_error "Branch '$branch_name' not found in remote"
        return 1
    fi
    
    # Create a local testing branch
    local test_branch="test/$branch_name"
    if git show-ref --verify --quiet "refs/heads/$test_branch"; then
        git branch -D "$test_branch"
    fi
    
    git checkout -b "$test_branch" "origin/$branch_name" || {
        print_error "Failed to create test branch"
        return 1
    }
    
    print_success "Created test branch: $test_branch"
    print_info "You can now test the changes from $branch_name"
    
    # Ask for test result
    echo
    read -p "Test result for $branch_name? (pass/fail): " test_result
    case "${test_result,,}" in
        pass|p|ok|success)
            qa_approve "$branch_name"
            ;;
        fail|f|error|bug)
            qa_reject "$branch_name"
            ;;
        *)
            print_warning "Test result not recorded. Use --approve or --reject later."
            ;;
    esac
}

qa_approve() {
    local branch_name="$1"
    print_success "✅ Branch $branch_name APPROVED for release"
    print_info "Sending to F_Release..."
    print_info "Developer work is ready for production release!"
}

qa_reject() {
    local branch_name="$1"
    print_error "❌ Branch $branch_name REJECTED"
    print_info "Sending back for Bug_Fix..."
    print_info "Developer needs to fix issues and resubmit"
}

# ──────────────────────────────────────────────
# Manager Functions
# ──────────────────────────────────────────────
manager() {
    local action=""
    local password=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clone-release)
                action="clone_release"
                shift
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                manager_usage
                return 1
                ;;
        esac
    done

    [[ -z "$action" ]] && manager_usage && return 1

    case "$action" in
        clone_release)
            if [[ -z "$password" ]]; then
                read -s -p "Enter manager password: " password
                echo
            fi
            clone_release "$password"
            ;;
    esac
}

manager_usage() {
    echo "Manager Usage:"
    echo "  $0 --clone-release [--password <password>]"
    echo
    echo "Example:"
    echo "  $0 --clone-release"
    echo "  $0 --clone-release --password your_password"
}

clone_release() {
    local password="$1"
    local correct_password="zs10062013"
    
    if [[ "$password" != "$correct_password" ]]; then
        print_error "❌ Incorrect password! Access denied."
        return 1
    fi
    
    if [[ -d "F_Release" ]]; then
        print_warning "F_Release directory already exists"
        return 0
    fi
    
    print_info "Cloning F_Release repository..."
    git clone https://github.com/karc46/ZUMI.git F_Release || {
        print_error "Failed to clone F_Release repository"
        return 1
    }
    
    print_success "F_Release repository cloned successfully"
}

# ──────────────────────────────────────────────
# Main Script (Enhanced)
# ──────────────────────────────────────────────
main() {
    # First, detect current git context
    detect_environment
    
    # If no arguments provided, show context-aware menu
    if [[ $# -eq 0 ]]; then
        echo
        print_info "Current Context:"
        print_info "  Branch: $CURRENT_BRANCH"
        print_info "  Role: $ROLE"
        
        case "$ROLE" in
            developer)
                echo
                print_info "Developer Commands:"
                echo "  $0 --auto-setup [name]    # Setup developer environment"
                echo "  $0 --list-branches        # List all branches"
                echo "  $0 --push-to-qa          # Push current branch to QA"
                echo "  $0 --help-developer       # All developer commands"
                ;;
            qa)
                echo
                print_info "QA Team Commands:"
                echo "  $0 --test-branch <branch> # Test a developer branch"
                echo "  $0 --list-developer-branches # List developer branches"
                echo "  $0 --help-qa             # All QA commands"
                ;;
            manager)
                echo
                print_info "Manager Commands:"
                echo "  $0 --clone-release       # Clone release repository"
                echo "  $0 --help-manager        # All manager commands"
                ;;
            *)
                echo
                echo "Are you developer/QA_team/Manager? "
                read -p "Enter your role: " user_role
                case "${user_role,,}" in
                    developer|dev)
                        print_info "Developer mode selected"
                        echo "Use: $0 --auto-setup [name] to get started"
                        ;;
                    qa|qa_team|qateam)
                        print_info "QA Team mode selected"
                        echo "Use: $0 --clone to setup QA environment"
                        ;;
                    manager|mgr)
                        print_info "Manager mode selected"
                        echo "Use: $0 --clone-release to setup release"
                        ;;
                    *)
                        print_error "Invalid role. Please choose: developer, QA_team, or Manager"
                        exit 1
                        ;;
                esac
                ;;
        esac
        exit 0
    fi

    # Handle help options
    case "$1" in
        --help|--help-developer)
            developer_usage
            ;;
        --help-qa)
            qa_usage
            ;;
        --help-manager)
            manager_usage
            ;;
        --create|--delete|--commit|--push-to-qa|--list-branches|--auto-setup)
            developer_branch_manager "$@"
            ;;
        --clone|--push|--approve|--reject|--test-branch|--list-developer-branches)
            qa_team "$@"
            ;;
        --clone-release)
            manager "$@"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Usage: $0 [developer_options|qa_options|manager_options]"
            echo "Run without arguments for context-aware menu"
            echo "  $0 --help-developer  - Developer commands"
            echo "  $0 --help-qa         - QA Team commands" 
            echo "  $0 --help-manager    - Manager commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
