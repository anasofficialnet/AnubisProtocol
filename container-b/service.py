#!/usr/bin/env python3
"""
Legacy Web Service for Container B (The Inner Sanctum)
Serves the exploit template and sanctum wall image.
Runs on port 8080 — only accessible via network pivot from Container A.
"""

import http.server
import os

PORT = 8080
TEMPLATE_PATH = "/opt/exploit_template.py"
IMAGE_PATH = "/opt/sanctum_wall.png"

HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>The Inner Sanctum — Anubis Protocol</title>
    <style>
        body {{
            background: #050505;
            color: #c9a227;
            font-family: 'Courier New', monospace;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            text-align: center;
        }}
        .container {{
            max-width: 700px;
            padding: 2rem;
        }}
        h1 {{
            font-size: 1.8em;
            margin-bottom: 1rem;
            color: #ffd700;
        }}
        p {{
            color: #8b7d3c;
            line-height: 1.8;
            margin-bottom: 1rem;
        }}
        .glyph {{
            font-size: 3em;
            margin-bottom: 1em;
        }}
        .warning {{
            color: #c9a227;
            border: 1px solid rgba(201, 162, 39, 0.4);
            padding: 1rem;
            margin: 1.5rem 0;
            border-radius: 5px;
            background: rgba(201, 162, 39, 0.05);
            font-style: italic;
        }}
        .wall-container {{
            margin: 2rem 0;
            border: 2px solid rgba(201, 162, 39, 0.2);
            border-radius: 8px;
            overflow: hidden;
            position: relative;
        }}
        .wall-container img {{
            width: 100%;
            display: block;
            opacity: 0.7;
        }}
        .wall-label {{
            font-size: 0.7em;
            color: rgba(201, 162, 39, 0.3);
            margin-top: 0.5rem;
            font-style: italic;
        }}
        .downloads {{
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
            margin-top: 1.5rem;
        }}
        a {{
            color: #ffd700;
            text-decoration: none;
            border: 1px solid rgba(201, 162, 39, 0.3);
            padding: 0.8rem 2rem;
            border-radius: 5px;
            display: inline-block;
            transition: all 0.3s;
        }}
        a:hover {{
            background: rgba(201, 162, 39, 0.1);
            border-color: #ffd700;
        }}
        .info {{
            margin-top: 2rem;
            font-size: 0.75rem;
            color: rgba(201, 162, 39, 0.3);
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="glyph">&#x13080;</div>
        <h1>The Inner Sanctum</h1>
        <p>
            You have reached the final chamber.
            The Anubis Protocol guards the last gate on <strong>port 9999</strong>.
        </p>
        <p>
            The Gateway demands the <strong>True Name</strong> of the Eternal Guardian,
            followed by <strong>proof of your office</strong> in the Order.
        </p>
        <div class="warning">
            "The first seal was entrusted to the Seventh Scribe.
            He buried it within his tomb, hidden among his final words."
        </div>
        <div class="warning">
            "The second seal is carved upon this very wall.
            Gaze upon the ancient stone — read every glyph with care.
            What the wall reveals cannot be spoken by any scribe's quill."
        </div>
        <div class="wall-container">
            <img src="/sanctum_wall.png" alt="Ancient Sanctum Wall">
        </div>
        <p class="wall-label">The Wall of the Inner Sanctum — study it carefully</p>
        <div class="downloads">
            <a href="/download/exploit_template.py">Download exploit_template.py</a>
        </div>
        <div class="info">
            <p>Set the SECRET NAME (both seals), your OFFICE, and the PORT.</p>
            <p>The Final Gateway listens on port 9999</p>
        </div>
    </div>
</body>
</html>"""


class AnubisHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/download/exploit_template.py":
            self._serve_file(TEMPLATE_PATH, "exploit_template.py", "text/x-python")
        elif self.path == "/sanctum_wall.png":
            self._serve_file(IMAGE_PATH, "sanctum_wall.png", "image/png")
        else:
            # Serve the info page
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            page = HTML_PAGE.encode()
            self.send_header("Content-Length", str(len(page)))
            self.end_headers()
            self.wfile.write(page)

    def _serve_file(self, filepath, filename, content_type):
        if os.path.exists(filepath):
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            if content_type != "image/png":
                self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
            with open(filepath, "rb") as f:
                data = f.read()
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"File not found.")

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", PORT), AnubisHandler)
    print(f"[SANCTUM] Inner Sanctum service active on port {PORT}")
    server.serve_forever()
