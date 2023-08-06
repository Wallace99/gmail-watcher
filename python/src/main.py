import base64
import io
import os
from typing import List, Dict

from google.auth.transport.requests import Request
from google.cloud import datastore
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from google.cloud import storage

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
        print("Forced creds refresh.")

    return creds


def extract_label_map(labels_string: str):
    label_map = {}
    labels_to_process = labels_string.split(",")

    if len(labels_to_process) % 2 != 0:
        raise Exception("Malformed label map.")

    while labels_to_process:
        label_name = labels_to_process.pop(0)
        label_gcs_link = labels_to_process.pop(0)
        label_map[label_name] = label_gcs_link
    return label_map


def get_relevant_label_ids(service, label_map: dict) -> Dict[str, str]:
    """
    Get mapping of label ID to GCS link of where to upload attachments to.
    :param service: Gmail API service.
    :param label_map: Map of label names to GCS links.
    :return: Map of label ID to GCS link.
    """
    results = service.users().labels().list(userId='me').execute()
    labels = results.get('labels', [])

    if not labels:
        print('No labels found.')
        return {}

    output = {}
    for label in labels:
        label_formatted = label['name'].lower().replace(" ", "_")
        if label_formatted in label_map.keys():
            gcs_link = label_map[label_formatted]
            output[label["id"]] = gcs_link

    return output


def process_labels(creds: Credentials, labels_to_process: str = None):
    if not labels_to_process:
        labels_to_process = os.environ["labels_to_process"]
    label_map = extract_label_map(labels_to_process)
    print(label_map)

    service = build('gmail', 'v1', credentials=creds)

    label_ids_to_gcs = get_relevant_label_ids(service, label_map)

    for label_id in label_ids_to_gcs.keys():
        results = service.users().messages().list(userId="me", labelIds=[label_id], q="newer_than:7d",
                                                  maxResults=1).execute()
        process_message_for_label(service, results, label_ids_to_gcs[label_id])


def process_message_for_label(service, label_results: dict, gcs_link: str):
    if len(label_results["messages"]) == 0:
        print("No messages detected for label.")
        return {}

    message_id = label_results["messages"][0]["id"]
    result = service.users().messages().get(userId="me", id=message_id).execute()
    parts = result["payload"]["parts"]

    for i in parts:
        if "attachmentId" in i["body"]:
            attachment_id = i["body"]["attachmentId"]
            mime_type = i["mimeType"]
            filename = i["filename"]

            attachment_data = service.users().messages().attachments().get(
                userId='me',
                messageId=message_id,
                id=attachment_id
            ).execute()

            storage_client = storage.Client()
            bucket = storage_client.bucket(gcs_link)
            blob = bucket.blob(filename)

            # Decode the attachment data (it's base64url-encoded)
            attachment_bytes = base64.urlsafe_b64decode(attachment_data['data'])

            # Upload the attachment to GCS
            blob.upload_from_file(io.BytesIO(attachment_bytes), content_type=mime_type)


if __name__ == '__main__':
    # force_refresh = "false"
    force_refresh = os.environ["force_refresh"].lower()
    credentials = authenticate(True if force_refresh == "true" else False)
    process_labels(credentials)
