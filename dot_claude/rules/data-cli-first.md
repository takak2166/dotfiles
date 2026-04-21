# Data handling: CLI-first (format-aware tools)

- For data parsing/transformation (JSON/YAML/CSV/TSV/etc.), **prefer Linux CLI tools** over writing Python scripts (e.g. `python -c ...` or `.py`).
- Use **format-aware tools** so the workflow stays shell-native, composable, and easy to audit.
- Exceptions are allowed only when a CLI approach is **unreasonably complex or impractical** (e.g. very complex streaming transforms, mixed non-structured input, extremely large data requiring custom logic). If you must use a script, briefly state why CLI is not suitable.

## Recommended tools by format

- **JSON**: `jq`
- **YAML**: `yq`
- **CSV**: `csvcut` (csvkit)
- **TSV**: `mlr`, `tsv-utils`

## Examples

- JSON pretty print: `jq . file.json`
- YAML extract: `yq '.items[].id' file.yaml`
- CSV select columns: `csvcut -c id,name file.csv`
- CSV filter (Miller): `mlr --csv filter '$enabled=="true"' then cut -f id file.csv`
