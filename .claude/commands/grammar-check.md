---
name: grammar-check
description: Fix grammar and spelling mistakes in markdown files using British English standards
usage: /grammar-check [file.md]
---

Systematically check and fix grammar, spelling, and style mistakes in markdown files while preserving the original tone and structure. This command uses British English as the standard and creates backups for easy comparison.

## When to Use

- Before committing documentation changes
- After writing or updating README files, specs, or other markdown documentation
- When preparing documents for review or publication
- To ensure consistent British English usage across project documentation
- After content creation or major edits to markdown files

## Process

### Phase 1: File Selection and Validation

1. **Determine target files**:
   - If specific file provided as argument, validate it exists and is readable
   - If no file specified, check git status for modified/untracked markdown files
   - Filter for `.md`, `.markdown`, and `.txt` files only

2. **Create safety backups**:
   - For each target file, create a `.bak` backup copy
   - If backup already exists, remove it first to avoid conflicts
   - Preserve original timestamps and permissions where possible

### Phase 2: Grammar and Style Analysis

For each target file:

1. **Read and analyse content structure**:
   - Preserve markdown formatting and structure
   - Maintain code blocks, tables, and special formatting
   - Identify prose sections that need grammar checking

2. **Apply British English corrections**:
   - Spelling: colour, realise, centre, defence, etc.
   - Grammar: proper verb tenses, subject-verb agreement
   - Style: consistent punctuation, sentence structure
   - Terminology: ensure technical terms are used correctly

3. **Preserve technical content**:
   - Keep code examples unchanged
   - Maintain URLs, file paths, and technical references
   - Preserve proper nouns and brand names
   - Keep markdown syntax intact

### Phase 3: Quality Review and Output

1. **Review changes made**:
   - Summarise types of corrections applied
   - Highlight any unclear passages that may need manual review
   - Note any technical terms that were uncertain

2. **Apply corrections**:
   - Write corrected content to original file
   - Maintain original file structure and formatting
   - Ensure no markdown syntax was broken

3. **Generate comparison summary**:
   - List files processed and backup locations
   - Provide summary of correction types made
   - Suggest running diff to review changes

## Implementation Details

### Grammar Checking Rules

**British English Spelling**:

- -ise endings: realise, organise, specialise
- -our endings: colour, behaviour, honour
- -re endings: centre, theatre, metre
- -ence endings: defence, licence (noun)

**Grammar Standards**:

- Proper comma usage in lists (Oxford comma optional but consistent)
- Correct apostrophe usage for contractions and possessives
- Consistent verb tenses within sections
- Subject-verb agreement corrections
- Proper capitalisation for headings and proper nouns

**Style Guidelines**:

- Clear, concise sentence structure
- Consistent terminology usage
- Appropriate technical language level
- Logical paragraph structure
- Proper markdown heading hierarchy

### File Handling

**Backup Strategy**:

```bash
# Create backup before editing
cp "original-file.md" "original-file.md.bak"

# After editing, user can compare with:
diff "original-file.md.bak" "original-file.md"
```

**Target File Detection**:

- Explicit file argument takes precedence
- Otherwise, scan git status for modified/untracked files
- Filter for markdown extensions: .md, .markdown, .txt
- Skip binary files and directories

## Expected Outcomes

After running this command:

1. **Corrected Files** - All target markdown files with improved grammar and spelling
2. **Backup Files** - Original versions preserved with .bak extension for comparison
3. **Summary Report** - Overview of corrections made and files processed
4. **Diff-Ready** - Easy comparison between original and corrected versions

## Error Handling

Handle these scenarios gracefully:

- **File not found** - Clear error message with suggestions for valid files
- **Permission denied** - Check file permissions and ownership
- **Binary files** - Skip non-text files with informative message
- **Malformed markdown** - Preserve structure even if formatting is unusual
- **Empty files** - Handle gracefully without creating unnecessary backups
- **Large files** - Process efficiently without memory issues

## Integration with Other Commands

Works well with:

- `/commit` - After grammar checking, commit the improved documentation
- `/write-spec` - Polish PRDs and specifications for clarity
- Before pull requests to ensure professional documentation quality
- `/enrich-project` - Improve the quality of generated documentation

## Usage Examples

```bash
# Check specific file
/grammar-check README.md

# Check all modified markdown files in git
/grammar-check

# After running, compare changes
diff README.md.bak README.md
```

## Important Notes

- **Preserves meaning** - Only fixes grammar/spelling, never changes intent
- **British English standard** - Consistent with UK spelling and style
- **Markdown safe** - Preserves all formatting and syntax
- **Backup creation** - Always creates .bak files for easy rollback
- **Technical preservation** - Keeps code examples and technical terms intact
- **Tone preservation** - Maintains original writing style and voice

## Completion Checklist

- [ ] Target files identified correctly
- [ ] Backup files created successfully
- [ ] Grammar and spelling corrections applied
- [ ] British English standards followed
- [ ] Markdown syntax preserved
- [ ] Technical content unchanged
- [ ] Summary of changes provided
- [ ] Files ready for diff comparison

Remember: The goal is to improve readability and professionalism while preserving the author's voice and technical accuracy.
