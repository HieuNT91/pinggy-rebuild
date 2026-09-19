#!/bin/bash

# Check if a username is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1

# Add the new user with a home directory
sudo useradd --create-home --base-dir /home "$USERNAME"

if [ $? -ne 0 ]; then
    echo "Failed to add user $USERNAME"
    exit 1
fi

# Set the password for the new user
echo "$USERNAME:$USERNAME" | sudo chpasswd

if [ $? -ne 0 ]; then
    echo "Failed to set password for user $USERNAME"
    exit 1
fi

# Prompt for changing the password
echo "Now you can change the password for $USERNAME"
sudo passwd "$USERNAME"

if [ $? -ne 0 ]; then
    echo "Failed to change the password for user $USERNAME"
    exit 1
fi

echo "User $USERNAME added successfully."
