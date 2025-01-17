import os
import os.path
import requests
import xmltodict
import sys
import json

# Uses pyQuARC 1.1.5
sys.path.append('lib/pyQuARC.egg')
from pyQuARC import ARC

# The field path has the doctype (e.g. Collection/) as a prefix, this should be removed.
# e.g., Collection/SpatialInfo/VerticalCoordinateSystem/AltitudeSystemDefinition/DistanceUnits returns
# SpatialInfo/VerticalCoordinateSystem/AltitudeSystemDefinition/DistanceUnits
def remove_doctype(field_path):
    pos = field_path.find("/")
    path = field_path
    if (pos != -1):
        path = field_path[pos+1:]
    return path

# Given the specified path and the check being applied, include the check result of the value/message to the "result" dictionary.
# If the check is valid (no errors), just include "OK; "
#
# e.g. check_data = { "valid": false, "value": [ 43 ],
# "message": [ "Warning: The abstract provided may be inadequate based on length." ],
# "remediation": "Provide a more comprehensive description, mimicking a journal abstract that is useful to the science
# community but also approachable for a first time user of the data." }
def assign_results(path, check, check_data, result):
    if "valid" in check_data:
        valid = check_data["valid"]
        # if check is valid, use "OK"
        if valid:
            if result[path] == "":
                result[path] += "OK; "
        else:
            # prior check said this was OK, but this check says not.
            if result[path] == "OK; ":
                result[path] = ""

            # Use the message if we have one.
            if "message" in check_data:
                result[path] = "<b>Errors:</b><ul>"
                for message in check_data["message"]:
                    result[path] += "<li>" + message + "</li> "
                result[path] += "</ul>"
            if "remediation" in check_data:
              result[path] += "<b>Remediation:</b><br>"+check_data["remediation"]

            # Otherwise just mention the check failed.
            else:
                result[path] += check+" failed<br>"

# This just cleans up the result path, it will remove a trailing ; and if the result path's value == "" then will remove it altogher from the
# dictionary, hence all checks passed.
# e.g., result[path] = "OK; " will return "OK"
def trim_result_path(result, path):
    if result[path].endswith("; "):
        result[path] = result[path][:len(result[path])-2]

    if result[path] == "":
        del result[path]

# Main logic that parses through the errors for the specified field path and assigns the results of the checks to the "result" dictionary.
# The "result" dictionary is ["path":"result1;result2;"]
# e.g. see arc_response.json (in this directory) for an example of what errors looks like.
def parse_checks(field_path, errors, result):
    path = remove_doctype(field_path)
    result[path] = ""
    checks = errors[field_path].keys()

    for check in checks:
        check_data = errors[field_path][check]
        assign_results(path, check, check_data, result)

    trim_result_path(result, path)

# Main that calls the ARC library, with the specified metadata file (arg1) and theh specified format (arg2), parses the results and transforms the results
# into something cmr dashboard can use.
if __name__ == "__main__":
    if (len(sys.argv) != 3):
        print("Usage python3 dashboard_checker.py [file] [format]")
        exit()
    file = sys.argv[1]
    format = sys.argv[2]
    result = {}
    arc = ARC(file_path=file, metadata_format=format or ECHO10)
    validation_results = arc.validate()
    arc_errors = arc.errors
    for error in arc_errors:
        errors = error["errors"]
        for field_path in errors.keys():
            parse_checks(field_path, errors, result)
    out = open(file+'.out', 'w')
    out.write(json.dumps(result))
    out.close()

