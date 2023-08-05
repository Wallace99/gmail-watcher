import os

from google.auth.transport.requests import Request
from google.cloud import datastore
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

client = datastore.Client()

SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']


def authenticate(force_refresh: bool = False):
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
            print("Creds refreshed.")
        else:
            raise Exception("Refresh token expired! Run auth script to setup creds.")

    if force_refresh:
        creds.refresh(Request())
        print("Creds refreshed.")

    return creds


def watch_labels(creds: Credentials):
    labels_to_watch = os.environ["labels_to_watch"].split(",")
    if len(labels_to_watch) % 2 != 0:
        raise Exception("Malformed label map.")

    label_map = {}
    while labels_to_watch:
        label_map[labels_to_watch.pop(0)] = labels_to_watch.pop(0)
    print(label_map)

    service = build('gmail', 'v1', credentials=creds)
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])
    if not labels:
        print('No labels found.')
    else:
        print('Labels:')
        for label in labels:
            if label['name'].lower().replace(" ", "_") in label_map.keys():
                print(label['name'] + " " + label['id'])
                request = {
                    'labelIds': [label["id"]],
                    'topicName': label_map[label["name"]],
                    'labelFilterBehavior': 'INCLUDE'
                }
                results = service.users().watch(userId='me', body=request).execute()
                print(results)
            else:
                print(f"{label['name'].lower().replace(' ', '_')} not in label map.")


if __name__ == '__main__':
    credentials = authenticate(True if os.environ["force_refresh"].lower() == "true" else False)
    watch_labels(credentials)

