import json
import pathlib
import subprocess
import sys

result = "TestResults.xcresult"
output = pathlib.Path("test-images")
output.mkdir(exist_ok=True)

# Xcode 26 replaced the JSON object API with a direct attachment exporter.
xcode_major = int(subprocess.check_output(["xcodebuild", "-version"], text=True).splitlines()[0].split()[1].split(".")[0])
if xcode_major >= 26:
    subprocess.run(["xcrun", "xcresulttool", "export", "attachments",
                    "--path", result, "--output-path", str(output)], check=True)
    sys.exit(0)

visited = set()

def get(identifier=None):
    args = ["xcrun", "xcresulttool", "get", "--path", result, "--format", "json"]
    if identifier:
        args += ["--id", identifier]
    return json.loads(subprocess.check_output(args))

def walk(value):
    if isinstance(value, list):
        for item in value:
            walk(item)
    elif isinstance(value, dict):
        payload = value.get("payloadRef", {}).get("id", {}).get("_value")
        filename = value.get("filename", {}).get("_value", "")
        if payload and filename.lower().endswith((".png", ".jpg", ".jpeg")):
            target = output / (str(len(list(output.iterdir()))) + "-" + pathlib.Path(filename).name)
            subprocess.run(["xcrun", "xcresulttool", "export", "--path", result,
                            "--id", payload, "--type", "file", "--output-path", str(target)], check=True)
        for key, child in value.items():
            if key in ("testsRef", "summaryRef") and isinstance(child, dict):
                identifier = child.get("id", {}).get("_value")
                if identifier and identifier not in visited:
                    visited.add(identifier)
                    walk(get(identifier))
            else:
                walk(child)

walk(get())
