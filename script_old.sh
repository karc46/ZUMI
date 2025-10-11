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
# Git Branch Manager (Developer Function)
# ──────────────────────────────────────────────
developer_branch_manager() {
    local action=""
    local branch_name=""
    local switch_branch=""
    local commit_message=""
    local file_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --create)
                action="create"
                branch_name="$2"
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
                branch_name="$2"
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
    esac
}

developer_usage() {
    echo "Developer Usage:"
    echo "  $0 --create <branch_name>"
    echo "  $0 --delete <branch_name> [--switch <other_branch>]"
    echo "  $0 --commit <file_path> \"<commit_message>\""
    echo "  $0 --push-to-qa <branch_name>"
    echo
    echo "Examples:"
    echo "  $0 --create Developer/karthi"
    echo "  $0 --delete Developer/karthi --switch main"
    echo "  $0 --commit \"bluetooth\" \"Added bluetooth source code\""
    echo "  $0 --push-to-qa Developer/karthi"
}

create_branch() {
    local branch_name="$1"
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
    
    print_info "Pushing branch '$current_branch' to origin..."
    git push -u origin "$current_branch" || {
        print_error "Failed to push branch '$current_branch'"
        return 1
    }
    
    print_success "Branch '$current_branch' pushed to origin"
    print_info "Data copied to QA team for testing"
}

# ──────────────────────────────────────────────
# QA Team Functions
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
    esac
}

qa_usage() {
    echo "QA Team Usage:"
    echo "  $0 --clone"
    echo "  $0 --commit <file_path> \"<commit_message>\""
    echo "  $0 --push <branch_name>"
    echo "  $0 --approve <branch_name>"
    echo "  $0 --reject <branch_name>"
    echo
    echo "Examples:"
    echo "  $0 --clone"
    echo "  $0 --commit \"bluetooth\" \"Added bluetooth test cases\""
    echo "  $0 --push QA/paul"
    echo "  $0 --approve Developer/karthi"
    echo "  $0 --reject Developer/karthi"
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

qa_approve() {
    local branch_name="$1"
    print_success "✅ Branch $branch_name APPROVED for release"
    print_info "Sending to F_Release..."
    # In a real scenario, this would trigger a merge to F_Release
    print_info "Simulating: git checkout F_Release && git merge $branch_name"
}

qa_reject() {
    local branch_name="$1"
    print_error "❌ Branch $branch_name REJECTED"
    print_info "Sending back for Bug_Fix..."
    # In a real scenario, this would create a bugfix branch
    print_info "Simulating: git checkout -b bugfix/$branch_name-from-qa"
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
# Main Script
# ──────────────────────────────────────────────
main() {
    # If no arguments provided, ask for role
    if [[ $# -eq 0 ]]; then
        echo "Are you developer/QA_team/Manager? "
        read -p "Enter your role: " user_role
        case "${user_role,,}" in
            developer|dev)
                print_info "Developer mode selected"
                echo "Use: $0 --help-developer for usage"
                ;;
            qa|qa_team|qateam)
                print_info "QA Team mode selected"
                echo "Use: $0 --help-qa for usage"
                ;;
            manager|mgr)
                print_info "Manager mode selected"
                echo "Use: $0 --help-manager for usage"
                ;;
            *)
                print_error "Invalid role. Please choose: developer, QA_team, or Manager"
                exit 1
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
        --create|--delete|--commit|--push-to-qa)
            developer_branch_manager "$@"
            ;;
        --clone|--push|--approve|--reject)
            qa_team "$@"
            ;;
        --clone-release)
            manager "$@"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Usage: $0 [developer_options|qa_options|manager_options]"
            echo "Run without arguments for interactive mode or use:"
            echo "  $0 --help-developer  - Developer commands"
            echo "  $0 --help-qa         - QA Team commands" 
            echo "  $0 --help-manager    - Manager commands"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
