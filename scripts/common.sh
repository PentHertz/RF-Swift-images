#!/bin/bash

### Part picket from Exegol project with love <3 (https://github.com/ThePorgs/Exegol)

export RED='\033[1;31m'
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export NOCOLOR='\033[0m'

### Echo functions

function colorecho () {
    echo -e "${BLUE}$*${NOCOLOR}"
}

function criticalecho () {
    echo -e "${RED}$*${NOCOLOR}" 2>&1
    exit 1
}

function criticalecho-noexit () {
    echo -e "${RED}$*${NOCOLOR}" 2>&1
}

### </3 Love comes to an end

function goodecho () {
    echo -e "${GREEN}$*${NOCOLOR}" 2>&1
}

function installfromnet() {
    n=0
    until [ "$n" -ge 5 ]
    do
        colorecho "[Internet][Download] Try number: $n"
        $* && break 
        n=$((n+1)) 
        sleep 15
    done
}

function install_dependencies() {
    local dependencies=$1
    goodecho "[+] Installing dependencies: ${dependencies}"
    installfromnet "apt-fast install -y ${dependencies}"
}

function grclone_and_build() {
    local repo_url=$1
    local repo_subdir=$2
    local build_dir="build"
    local branch=""
    shift 2

    # Check if a branch is specified (e.g., -b branch_name)
    if [[ $1 == "-b" ]]; then
        branch=$2
        shift 2
    fi

    local cmake_args=("$@")  # Capture all remaining arguments as CMake arguments

    # Create the base directory if it doesn't exist
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot || exit

    # If no subdirectory is provided, use the repository name as the build directory
    if [ -z "$repo_subdir" ]; then
        repo_subdir=$(basename "$repo_url" .git)
    fi

    # Clone the repository and switch to the specified branch if provided
    cmake_clone_and_build "$repo_url" "$repo_subdir/$build_dir" "$branch" "" "-DCMAKE_INSTALL_PREFIX=/usr" "${cmake_args[@]}"
}

function gitinstall() {
    # Extract the repository URL from the argument
    repo_url="$1"
    method="$2"
    branch="$3"
    
    # Extract the repository name (last part of the URL without .git)
    repo_name=$(basename "$repo_url" .git)

    # Check if the repository already exists in the current directory
    if [ -d "$repo_name" ]; then
        colorecho "Repository '$repo_name' already exists. Pulling latest changes..."
        cd "$repo_name" || exit
        installfromnet "git pull"
        if [ $? -eq 0 ]; then
            goodecho "Repository '$repo_name' updated successfully."
        else
            criticalecho-noexit "Failed to update the repository."
        fi
        cd ..
    else
        # Clone the repository with the specified branch if provided
        if [ -n "$branch" ]; then
            installfromnet "git clone -b $branch $repo_url"
        else
            installfromnet "git clone $repo_url"
        fi

        # If the clone was successful, write the name and path to the file
        if [ $? -eq 0 ]; then
            # Ensure the directory /var/lib/db/ exists, create if not
            if [ ! -d "/var/lib/db/" ]; then
                sudo mkdir -p /var/lib/db/
            fi
            
            # Get the absolute path of the repository
            repo_abs_path="$(pwd)/$repo_name"
            cd $repo_name
            git submodule update --init --recursive
            cd ..

            # Append the repository name, absolute path, and method to the file
            echo "$repo_name:$repo_abs_path:$method" | sudo tee -a /var/lib/db/rfswift_github.lst > /dev/null

            colorecho "Repository '$repo_name' cloned successfully."
            colorecho "Added '$repo_name $repo_abs_path' to /var/lib/db/rfswift_github.lst"
        else
            criticalecho "Failed to clone the repository."
        fi
    fi
}

function cmake_clone_and_build() {
    local repo_url=$1
    local build_dir=$2
    local branch=$3  # This can be empty if no branch is specified
    local reset_commit=$4  # This can be empty if reset is not needed
    shift 4
    local cmake_args=("$@")  # Capture all remaining arguments as CMake arguments

    # Extract the repository name from the URL
    local repo_name=$(basename "$repo_url" .git)

    # Clone the repository if it doesn't exist, otherwise check for updates
    if [ ! -d "$repo_name" ]; then
        goodecho "[+] Cloning ${repo_name}"
        gitinstall "$repo_url" "cmake_clone_and_build" "$branch"
        cd "$repo_name" || exit
        should_build=true
    else
        goodecho "[+] Repository ${repo_name} already exists, checking for updates"
        cd "$repo_name" || exit
        installfromnet "git fetch"
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})

        if [ "$LOCAL" != "$REMOTE" ]; then
            goodecho "[+] Updates found, pulling latest changes"
            installfromnet "git pull"
            should_build=true
        else
            colorecho "[+] No updates found, skipping build and installation"
            should_build=false
        fi
    fi

    # Optionally reset the repository to the specified commit/tag
    if [ -n "$reset_commit" ]; then
        goodecho "[+] Resetting repository to commit/tag '$reset_commit'"
        git reset --hard "$reset_commit"
    else
        goodecho "[+] No reset specified, skipping git reset."
    fi

    # If updates are found or it's the first time cloning, build and install the project
    if [ "$should_build" = true ]; then
        # Create the build directory if it doesn't exist
        if [ ! -d "$build_dir" ]; then
            mkdir -p "$build_dir"
        fi

        # Navigate to the build directory
        cd "$build_dir" || exit

        # Run CMake with additional arguments, build, and install
        goodecho "[+] Building and installing ${repo_name}"
        cmake "${cmake_args[@]}" ../
        make -j$(nproc)
        sudo make install

        # Clean up the build directory if needed
        cd ..
        rm -rf "$build_dir"
    fi

    # Return to the original directory
    cd ..
}