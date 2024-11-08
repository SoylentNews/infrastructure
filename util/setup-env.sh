# Check the value of ENVIRONMENT and load the appropriate environment file

if [ -f .env ]; then
    echo ".env overriding"
    export $(cat .env | xargs)
fi



declare -A combined_env

# Function to append environment variables from a file to the combined_env associative array
append_env_vars() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Loading from $file"
        while IFS= read -r line || [ -n "$line" ]; do
            # Split the line into key and value
            key=$(echo "$line" | cut -d= -f1)
            value=$(echo "$line" | cut -d= -f2-)
            combined_env["$key"]="$value"
        done < "$file"
    fi
}


# Collect environment variables based on the environment
if [ "$ENVIRONMENT" = "production" ]; then
    append_env_vars "/secrets/production.env"
else
    append_env_vars "/secrets/development.env"
fi

# Collect environment variables from project-specific file
project_name=$(basename "$PWD")
append_env_vars "/secrets/$ENVIRONMENT/$project_name.env"

# Collect environment variables from .env again if it exists
append_env_vars ".env"
for key in "${!combined_env[@]}"; do
    export "$key=${combined_env[$key]}"
done

# Print the loaded environment variables
echo "Loaded environment variables:"
for key in "${!combined_env[@]}"; do
    echo "$key=${combined_env[$key]}"
done

replace_placeholders() {
    local template="$1"
    local output="$2"
    local content=$(cat "$template")

    # Iterate over all keys in the associative array
    for key in "${!combined_env[@]}"; do
        # Replace {{VARIABLE}} with the value of the environment variable using awk
        local value="${combined_env[$key]}"
        content=$(echo "$content" | awk -v k="{{${key}}}" -v v="$value" '{gsub(k, v); print}')
    done

    echo "$content" > "$output"
}

# Check if pre-hook.sh exists in the current directory
if [ -f ./pre-hook.sh ]; then
    echo "Found pre-hook.sh in the current directory. Executing..."
    # Execute pre-hook.sh
    source ./pre-hook.sh
fi

# Iterate over all .template files in the current directory
for template in ./*.template; do
    if [ -f "$template" ]; then
        output="${template%.template}"
        replace_placeholders "$template" "$output"
    fi
done

# Check if post-hook.sh exists in the current directory
if [ -f ./post-hook.sh ]; then
    echo "Found post-hook.sh in the current directory. Executing..."
    # Execute post-hook.sh
    source ./post-hook.sh
fi

