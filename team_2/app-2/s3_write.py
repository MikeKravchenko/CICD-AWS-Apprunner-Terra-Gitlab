import os
import boto3
from http.server import BaseHTTPRequestHandler, HTTPServer

NAME = os.environ["NAME"]
PORT = int(os.environ["PORT"])

# By convention
BUCKET_NAME = f"{NAME}-data-behavox-platform-sre"

s3 = boto3.client("s3")

dummy_file_content = f"Hello from {NAME}!".encode("utf-8")

class RequestHandler(BaseHTTPRequestHandler):
    def _upload_file(self):
        s3.put_object(Bucket=BUCKET_NAME, Key="/dummy.txt", Body=dummy_file_content)

    def _send_response(self, content, status_code):
        self.send_response(status_code)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(content.encode())

    def _process_response(self):
        try:
            self._upload_file()
            self._send_response(f"Dummy file uploaded to {BUCKET_NAME}/dummy.txt", 200)
        except Exception as e:
            self._send_response(str(e), 500)

    def do_GET(self):
        self._process_response()

    def do_HEAD(self):
        self._process_response()

def run(server_class=HTTPServer, handler_class=RequestHandler, port=PORT):
    server_address = ("", port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting server on port {port}")
    httpd.serve_forever()


if __name__ == "__main__":
    run()
