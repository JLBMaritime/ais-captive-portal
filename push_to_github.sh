#!/bin/bash

# Script to push the JLBMaritime-AIS Captive Portal to GitHub
# This script automates the process of pushing the code to GitHub

# Exit on error
set -e

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install git first."
    echo "Run: sudo apt-get update && sudo apt-get install -y git"
    exit 1
fi

# Get GitHub username and repository name
read -p "Enter your GitHub username: " USERNAME
read -p "Enter repository name [ais-captive-portal]: " REPO_NAME
REPO_NAME=${REPO_NAME:-ais-captive-portal}

# Configure Git if not already configured
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter your name for Git commits: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi

if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter your email for Git commits: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi

# Initialize git repository if not already initialized
if [ ! -d .git ]; then
    echo "Initializing Git repository..."
    git init
fi

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "Creating .gitignore file..."
    cat > .gitignore << EOF
*.log
*.tmp
.DS_Store
*~
EOF
fi

# Check if there are changes to commit
if [ -n "$(git status --porcelain)" ]; then
    # Add all files to Git
    echo "Adding files to Git..."
    git add .

    # Commit changes
    echo "Committing changes..."
    git commit -m "JLBMaritime-AIS Captive Portal"
fi

# Check if remote origin exists
if ! git remote | grep -q "^origin$"; then
    echo "Adding remote origin..."
    git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"
else
    # Update the remote URL if it exists
    echo "Updating remote origin URL..."
    git remote set-url origin "https://github.com/$USERNAME/$REPO_NAME.git"
fi

# Determine the current branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "HEAD" ]; then
    # If in detached HEAD state, use main as the branch
    BRANCH="main"
fi

echo ""
echo "Ready to push to GitHub!"
echo "Repository: https://github.com/$USERNAME/$REPO_NAME"
echo "Branch: $BRANCH"
echo ""

read -p "Make sure your GitHub repository exists. Ready to push? (y/n): " CONFIRM
if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
    echo "Pushing to GitHub..."
    git push -u origin $BRANCH
    
    echo ""
    echo "Success! Your code has been pushed to GitHub."
    echo "Repository URL: https://github.com/$USERNAME/$REPO_NAME"
    echo ""
    
    # Update the GitHub URL in install.sh
    if grep -q "GITHUB_REPO=" install.sh; then
        sed -i "s|GITHUB_REPO=.*|GITHUB_REPO=\"https://github.com/$USERNAME/$REPO_NAME.git\"|" install.sh
        echo "Updated GitHub repository URL in install.sh"
        
        # Commit and push the update
        git add install.sh
        git commit -m "Update GitHub repository URL in install.sh"
        git push
    fi
else
    echo "Push canceled."
fi

exit 0
