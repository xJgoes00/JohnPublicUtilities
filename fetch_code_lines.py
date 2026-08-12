import json
import os
import sys

# Terminal colors using ANSI escape codes
COLOR_GREEN = "\033[92m"
COLOR_CYAN = "\033[96m"
COLOR_YELLOW = "\033[93m"
COLOR_RED = "\033[91m"
COLOR_RESET = "\033[0m"

# Enable ANSI escape codes on Windows cmd
if os.name == 'nt':
    os.system('')

def print_help():
    help_text = f"""
{COLOR_GREEN}Usage:{COLOR_RESET} python fetch_code_lines.py [input_file] [output_file/directory] [options]

{COLOR_CYAN}Arguments:{COLOR_RESET}
  {COLOR_GREEN}input_file{COLOR_RESET}             Path to the input JSON file containing problems.
                             If not provided, you will be prompted to enter it.
  {COLOR_GREEN}output_file/dir{COLOR_RESET}        Custom path or filename for the output file.
                             Defaults to 'problems_with_code.txt' in the script directory.

{COLOR_CYAN}Options:{COLOR_RESET}
  {COLOR_GREEN}-h, --help{COLOR_RESET}             Show this help message and exit.
  {COLOR_GREEN}--no-location{COLOR_RESET}          Do not print the file location and line numbers for each problem.
  {COLOR_GREEN}--unique{COLOR_RESET}               Only fetch unique problems (removes duplicate messages per file).
"""
    print(help_text)

def main():
    try:
        args = sys.argv[1:]
        
        # Check for help flags
        if '-h' in args or '--help' in args:
            print_help()
            sys.exit(0)
            
        # Check for --no-location flag
        no_location = False
        if '--no-location' in args:
            no_location = True
            args.remove('--no-location')
            
        # Check for --unique flag
        unique_only = False
        if '--unique' in args:
            unique_only = True
            args.remove('--unique')
            
        # Check for any other unrecognized flags
        for arg in args:
            if arg.startswith('-'):
                print(f"{COLOR_RED}Error: Unknown option {arg}{COLOR_RESET}")
                print_help()
                sys.exit(1)
                
        if len(args) > 2:
            print(f"{COLOR_RED}Error: Too many arguments.{COLOR_RESET}")
            print_help()
            sys.exit(1)

        # 1. Resolve input path
        if len(args) >= 1:
            problems_file = args[0]
        else:
            try:
                problems_file = input("Enter path to problems JSON file (default: PROBLEMS.TXT): ").strip()
            except (KeyboardInterrupt, EOFError):
                print(f"\n{COLOR_YELLOW}Operation cancelled.{COLOR_RESET}")
                sys.exit(0)
            if not problems_file:
                problems_file = "PROBLEMS.TXT"

        problems_file = os.path.abspath(problems_file)

        if not os.path.exists(problems_file):
            raise FileNotFoundError(f"Input file not found at: {problems_file}")

        # 2. Resolve output path
        script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
        if len(args) >= 2:
            out_arg = args[1]
            if os.path.isdir(out_arg) or out_arg.endswith(('/', '\\')):
                output_file = os.path.join(out_arg, "problems_with_code.txt")
            else:
                output_file = out_arg
        else:
            output_file = os.path.join(script_dir, "problems_with_code.txt")
            
        output_file = os.path.abspath(output_file)

        # Make sure parent directory of output exists
        out_dir = os.path.dirname(output_file)
        if out_dir and not os.path.exists(out_dir):
            os.makedirs(out_dir, exist_ok=True)

        print(f"Reading problems from: {problems_file}")
        with open(problems_file, 'r', encoding='utf-8') as f:
            problems = json.load(f)

        if unique_only:
            unique_problems = []
            seen_problems = set()
            for prob in problems:
                key = (prob.get('resource'), prob.get('message'))
                if key not in seen_problems:
                    unique_problems.append(prob)
                    seen_problems.add(key)
            problems = unique_problems

        # Cache to avoid re-reading files from disk repeatedly
        file_cache = {}

        def get_file_lines(filepath):
            if filepath in file_cache:
                return file_cache[filepath]
            
            # Clean up URI-like or standard path
            normalized_path = filepath
            if normalized_path.startswith('/'):
                normalized_path = normalized_path[1:]
            normalized_path = os.path.normpath(normalized_path)
            
            if not os.path.exists(normalized_path):
                file_cache[filepath] = None
                return None
                
            try:
                with open(normalized_path, 'r', encoding='utf-8', errors='replace') as f_in:
                    lines = f_in.readlines()
                file_cache[filepath] = lines
                return lines
            except Exception as e_read:
                print(f"{COLOR_YELLOW}Warning: Error reading {normalized_path}: {e_read}{COLOR_RESET}")
                file_cache[filepath] = None
                return None

        # Write/stream directly to the output file
        with open(output_file, 'w', encoding='utf-8') as out_f:
            for i, prob in enumerate(problems, 1):
                resource = prob.get("resource", "")
                message = prob.get("message", "")
                code_type = prob.get("code", "")
                start_line = prob.get("startLineNumber", 1)
                end_line = prob.get("endLineNumber", start_line)
                
                lines = get_file_lines(resource)
                
                out_f.write(f"Problem #{i}: {message} ({code_type})\n")
                
                if not no_location:
                    display_path = resource
                    if display_path.startswith('/'):
                        display_path = display_path[1:]
                    display_path = os.path.normpath(display_path)
                    out_f.write(f"Location: {display_path} (Lines {start_line}-{end_line})\n")
                    
                out_f.write("Code:\n")
                
                if lines:
                    for line_no in range(start_line, end_line + 1):
                        idx = line_no - 1
                        if 0 <= idx < len(lines):
                            line_content = lines[idx].rstrip('\r\n')
                            out_f.write(f"{line_no:4d}: {line_content}\n")
                        else:
                            out_f.write(f"{line_no:4d}: <Line out of bounds>\n")
                else:
                    out_f.write("  <Could not read source file or file does not exist>\n")
                    
                out_f.write("-" * 80 + "\n\n")
            
        print(f"{COLOR_GREEN}Success: Processed {len(problems)} problems.{COLOR_RESET}")
        print(f"Result written to: {output_file}")

    except Exception as e:
        print(f"{COLOR_RED}Error: {e}{COLOR_RESET}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
