# 1. Project Overview

**Project name:** depenses  
**Project type:** Bash Personal Expense Tracker

The purpose of this tool is to help users record, view, delete, and calculate their personal expenses from the Linux terminal.

## 2. Features and Commands

| Command | Description | Example |
| `add` | Add a new expense | `./depenses.sh add 1500 Food Lunch` |
| `list` | Display all expenses | `./depenses.sh list` |
| `delete` | Delete an expense by ID | `./depenses.sh delete 2` |
| `total` | Calculate all expenses | `./depenses.sh total` |
| `month` | Display the current month's report | `./depenses.sh month` |
| `help` | Display usage instructions | `./depenses.sh help` |

## 3. Add Command Format

```bash
./depenses.sh add AMOUNT CATEGORY [NOTE]
```

Example:

```bash
./depenses.sh add 1500 Food "Lunch at Mama Ngozi"
```

The note is optional and may contain spaces.

## 4. Data Storage

The application stores expenses in a local text file.

Default location:

```text
~/.local/share/depenses/expenses.txt
```

The data path can be changed using the `DEPENSES_FILE` environment variable.

Example:

```bash
export DEPENSES_FILE=/tmp/depenses-test.txt
```

### Data format

Each expense is stored as one tab-separated line with five fields:

```text
ID    AMOUNT    CATEGORY    DATE    NOTE
```

Example:

```text
1    1500    Food    2026-11-06    Lunch at Mama Ngozi
```

The fields are stored in this order: ID, amount, category, date, and note.

## 5. Validation Rules

- Amount must be a positive number.
- Amount may have at most two decimal places.
- Category may contain only letters, digits, underscores, and hyphens.
- Category names are case-sensitive. For example, `Food` and `food` are treated as different categories.
- Notes cannot contain tabs or newline characters.
- Invalid commands, missing arguments, extra arguments, and unknown expense IDs produce an error message.
- Invalid input exits with status code 1.

## 6. ID Behaviour

Each expense receives an ID.

The next ID is calculated using the highest ID currently in the data file, plus one. Therefore, if the expense with the highest ID is deleted, that ID may be reused by the next expense.

## 7. Reports

The `total` command calculates the total amount of all recorded expenses.

The `month` command groups expenses by category and reports totals for the current month only.

Category matching is case-sensitive.

## 8. Error Handling and Edge Cases

The application handles:

- Invalid and non-positive amounts.
- Amounts with more than two decimal places.
- Empty categories.
- Missing or extra command arguments.
- Unknown commands.
- Invalid or unknown expense IDs.
- Empty data files.
- Notes containing spaces.
- Deletion of an expense using its ID.

The application uses a temporary file when deleting an expense to avoid directly rewriting the original data during the operation.

## 9. Known Limitations and Design Decisions

- The application is designed for local terminal use.
- Category names are case-sensitive.
- IDs may be reused after deleting the highest existing ID.
- Leading-zero amounts such as `007` are currently accepted.
- The data file is expected to follow the application's tab-separated format. Manually editing it incorrectly may affect reports.
- The application does not provide a graphical user interface or cloud synchronisation.

## 10. Testing

Automated tests are located in:

```text
tests/test_depenses.sh
```

Run the tests with:

```bash
./tests/test_depenses.sh
```

The test script checks help, adding, listing, totals, monthly reports, deleting, invalid amounts, and unknown IDs.

## 11. Quality Checklist

- [x] Valid expense amounts are accepted.
- [x] Invalid amounts are rejected.
- [x] Categories are validated.
- [x] Notes containing spaces are supported.
- [x] Empty data is handled.
- [x] Deleting an expense works.
- [x] Total calculation works.
- [x] Monthly reports work.
- [x] Error messages are displayed for invalid commands and arguments.
- [x] Automated tests pass (8/8).
- [x] `bash -n depenses.sh` passes.
- [x] ShellCheck passes on `depenses.sh` and `tests/test_depenses.sh` (verified by reviewer).
