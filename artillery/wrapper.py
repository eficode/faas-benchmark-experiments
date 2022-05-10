import json

json_file = "result.txt"
output_json_file = "result.json"

with open(json_file, "r") as _file:
    # read all lines in file into a list
    lines = _file.readlines()
    # new list for parsed JSON objects
    json_lines = []
    # create a list of python dicts that we can then drop as a single JSON structure
    for line in lines:
        # get rid of newlines in the output ...
        if line == "\n":
            continue
        json_lines.append(json.loads(json.loads(line)["body"]))

# write json output to a new file
with open(output_json_file, "w+") as _file:
    _file.write(json.dumps(json_lines, indent=4))


