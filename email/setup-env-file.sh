#!/bin/bash

# Define the template file and the output file
template_file="mailu.env.template"
output_file="${template_file%.template}"

# Use envsubst to replace environment variables in the template file
envsubst < "$template_file" > "$output_file"

echo "Processed template and saved to $output_file"
