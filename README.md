# Coding and Documentation Agent

This repo contains a compiles code and documentation from a given repo and stores the metadata in a BigQuery table.  The app also creates a datastore that can be used to search the documentation.  The app also creates a web client that can be used to search the documentation.  

You can use the Agent Builder interface to create the rest of the agent. 

### Help

The following are the available commands in the Makefile.  To run a command, type `make <command>`.  For example, to run the web server, type `make web`.

```
  help                 Show this help.
  run                  Run the search scraping app.
  index                Copy the index example file and search and replace client id, agent and project.
  req                  Make requirements.
  web                  Launch an http server.
  clone                Clone the repo.
  clean                Clean up.
  mb                   Make search bucket.
  sync                 Synce repo and docs to bucket.
  loadmeta             Upload metadata.jsonl file to bucket
  loadbq               Load metadato into BigQuery.
  datastore            Create the datastore.
  delete_datastore     Delete the datastore.
  faq_mb               Make search bucket.
  faq_cp               Copy FAQ to bucket.
  faq_datastore        Create the datastore.
```

### Authenticate
```bash

# the following command will set env vars from your .env file
. .env

gcloud auth login
gcloud auth application-default login
gcloud config set project ${PROJECT}

```

### Set up python environment
```bash
python -m venv env
source env/bin/activate
pip install -r requirements.txt
```

### Set up the .env file

Copy from the example and make the necessary changes. 

### Create datastore

1. Clone the repo.  Then create a directory for documentation
```bash
make clone
mkdir docs
```

2. Run the following commands to create the bucket and sync the content to the bucket
```bash
make mb
make sync
```

3. Run the following commands to create the datastore
```bash
make run
make loadmeta
make loadbq
make v=1 datastore

```

### Create FAQ datastore

1. Copy the example FAQ file to the correct location and make changes as needed. 
```bash
cp FAQ.example.csv FAQ.csv
```

2. Run the following commands to create the bucket
```bash
make mb
```

3. Run the following commands to create the datastore.
```bash
make faq_cp
make v=1 faq_datastore

```

### Create web client

1. Create oauth client.  Set the authorized javascript origins to `http://localhost:8000`.

2. Copy the client id and agent id to the `.env` file.

3. Run the following commands to create the `index.html` file. Run `make index`. 

4. Run the following commands to start the web server. Run `make web`.