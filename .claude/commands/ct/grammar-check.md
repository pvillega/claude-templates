---
description: "Fix grammar and spelling mistakes in markdown files using British English standards"
arguments:
  - name: "file"
    type: "optional positional"
    description: "Specific markdown file to check (e.g., README.md, CONTRIBUTING.md). If omitted, scans git-modified markdown files instead."
    example: "ct:grammar-check README.md"
argument-hint: "[optional: file.md - specific file to check, or omit to scan git-modified files]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
---

# Grammar Check

Systematically check and fix grammar, spelling, and style mistakes in markdown files using British English standards, while preserving the original tone and structure.

## Your Task

1. **Identify target files**:
   - If file argument provided (e.g., `README.md`), validate it exists and is a markdown file (.md, .markdown, .txt)
   - If no argument provided, use `git status` to find modified/untracked markdown files
   - Skip non-markdown files

2. **Create safety backups**:
   - For each target file, run `cp "file.md" "file.md.bak"`
   - If backup already exists, remove it first to avoid conflicts

3. **Check and fix grammar/spelling**:
   - Read the file content carefully
   - Apply British English corrections (colour, realise, centre, defence, etc.)
   - Fix grammar issues: subject-verb agreement, verb tenses, punctuation, apostrophes
   - Fix style: sentence structure, consistent terminology, proper capitalisation
   - Preserve all markdown syntax, code blocks, tables, URLs, file paths, and technical terms
   - Maintain the original tone and voice

4. **Write corrected content**:
   - Save all corrections to the original file
   - Ensure markdown syntax remains intact
   - Verify no formatting was broken

5. **Report what was done**:
   - List files processed and backup locations
   - Summarise correction types applied (spelling, grammar, style)
   - Suggest running `diff file.md.bak file.md` to review changes

## Output Format

Present a summary followed by details:

```
Grammar check complete for 2 files:

- README.md: Fixed 3 spelling (colour, realise, centre), 2 grammar (subject-verb), 1 style (comma usage)
  Backup: README.md.bak

- CONTRIBUTING.md: Fixed 1 spelling (defence)
  Backup: CONTRIBUTING.md.bak

To review changes:
  diff README.md.bak README.md
  diff CONTRIBUTING.md.bak CONTRIBUTING.md
```

## Notes

- **British English standard**: Use UK spelling conventions (-ise, -our, -re, -ence endings)
- **Preserve meaning**: Only fix grammar/spelling, never alter the author's intent or technical accuracy
- **Backup strategy**: Always create .bak files for easy rollback and comparison
- **Markdown safe**: Never break markdown syntax, formatting, or special elements
- **Technical preservation**: Keep code examples, URLs, proper nouns, brand names unchanged
- **Tone preservation**: Maintain original writing style and voice
- Safe to run multiple times on the same files
