import argparse
import base64
import json
import zlib
import requests
from requests.auth import HTTPBasicAuth


def get_headers():
    return {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "*/*"
    }


def submit_query(base_url, query, pacs_name):
    directive = json.loads(query)
    pfdcm_status_url = f'{base_url}/PACS/sync/pypx/'
    headers = {'Content-Type': 'application/json', 'accept': 'application/json'}

    body = {
        "PACSservice": {
            "value": pacs_name
        },
        "listenerService": {
            "value": "default"
        },
        "PACSdirective": {
            "withFeedBack": True,
            "then": "status",
            "thenArgs": '',
            "dblogbasepath": '/home/dicom/log',
            "json_response": False
        }
    }
    body["PACSdirective"].update(directive)
    print(body)

    try:
        response = requests.post(pfdcm_status_url, json=body, headers=headers, timeout=1000)
        d_response = json.loads(response.text)
        if d_response['status']: return json.dumps(d_response['pypx']['data'], indent=2)
        else: raise Exception(d_response['message'])
    except Exception as ex:
        print(ex)

def main():
    parser = argparse.ArgumentParser(description="PACs Query Tool")
    parser.add_argument("--pacs_name", required=True, help="Name of the PACS server")
    parser.add_argument("--query", required=True, help="Query as a JSON string")
    parser.add_argument("--base-url", default="http://ekanite.tch.harvard.edu:32223", help="Base URL of the PACS API")

    args = parser.parse_args()

    try:
        print("Submitting PACS query...")
        result = submit_query(args.base_url, args.query, args.pacs_name)
        print(result)

    except Exception as e:
        logger.error(e)


if __name__ == "__main__":
    main()

