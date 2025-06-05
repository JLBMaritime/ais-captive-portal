# GitHub Push Instructions

Follow these steps to push the JLBMaritime-AIS Captive Portal solution to GitHub:

## Step 1: Initialize Git Repository (if not already done)

```bash
# Navigate to your project directory
cd /path/to/captive-portal

# Initialize git repository
git init
```

## Step 2: Configure Git (if not already done)

```bash
# Set your username and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Step 3: Create .gitignore File

```bash
# Create a .gitignore file
cat > .gitignore << EOF
*.log
*.tmp
.DS_Store
*~
EOF
```

## Step 4: Add Files to Git

```bash
# Add all files to git
git add .
```

## Step 5: Commit the Changes

```bash
# Commit your changes
git commit -m "Initial commit of JLBMaritime-AIS Captive Portal"
```

## Step 6: Create GitHub Repository

1. Go to https://github.com/new
2. Enter repository name (e.g., "ais-captive-portal")
3. Choose public or private repository
4. Do NOT initialize with README, .gitignore, or license
5. Click "Create repository"

## Step 7: Link Local Repository to GitHub

```bash
# Add GitHub repository as remote origin (replace USERNAME and REPO_NAME)
git remote add origin https://github.com/USERNAME/REPO_NAME.git
```

## Step 8: Push to GitHub

```bash
# Push your code to GitHub
git push -u origin main
```

If you're using an older version of Git that still uses "master" as the default branch name:

```bash
git push -u origin master
```

## Step 9: Verify

1. Refresh your GitHub repository page
2. Confirm that all files have been pushed successfully

## One-Command Push (for future updates)

After the initial setup, you can use this single command to add, commit, and push changes:

```bash
git add . && git commit -m "Update captive portal files" && git push
```

## Using the setup_github.sh Script

Alternatively, you can use the provided `setup_github.sh` script to help set up your GitHub repository:

```bash
# Make the script executable if it's not already
chmod +x setup_github.sh

# Run the script
./setup_github.sh
```

The script will guide you through the process and provide instructions for completing the GitHub setup.
