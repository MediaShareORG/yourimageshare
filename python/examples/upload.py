#!/usr/bin/env python3
"""Example: upload a local file and print the direct link.

Usage: YIS_API_KEY=... python upload.py photo.jpg
"""
import os
import sys

from yourimageshare import YourImageShare

api_key = os.environ.get("YIS_API_KEY")
path = sys.argv[1] if len(sys.argv) > 1 else None

if not api_key or not path:
    print("Usage: YIS_API_KEY=... python upload.py <file>", file=sys.stderr)
    sys.exit(1)

client = YourImageShare(api_key=api_key)
result = client.upload(path)
print(result.direct)
