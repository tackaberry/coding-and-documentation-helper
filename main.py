import requests
import os
import json
import hashlib
from dotenv import load_dotenv
import glob

load_dotenv()

BUCKET_NAME = os.environ.get("BUCKET_NAME")
REPO_PATH = os.environ.get("REPO_PATH")
REPO_URL = os.environ.get("REPO_URL")
DOCS_PATH = os.environ.get("DOCS_PATH")

repo_url=REPO_URL
paths = [DOCS_PATH, REPO_PATH]
base_url = {
    "repo": f"{repo_url}/tree/main",
    "docs": f"http://localhost:8000/docs"
}

exts = ['yaml', 'yml', 'md', 'pdf']
mime_types = {
    'yaml': 'text/plain',
    'yml': 'text/plain',
    'md': 'text/plain',
    'pdf': 'application/pdf'
}

rows=[]
for path in paths:
    for ext in exts: 
        files = glob.glob(f"./{path}/**/*.{ext}", recursive=True)
        for file_path in files:
            file_path = file_path.replace(f'./{path}', '')
            filename = os.path.basename(file_path)
            rows.append({
                "name": filename,
                "uri": f"gs://{BUCKET_NAME}/{path}{file_path}",
                "url": f"{base_url[path]}{file_path}",
                "path": file_path,
                "type": ext,
                "mime_type": mime_types[ext],
                "language": "en",
                "tags": []
            })
    
lines = []
for row in rows:
    key = hashlib.md5(row['path'].encode('utf-8')).hexdigest()

    jsonData = {
            "title": row['name'],
            "path": row['path'],      
            "type": row['type'],
            "mime_type": row['mime_type'],
            "url": row['url'],
            "language": row['language'],
            "tags": row['tags'],
        }
    
    line = {
        "id": f"foc-{key}",
        "jsonData": json.dumps(jsonData),
        "content": {
            "mimeType": row['mime_type'],
            "uri": row["uri"],
        }
    }
    lines.append(line)

    with open(f'metadata.jsonl', 'w') as f:
        for line in lines:
            f.write(json.dumps(line) + '\n')
