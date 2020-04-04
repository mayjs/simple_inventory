from datetime import date
import json
import os
from pathlib import Path
from flask import Flask, request

data_root = Path(os.environ.get("INVENTORY_WEB_DATA_DIR", "./data"))
web_root = os.environ.get("INVENTORY_WEB_URL_ROOT", "/")

app = Flask(__name__)

def mini_html(body):
    return f"""
        <!DOCTYPE html>
        <head>
        </head>
        <body>
            {body}
        </body>
    """

def get_url(*args):
    return web_root + "/".join(map(str, args))


@app.route('/')
def hello_world():
    content = "\n".join(f"<li><a href='{get_url(dir.relative_to(data_root))}'>{dir.relative_to(data_root)}</a></li>" for dir in data_root.iterdir() if dir.is_dir())
    return mini_html(f"<ul>{content}</ul>")

@app.route('/<category>')
def ls(category):
    return f"Opened {data_root/category}"

@app.route('/<category>/<entryid>', methods=['GET', 'POST'])
def edit_entry(category, entryid):
    with open(data_root / category / "format.json") as f:
        format = json.load(f)
    json_path = data_root / category / (entryid+".json")
    header = ""
    if request.method == 'POST':
        out = dict(request.form)
        for field in format:
            if field["type"] == "checkbox":
                out[field["name"]] = field["name"] in out
        with open(json_path, "w") as f:
            json.dump(out, f)
        header = "<h2>Saved!</h2>"


    if json_path.is_file():
        with open(json_path) as f:
            entry_data = json.load(f)
    else:
        entry_data = dict()

    fields = []
    for field in format:
        default = ""
        if field.get("default", False):
            if field["type"] == "date":
                default = date.today().strftime("%Y-%m-%d")
        fields.append(f'<label for="{field["name"]}">{field["hr_name"]}</label>')
        if field["type"] != "checkbox":
            fields.append(f'<input type="{field["type"]}" id="{field["name"]}" name="{field["name"]}" value="{entry_data.get(field["name"], default)}"><br><br>')
        else:
            checked = "checked" if entry_data.get(field["name"], False) else ""
            fields.append(f'<input type="{field["type"]}" id="{field["name"]}" name="{field["name"]}" {checked}><br><br>')
    fields.append('<input type="submit" value="Save">')

    newline = "\n" # "f-string expression part cannot include a backslash"
    return mini_html(f'{header}<form method="POST">{newline.join(fields)}</form>')


if __name__ == '__main__':
    app.run(debug=False)
