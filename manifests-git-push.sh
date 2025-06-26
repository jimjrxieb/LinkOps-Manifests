#!/bin/bash

# Usage: ./gitpush.sh "Your commit message"

if [ -z "$1" ]; then
  echo "❌ Please provide a commit message."
  echo "Usage: ./gitpush.sh \"Your message here\""
  exit 1
fi

git add .
git commit -m "$1"
git push

echo "✅ Pushed with message: $1"


