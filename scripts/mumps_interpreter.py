#!/usr/bin/env python3
import sys
import re
import json
import os

class UltraMumpsInterpreter:
    def __init__(self, global_file="mumps_globals.json"):
        self.global_file = global_file
        self.globals = self.load_globals()
        self.locals = {}

    def load_globals(self):
        if os.path.exists(self.global_file):
            with open(self.global_file, "r") as f:
                return json.load(f)
        return {}

    def save_globals(self):
        with open(self.global_file, "w") as f:
            json.dump(self.globals, f, indent=2)

    def execute(self, line):
        line = line.strip()
        if not line or line.startswith(";"):
            return

        # Very basic parser for W, S
        if line.startswith("W "):
            content = line[2:]
            # Handle quoted strings and globals
            parts = re.findall(r'"[^"]*"|\^?[A-Z0-9\(\)"]+', content)
            output = ""
            for p in parts:
                if p.startswith('"'):
                    output += p.strip('"')
                elif p.startswith('^'):
                    output += str(self.globals.get(p, "<UNDEFINED>"))
                else:
                    output += str(self.locals.get(p, "<UNDEFINED>"))
            print(output, end="")
            if line.endswith("!"):
                print()
        
        elif line.startswith("S "):
            match = re.match(r"S (\^?[A-Z0-9\(\)]+)=(.*)", line)
            if match:
                var, val = match.groups()
                # Simple value parsing
                if val.startswith('"'):
                    val = val.strip('"')
                
                if var.startswith('^'):
                    self.globals[var] = val
                    self.save_globals()
                else:
                    self.locals[var] = val

    def run_file(self, filename):
        if not os.path.exists(filename):
            print(f"Error: {filename} not found")
            return
        with open(filename, "r") as f:
            for line in f:
                # Handle labels
                if " " in line:
                    self.execute(line.split(" ", 1)[1])
                else:
                    # Pure command line or label
                    pass

if __name__ == "__main__":
    interpreter = UltraMumpsInterpreter()
    if len(sys.argv) > 1:
        interpreter.run_file(sys.argv[1])
    else:
        print("Ultra Chaos MUMPS Interpreter (1966 Edition)")
        while True:
            try:
                line = input("M> ")
                if line.upper() == "HALT" or line.upper() == "H":
                    break
                interpreter.execute(line)
            except EOFError:
                break
            except Exception as e:
                print(f"ERROR: {e}")
 
