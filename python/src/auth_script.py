import json
from google.cloud import datastore
from google_auth_oauthlib.flow import InstalledAppFlow

# Run this script if your refresh token expires or on first use. "credentials.json"
# oauth secret.

SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']

client = datastore.Client()

flow = InstalledAppFlow.from_client_secrets_file(
    'credentials.json', SCOPES)
creds = flow.run_local_server(port=0)
creds_dict = json.loads(creds.to_json())

entity = datastore.Entity(key=client.key("Auth", "creds"))
for key, value in creds_dict.items():
    entity[key] = value

client.put(entity)

print("Saved credentials to datastore")
