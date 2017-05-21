#!/bin/bash

# This is a very ugly deployment method.
# But hey, it's easy and it works!

pub build
cd build/web
echo "# Hi pirate!" > README.md
git init
git add .
git commit -m "Initial commit"
git branch -m gh-pages
git remote add origin https://github.com/hermanbergwerf/bromium-deploy.git
git push -u origin gh-pages --force
