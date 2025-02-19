#!/bin/bash

# Function to open the file in nvim
open_in_nvim() {
    local secrets_id=$1
    local file_path="$HOME/.microsoft/usersecrets/$secrets_id/secrets.json"

    # Check if the file exists
    if [[ -f "$file_path" ]]; then
        nvim "$file_path"
    else
        echo "File not found: $file_path"
        dotnet user-secrets set "foo" "bar"
        nvim "$file_path"
    fi
}

# Loop through all .csproj files in the current directory
for file in *.csproj; do
    # Check if the file exists and is not a directory
    if [[ -f "$file" ]]; then
        # Extract the UserSecretsId
        result=$(grep -oPm1 '<UserSecretsId>\K.*?(?=</UserSecretsId>)' "$file")

        # If a UserSecretsId is found, open the corresponding file in nvim
        if [[ -n $result ]]; then
            echo "Found UserSecretsId: $result"
            open_in_nvim "$result"
            exit 0
        fi
    fi
done



# If no UserSecretsId was found in any file
echo "No UserSecretsId found in any .csproj file."
