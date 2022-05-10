"""
Methods to be used for wrapping around the artillery cli
"""
import json
import shlex
from subprocess import run, PIPE, CompletedProcess, CalledProcessError


def shell(cmd: str, context: str = None, env: dict = None) -> CompletedProcess:
    """
    cmd: the shell command to run
    context: path to run command at, defaults to current directory
    env: dict of environment variables to inject in the subprocess

    run a shell command in a subprocess
    """

    # use shlex.split to split command string on spaces to a list of strings
    cmd_list = shlex.split(cmd)

    try:
        # create the process, pipe stdout/stderr, output stdout/stderr as strings
        # add 'check=True' to throw an exception on a non-zero exit code
        if context is None:
            proc = run(cmd_list, env=env, stdout=PIPE, text=True, check=False)
        else:
            proc = run(cmd_list, env=env, stdout=PIPE, cwd=context, text=True, check=False)
    except (OSError, ValueError, CalledProcessError) as err:
        print("---")
        print(f"ERROR: Encountered an error executing the shell command: {cmd}")
        print("---")
        raise err

    # return the completed process
    return proc


def parse_result_txt_json_file(filename: str) -> list:
    """
    read a messy stdout file from artillery logs and parse to a python dict
    """
    # open file as read only
    with open(filename, "r", encoding="utf-8") as _file:
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

    return json_lines


def write_parsed_json_to_file(json_list: list, output_filename: str) -> None:
    """
    write json output to a new file, allow to create the file if not exists
    will overwrite existing file with that filename
    """
    with open(output_filename, "w+", encoding="utf-8") as _file:
        _file.write(json.dumps(json_list, indent=4))


def write_subprocess_stdout_to_file(proc: CompletedProcess, filename: str) -> None:
    """
    Write stdout of a completed process to a file
    """
    with open(filename, "w+", encoding="utf-8") as _file:
        _file.write(proc.stdout)


def run_artillery_script(script_path: str, report_path: str, stdout_filename: str = None) -> None:
    """
    script_path: path to artillery .yaml script file to run
    report_path: path to output artillery report .json file
    stdout_filename: optional path to write stdout to specified filename
        this is useful for saving response bodies logged to stdout

    will run artillery using the cli as a subprcess
    """

    # build the shell command to run
    artillery_cmd = f"artillery run --quiet {script_path} --output {report_path}"

    print("Running artillery cli using the following shell command: ")
    print(artillery_cmd)
    print("Starting artillery ...")

    # create the shell process
    # the program will wait here for the shell subprocess to finish
    art_proc = shell(artillery_cmd)

    # check if artillery exited succesfully
    if art_proc.returncode == 0:
        print("Done running artillery")
        if stdout_filename:
            write_subprocess_stdout_to_file(art_proc, stdout_filename)
    else:
        print("ERROR: something went wrong running artillery, dumping stdout and stderr")
        print(f"artillery return code: {art_proc.returncode}")
        print("stdout")
        print(art_proc.stdout)
        print("stderr")
        print(art_proc.stderr)
        print("--- end of artillery error output ---")


def generate_artillery_report(input_file: str, output_file: str) -> None:
    """
    input_file: artillery .json report file
    output_file: filename for the .html report file to generate

    Uses the artillery cli to generate a html report from a completed artillery .json report
    """
    generate_report_cmd = f"artillery report {input_file} --output {output_file}"

    print("Running artillery report with the following shell command:")
    print(generate_report_cmd)
    print("Generating artillery report ...")

    generate_proc = shell(generate_report_cmd)

    if generate_proc.returncode == 0:
        print("Successfully generated report.")
    else:
        print("ERROR: artillery report did not exit successfully.")
        print(f"artillery return code: {generate_report_cmd.returncode}")
        print("stdout")
        print(generate_report_cmd.stdout)
        print("stderr")
        print(generate_report_cmd.stderr)
        print("--- end of artillery error output ---")


if __name__ == "__main__":
    """
    example useage.

    this code is only executed when invoking this file directly, eg:$ python wrapper.py
    """
    artillery_script = "benchmark.yaml"
    report_filename = "report.json"
    json_file = "result.txt"
    output_json_file = "result.json"
    html_report_filename = "report.html"

    # run the artillery script, will produce the report.json and all json bodies as result.txt
    run_artillery_script(artillery_script, report_filename, json_file)

    # parse result.txt to a valid JSON list and save to result.json
    parsed_json = parse_result_txt_json_file(json_file)
    write_parsed_json_to_file(parsed_json, output_json_file)

    # parse the generated report.json to a visual html report, and save to a file
    generate_artillery_report(report_filename, html_report_filename)
