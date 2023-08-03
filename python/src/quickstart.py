from __future__ import print_function

import yaml
from google.auth.transport.requests import Request
from google.cloud import datastore
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

client = datastore.Client()

# If modifying these scopes, delete the file token.json.
SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']


def authenticate():
    creds = None
    query = client.query(kind="Auth")
    results = list(query.fetch())

    if results:
        result = results[0]
        creds_dict = {}
        for key, value in result.items():
            creds_dict[key] = value
        creds = Credentials.from_authorized_user_info(info=creds_dict, scopes=SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            raise Exception("Refresh token expired! Run auth script to setup creds.")

    return creds


def watch_labels(creds):
    with open('conf.yaml', 'r') as file:
        labels_to_watch = yaml.safe_load(file)

    service = build('gmail', 'v1', credentials=creds)
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])
    if not labels:
        print('No labels found.')
    else:
        print('Labels:')
        for label in labels:
            if label['name'] in labels_to_watch.keys():
                print(label['name'] + " " + label['id'])
                print(labels_to_watch[label["name"]])
                request = {
                    'labelIds': [label["id"]],
                    'topicName': labels_to_watch[label["name"]],
                    'labelFilterBehavior': 'INCLUDE'
                }
                results = service.users().watch(userId='me', body=request).execute()
                print(results)

        # results = service.users().watch(userId='me', body=request).execute()
    #     results = service.users().messages().list(
    #         userId='me',
    #         q='newer_than:2d',
    #         labelIds=['Label_2843525942517274814'],
    #         includeSpamTrash=False
    #     ).execute()
    #     print(results)
    #
    # except HttpError as error:
    #     # TODO(developer) - Handle errors from gmail API.
    #     print(f'An error occurred: {error}')


if __name__ == '__main__':
    credentials = authenticate()
    watch_labels(credentials)
