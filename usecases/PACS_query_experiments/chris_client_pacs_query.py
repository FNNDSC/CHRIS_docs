# This module requests a query to a remote PACS using CUBE PACS API
# using python-chrisclient

from chrisclient import client
import argparse
import base64
import json
import zlib
import time
import sys
import requests

# Counter to track all HTTP requests
request_count = 0

original_request = requests.Session.request

def counting_request(self, method, url, *args, **kwargs):
    global request_count
    request_count += 1
    print(f"[REQUEST] {method} {url}")
    return original_request(self, method, url, *args, **kwargs)

requests.Session.request = counting_request

class CubePACSClient:
    def __init__(self, url: str, username: str, password: str, timeout: int):
        self.cl = client.Client(url, username, password)
        self.timeout = timeout

    def get_pacs_id(self, pacs_name: str) -> int:
        try:
            search_params = {"identifier": pacs_name}
            pacs_list = self.cl.get_pacs_list(search_params, timeout=self.timeout)
            return pacs_list['data'][0]['id']
        except Exception as ex:
            raise Exception(f"Could not find PACS id: {ex}")

    def post_pacs_query(self, title: str, query: str, pacs_name: str) -> int:
        pacs_id = self.get_pacs_id(pacs_name)
        data = {"title": title, "query": query}
        try:
            response = self.cl.create_pacs_query(pacs_id, data, timeout=self.timeout)
            return response['id']
        except Exception as ex:
            raise Exception(f"Could not post query: {ex}")

    def get_query_results(self, query_id: int, timeout: int = 120, interval: int = 3, max_retries: int = 3) -> str:
        start_time = time.time()
        attempts = 0

        while True:
            try:
                response = self.cl.get_pacs_query_by_id(query_id, timeout=self.timeout)
                status = response['status']
                result = response['result']

                if status == "succeeded":
                    if result:
                        return result
                    raise Exception("[ERROR] 'result' not found despite status succeeded.")

                elapsed = time.time() - start_time
                if elapsed > timeout:
                    raise TimeoutError(f"[TIMEOUT] Query did not succeed in {timeout} seconds. Last status: {status}")

                print(f"[INFO] Current status: {status}. Retrying in {interval}s...")
                time.sleep(interval)

            except Exception as e:
                attempts += 1
                if attempts >= max_retries:
                    raise Exception(f"[ERROR] Failed to fetch query result after {max_retries} retries: {e}")
                print(f"[WARN] Temporary failure: {e}. Retrying ({attempts}/{max_retries}) in {interval}s...")
                time.sleep(interval)

    def decode_and_decompress(self, result: str) -> str:
        decoded = base64.b64decode(result)
        try:
            decompressed = zlib.decompress(decoded)
        except zlib.error:
            try:
                decompressed = zlib.decompress(decoded, wbits=-zlib.MAX_WBITS)
            except zlib.error as e:
                raise RuntimeError(f"Decompression failed: {e}")

        try:
            text = decompressed.decode("utf-8")
            parsed = json.loads(text)
            return json.dumps(parsed, indent=2)
        except (UnicodeDecodeError, json.JSONDecodeError):
            return decompressed.decode("utf-8")

def main():
    parser = argparse.ArgumentParser(description="PACs Query Tool")
    parser.add_argument("--username", required=True, help="Username for PACS authentication")
    parser.add_argument("--password", required=True, help="Password for PACS authentication")
    parser.add_argument("--title", required=True, help="Title for the PACS query")
    parser.add_argument("--query", required=True, help="Query as a JSON string")
    parser.add_argument("--base-url", default="http://ekanite.tch.harvard.edu:32223", help="Base URL of the PACS API")
    parser.add_argument("--pacs-name", required=True, help="Name of PACS identifier")
    parser.add_argument("--timeout", type=int, default=120, help="Timeout (in seconds) to wait for query result")
    parser.add_argument("--interval", type=int, default=3, help="Retry interval (in seconds)")
    parser.add_argument("--max-retries", type=int, default=3, help="Max retries on transient errors")

    args = parser.parse_args()

    try:
        pacs_client = CubePACSClient(args.base_url, args.username, args.password, args.timeout)

        print("[INFO] Submitting or reusing PACS query...")
        query_id = pacs_client.post_pacs_query(args.title, args.query, args.pacs_name)
        print(f"[INFO] Using query ID: {query_id}")

        print("[INFO] Fetching query result...")
        result_encoded = pacs_client.get_query_results(
            query_id,
            timeout=args.timeout,
            interval=args.interval,
            max_retries=args.max_retries
        )

        print("[INFO] Decoding and decompressing result...")
        result = pacs_client.decode_and_decompress(result_encoded)
        print("✅ Query Result (.jq format):")
        print(result)

    except Exception as e:
        print(f"[ERROR] {e}")
        sys.exit(1)
    print(f"📡 Total network requests made: {request_count}")


if __name__ == "__main__":
    main()

