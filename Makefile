include .env

project = $(PROJECT)
bucket = $(BUCKET_NAME)
repo_path = $(REPO_PATH)
repo_url = $(REPO_URL)
docs_path = $(DOCS_PATH)
datastore = $(DATASTORE)-$(v)
dataset = $(DATASET)
table = $(TABLE)
dataset_table = $(dataset).$(table)

agent = $(AGENT)
client_id = $(CLIENT_ID)

datastore_faq = $(DATASTORE)-faq-$(v)
bucket_faq = $(BUCKET_NAME)-faq

token := $(shell gcloud auth print-access-token)

help: ## Show this help.
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-20s\033[0m %s\n", $$1, $$2}'

run: ## Run the search scraping app.
	@echo "Running..."
	@env/bin/python main.py

index: ## Copy the index example file and search and replace client id, agent and project.
	@echo "Copying index..."
	@cp index.example.html index.html
	@sed -i 's/CLIENT_ID/$(client_id)/g' index.html
	@sed -i 's/PROJECT/$(project)/g' index.html
	@sed -i 's/AGENT/$(agent)/g' index.html

req: ## Make requirements.
	@echo "Making requirements..."
	@env/bin/python -m pip freeze > requirements.txt

web: ## Launch an http server.
	@echo "Launching server..."
	@env/bin/python -m http.server

clone: ## Clone the repo.
	@echo "Cloning..."
	@git clone $(repo_url) $(repo_path)

clean: ## Clean up.
	@rm -rf __pycache__
	@rm -rf env

mb: ## Make search bucket.
	@echo "Making bucket..."
	@gsutil mb gs://$(bucket)

sync: ## Synce repo and docs to bucket.
	gsutil -m rsync -r $(repo_path)/  gs://$(bucket)/$(repo_path)/
	gsutil -m rsync -r $(docs_path)/  gs://$(bucket)/$(docs_path)/

loadmeta: ## Upload metadata.jsonl file to bucket
	gsutil cp metadata.jsonl gs://$(bucket)/metadata.jsonl

loadbq: ## Load metadato into BigQuery.
	@echo "Loading BigQuery for benefits..."
	bq rm -f --table $(dataset_table)
	bq load --source_format=NEWLINE_DELIMITED_JSON $(dataset_table) gs://$(bucket)/metadata.jsonl schema.json

datastore: ## Create the datastore.
	@echo "Creating the datastore..."
	@curl -X POST \
	-H "Authorization: Bearer $(token)" \
	-H "Content-Type: application/json" \
	-H "X-Goog-User-Project: $(project)" \
	"https://discoveryengine.googleapis.com/v1alpha/projects/$(project)/locations/global/collections/default_collection/dataStores?dataStoreId=$(datastore)" \
	-d '{ "displayName": "$(datastore)", "industryVertical": "GENERIC", "solutionTypes": ["SOLUTION_TYPE_CHAT"], "contentConfig": "CONTENT_REQUIRED", "searchTier": "STANDARD", "searchAddOns": ["LLM"] }'
	@ curl -X POST \
	-H "Authorization: Bearer $(token)" \
	-H "Content-Type: application/json" \
	"https://discoveryengine.googleapis.com/v1/projects/$(project)/locations/global/collections/default_collection/dataStores/$(datastore)/branches/0/documents:import" \
	-d '{  "bigquerySource": { "projectId": "$(project)", "datasetId":"$(dataset)", "tableId": "$(table)" } }'

delete_datastore: ## Delete the datastore.
	@echo "Deleting the datastore..."
	@curl -X DELETE \
	-H "Authorization: Bearer $(token)" \
	-H "X-Goog-User-Project: $(project)" \
	"https://discoveryengine.googleapis.com/v1alpha/projects/$(project)/locations/global/dataStores/$(datastore)"

faq_mb: ## Make search bucket.
	@echo "Making bucket..."
	@gsutil mb gs://$(bucket_faq)

faq_cp: ## Copy FAQ to bucket.
	@echo "Copying FAQ to bucket..."
	@gsutil -m cp ./FAQ.csv  gs://$(bucket_faq)/FAQ.csv

faq_datastore: ## Create the datastore.
	@echo "Creating the datastore..."
	@curl -X POST \
	-H "Authorization: Bearer $(token)" \
	-H "Content-Type: application/json" \
	-H "X-Goog-User-Project: $(project)" \
	"https://discoveryengine.googleapis.com/v1alpha/projects/$(project)/locations/global/collections/default_collection/dataStores?dataStoreId=$(datastore_faq)" \
	-d '{ "displayName": "$(datastore_faq)", "industryVertical": "GENERIC", "solutionTypes": [], "searchTier": "STANDARD" }'
	@ curl -X POST \
	-H "Authorization: Bearer $(token)" \
	-H "Content-Type: application/json" \
	"https://discoveryengine.googleapis.com/v1/projects/$(project)/locations/global/collections/default_collection/dataStores/$(datastore_faq)/branches/0/documents:import" \
	-d '{  "gcsSource": { "inputUris": [ "gs://$(bucket_faq)/FAQ.csv" ], "dataSchema": "csv" } }'


faq_delete_datastore: ## Delete the datastore.
	@echo "Deleting the datastore..."
	@curl -X DELETE \
	-H "Authorization: Bearer $(token)" \
	-H "X-Goog-User-Project: $(project)" \
	"https://discoveryengine.googleapis.com/v1alpha/projects/$(project)/locations/global/dataStores/$(datastore_faq)"
