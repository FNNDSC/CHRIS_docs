import argparse
import base64
import json
import zlib
import requests
from requests.auth import HTTPBasicAuth

# Counter to track all HTTP requests
request_count = 0

original_request = requests.Session.request

def counting_request(self, method, url, *args, **kwargs):
    global request_count
    request_count += 1
    print(f"[REQUEST] {method} {url}")
    return original_request(self, method, url, *args, **kwargs)

requests.Session.request = counting_request

def get_headers():
    return {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "*/*"
    }
    
def find_pacs_id_by_name(base_url: str, auth: HTTPBasicAuth, pacs_name: str) ->int:
    url = f"{base_url}/api/v1/pacs/search/?identifier={pacs_name}"
    response = requests.get(url, auth=auth)
    response.raise_for_status()
    
    items = response.json().get("collection", {}).get("items", [])
    for item in items:
        for field in item.get("data", []):
            if field.get("name") == "id":
                return field.get("value")
    raise Exception("[ERROR] No PACS ID found in response.")
    


def submit_query(base_url, auth, title, query_str, pacs_name):
    pacs_id = find_pacs_id_by_name(base_url, auth, pacs_name)
    url = f"{base_url}/api/v1/pacs/{pacs_id}/queries/"
    data = {
        "title": title,
        "query": query_str
    }

    response = requests.post(url, data=data, headers=get_headers(), auth=auth)
    if response.status_code == 400:
        error_msg = response.json().get("collection", {}).get("error", {}).get("message", "")
        if "already registered" in error_msg:
            print(f"[INFO] Query title '{title}' already registered. Searching existing queries...")
            return find_query_id_by_title(base_url, auth, title, pacs_id)
        else:
            raise Exception(f"[ERROR] 400 Bad Request: {error_msg}")

    response.raise_for_status()
    return extract_id_from_items(response.json())


def find_query_id_by_title(base_url, auth, title, pacs_id):
    url = f"{base_url}/api/v1/pacs/{pacs_id}/queries/"
    response = requests.get(url, auth=auth)
    response.raise_for_status()

    items = response.json().get("collection", {}).get("items", [])
    for item in items:
        data_fields = item.get("data", [])
        title_field = next((f for f in data_fields if f["name"] == "title" and f["value"] == title), None)
        if title_field:
            id_field = next((f for f in data_fields if f["name"] == "id"), None)
            if id_field:
                return id_field["value"]
    raise Exception(f"[ERROR] Query with title '{title}' not found.")


def extract_id_from_items(json_response):
    items = json_response.get("collection", {}).get("items", [])
    for item in items:
        for field in item.get("data", []):
            if field.get("name") == "id":
                return field.get("value")
    raise Exception("[ERROR] No query ID found in response.")


import time

def fetch_query_result(base_url, auth, query_id, timeout=60, interval=3):
    url = f"{base_url}/api/v1/pacs/queries/{query_id}/"
    start_time = time.time()

    while True:
        response = requests.get(url, auth=auth)
        response.raise_for_status()

        items = response.json().get("collection", {}).get("items", [])
        status = None
        result = None

        for item in items:
            for field in item.get("data", []):
                if field.get("name") == "status":
                    status = field.get("value")
                elif field.get("name") == "result":
                    result = field.get("value")

        if status == "succeeded":
            if result is not None:
                return result
            else:
                raise Exception("[ERROR] 'result' not found despite status succeeded.")

        elapsed = time.time() - start_time
        if elapsed > timeout:
            raise TimeoutError(f"Timeout waiting for query to succeed. Last status: {status}")

        print(f"[INFO] Current status: {status}. Retrying in {interval}s...")
        time.sleep(interval)



def decode_and_decompress(encoded_str):
    decoded = base64.b64decode(encoded_str)
    try:
        # Try standard zlib decompress
        decompressed = zlib.decompress(decoded)
    except zlib.error:
        try:
            # Fallback to raw deflate
            decompressed = zlib.decompress(decoded, wbits=-zlib.MAX_WBITS)
        except zlib.error as e:
            raise RuntimeError(f"Decompression failed: {e}")

    try:
        # Decode bytes to UTF-8 string
        text = decompressed.decode("utf-8")
        # Try to load and pretty-print JSON
        parsed = json.loads(text)
        return json.dumps(parsed, indent=2)
    except (UnicodeDecodeError, json.JSONDecodeError):
        # Return raw string if not valid JSON
        return decompressed.decode("utf-8")


def main():
    parser = argparse.ArgumentParser(description="PACs Query Tool")
    parser.add_argument("--username", required=True, help="Username for PACS authentication")
    parser.add_argument("--password", required=True, help="Password for PACS authentication")
    parser.add_argument("--title", required=True, help="Title for the PACS query")
    parser.add_argument("--query", required=True, help="Query as a JSON string")
    parser.add_argument("--base-url", default="http://ekanite.tch.harvard.edu:32223", help="Base URL of the PACS API")
    parser.add_argument("--pacs-name", required=True, help="PACS identifier in CUBE")

    args = parser.parse_args()
    auth = HTTPBasicAuth(args.username, args.password)

    try:
        print("[INFO] Submitting or reusing PACS query...")
        query_id = submit_query(args.base_url, auth, args.title, args.query, args.pacs_name)
        print(f"[INFO] Using query ID: {query_id}")

        print("[INFO] Fetching query result...")
        result_encoded = fetch_query_result(args.base_url, auth, query_id)

        print("[INFO] Decoding and decompressing result...")
        result = decode_and_decompress(result_encoded)
        print("✅ Query Result (.jq format):")
        print(result)

    except Exception as e:
        print(e)
    print(f"📡 Total network requests made: {request_count}")


if __name__ == "__main__":
    main()


