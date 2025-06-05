#!/bin/bash

# Setup GitHub repository for JLBMaritime-AIS Captive Portal
# This script initializes a Git repository and pushes the code to GitHub

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git not found. Please install git first."
    exit 1
fi

# Prompt for GitHub username and repository name
read -p "GitHub Username: " GITHUB_USERNAME
read -p "GitHub Repository Name [ais-captive-portal]: " GITHUB_REPO_NAME
GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-ais-captive-portal}

# Initialize git repository
git init

# Add all files
git add .

# Commit changes
git commit -m "Initial commit of JLBMaritime-AIS Captive Portal"

# Create .gitignore file
cat > .gitignore <<EOF
*.log
*.tmp
.DS_Store
*~
EOF

# Add and commit .gitignore
git add .gitignore
git commit -m "Add .gitignore file"

# Set the remote repository URL
git remote add origin "https://github.com/$GITHUB_USERNAME/$GITHUB_REPO_NAME.git"

echo ""
echo "Repository has been initialized locally."
echo ""
echo "Next steps:"
echo "1. Create a new repository on GitHub at: https://github.com/new"
echo "   - Repository name: $GITHUB_REPO_NAME"
echo "   - Make it Public (recommended) or Private"
echo "   - Do NOT initialize with README, .gitignore, or license"
echo ""
echo "2. Push the code to GitHub with:"
echo "   git push -u origin main"
echo ""
echo "3. Update the GitHub URL in install.sh if needed:"
echo "   Current URL: https://github.com/jlbmaritime/ais-captive-portal.git"
echo "   New URL: https://github.com/$GITHUB_USERNAME/$GITHUB_REPO_NAME.git"
echo ""
echo "4. Deploy using the instructions in README.md"

exit 0
