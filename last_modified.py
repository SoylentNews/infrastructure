import os
import glob
import urllib.parse
from datetime import datetime

# Directory containing the folders
DIR = "/opt/loggie/logs/"

# Output HTML file
OUTPUT = "/opt/loggie/logs/index.html"

# HTML template as a string
TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Folder Links</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1 {
            color: #333;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 8px 12px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f4f4f4;
            text-align: left;
        }
        .link {
            font-size: 18px;
            color: #1a73e8;
            text-decoration: none;
        }
        .link:hover {
            text-decoration: underline;
        }
        .date {
            font-size: 14px;
            color: #555;
        }
    </style>
</head>
<body>
    <h1>Folder Links</h1>
    <table>
        <thead>
            <tr>
                <th>Folder</th>
                <th>Date</th>
            </tr>
        </thead>
        <tbody>
            {{links}}
        </tbody>
    </table>
</body>
</html>
"""

def generate_folder_list():
    folders = glob.glob(os.path.join(DIR, '#*'))
    # Exclude the special folder named "#*"
    folders = [folder for folder in folders if os.path.basename(folder) != '#*']
    return folders

def build_folder_date_pairs(folders):
    folder_date_pairs = []
    for folder in folders:
        print(f"Processing folder: {folder}")  # Debug statement
        files = glob.glob(os.path.join(folder, '*'))
        if files:
            latest_file = max(files, key=os.path.getmtime)
            latest_time = os.path.getmtime(latest_file)
            folder_date_pairs.append((latest_time, folder))
    return folder_date_pairs

def sort_folder_date_pairs(folder_date_pairs):
    return sorted(folder_date_pairs, reverse=True, key=lambda x: x[0])

def url_encode(string):
    return urllib.parse.quote(string)

def output_links(sorted_folder_date_pairs):
    links = ""
    for timestamp, folder in sorted_folder_date_pairs:
        print(f"Outputting pair: {timestamp} {folder}")  # Debug statement
        foldername = os.path.basename(folder)
        encoded_foldername = url_encode(foldername)
        human_readable_date = datetime.utcfromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S UTC')
        links += f'<tr><td><a class="link" href="{encoded_foldername}/index.html">{foldername}</a></td><td class="date">{human_readable_date}</td></tr>\n'

    output_content = TEMPLATE.replace("{{links}}", links)

    with open(OUTPUT, 'w') as output_file:
        output_file.write(output_content)

# Main script execution
folders = generate_folder_list()
print(f"Generated folders: {folders}")  # Debug statement
folder_date_pairs = build_folder_date_pairs(folders)
print(f"Folder-date pairs: {folder_date_pairs}")  # Debug statement
sorted_folder_date_pairs = sort_folder_date_pairs(folder_date_pairs)
print(f"Sorted folder-date pairs: {sorted_folder_date_pairs}")  # Debug statement
output_links(sorted_folder_date_pairs)
