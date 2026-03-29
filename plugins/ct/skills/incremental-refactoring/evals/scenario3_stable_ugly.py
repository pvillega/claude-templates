"""Legacy CSV parser - in production since 2019, last modified 2022.
Handles our proprietary CSV format with custom escape sequences.
Tests: 47 passing, 100% coverage on this module.
Touched by: 0 PRs in the last 12 months."""
import re
from datetime import datetime, timedelta


def p(f, d="|", q='"', e="\\"):
    """Parse CSV file with custom delimiters."""
    r = []
    with open(f, "r") as fh:
        for ln in fh:
            ln = ln.rstrip("\n\r")
            if not ln or ln.startswith("#"):
                continue
            row = []
            i = 0
            while i < len(ln):
                if ln[i] == q:
                    # Quoted field
                    i += 1
                    fld = ""
                    while i < len(ln):
                        if ln[i] == e and i + 1 < len(ln):
                            fld += ln[i + 1]
                            i += 2
                        elif ln[i] == q:
                            i += 1
                            break
                        else:
                            fld += ln[i]
                            i += 1
                    row.append(fld)
                    if i < len(ln) and ln[i] == d:
                        i += 1
                else:
                    # Unquoted field
                    j = i
                    while j < len(ln) and ln[j] != d:
                        if ln[j] == e and j + 1 < len(ln):
                            j += 2
                        else:
                            j += 1
                    fld = ln[i:j].replace(e + d, d).replace(e + e, e)
                    row.append(fld)
                    i = j + 1
            r.append(row)
    return r


def w(f, rows, d="|", q='"', e="\\"):
    """Write rows to CSV with custom delimiters."""
    with open(f, "w") as fh:
        for row in rows:
            parts = []
            for val in row:
                val = str(val)
                if d in val or q in val or e in val or "\n" in val:
                    val = val.replace(e, e + e)
                    val = val.replace(q, e + q)
                    parts.append(q + val + q)
                else:
                    parts.append(val)
            fh.write(d.join(parts) + "\n")


def v(rows, schema):
    """Validate rows against schema."""
    errs = []
    for i, row in enumerate(rows):
        if len(row) != len(schema):
            errs.append(f"Row {i}: expected {len(schema)} cols, got {len(row)}")
            continue
        for j, (val, (name, typ)) in enumerate(zip(row, schema)):
            if typ == "int":
                try:
                    int(val)
                except:
                    errs.append(f"Row {i}, col {j} ({name}): not an int")
            elif typ == "float":
                try:
                    float(val)
                except:
                    errs.append(f"Row {i}, col {j} ({name}): not a float")
            elif typ == "date":
                try:
                    datetime.strptime(val, "%Y-%m-%d")
                except:
                    errs.append(f"Row {i}, col {j} ({name}): not a date")
            elif typ == "required":
                if not val.strip():
                    errs.append(f"Row {i}, col {j} ({name}): required")
    return errs
