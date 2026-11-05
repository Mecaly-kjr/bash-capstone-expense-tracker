#!/usr/bin/env bash

# Personal Expense Tracker
# Project: depenses

set -euo pipefail

DATA_FILE="${DEPENSES_FILE:-$HOME/.local/share/depenses/expenses.txt}"

# Create the storage directory if necessary.
mkdir -p "$(dirname "$DATA_FILE")"
touch "$DATA_FILE"

# Display error and exit.
die() {
    echo "Error: $*" >&2
    exit 1
}

# Display help instructions.
show_help() {
    cat <<'EOF'
Personal Expense Tracker - depenses

Usage:
  ./depenses.sh add AMOUNT CATEGORY [NOTE]
  ./depenses.sh list
  ./depenses.sh delete ID
  ./depenses.sh total
  ./depenses.sh month
  ./depenses.sh help

Commands:
  add       Add a new expense.
  list      Display all expenses.
  delete    Delete an expense by ID.
  total     Display total expenses.
  month     Display current month's expenses by category.
  help      Display this help message.

Examples:
  ./depenses.sh add 1500 Food Lunch
  ./depenses.sh add 500 Transport Taxi
  ./depenses.sh list
  ./depenses.sh total
  ./depenses.sh month
  ./depenses.sh delete 1
EOF
}

# Validate a positive monetary amount.
valid_amount() {
    awk -v amount="$1" '
        BEGIN {
            if (amount !~ /^[0-9]+([.][0-9]{1,2})?$/) {
                exit 1
            }

            if (amount <= 0) {
                exit 1
            }
        }
    '
}

# Generate the next unique expense ID.
next_id() {
    awk -F '\t' '
        NF >= 5 && $1 ~ /^[0-9]+$/ {
            if ($1 > max) {
                max = $1
            }
        }
        END {
            print max + 1
        }
    ' "$DATA_FILE"
}

# Add a new expense.
cmd_add() {
    [[ $# -ge 2 && $# -le 3 ]] ||
        die "Usage: ./depenses.sh add AMOUNT CATEGORY [NOTE]"

    local amount="$1"
    local category="$2"
    local note="${3:-}"
    local id
    local date

    valid_amount "$amount" ||
        die "Amount must be positive and have at most two decimal places."

    [[ "$category" =~ ^[a-zA-Z0-9_-]+$ ]] ||
        die "Category must contain only letters, numbers, underscores or hyphens."

    [[ "$note" != *$'\t'* && "$note" != *$'\n'* ]] ||
        die "Note cannot contain tabs or newlines."

    id=$(next_id)
    date=$(date +%Y-%m-%d)

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$id" "$amount" "$category" "$date" "$note" >> "$DATA_FILE"

    echo "Expense added successfully!"
    echo "ID: $id"
    echo "Amount: $amount FCFA"
    echo "Category: $category"
    echo "Date: $date"
}

# Display all expenses in aligned columns.
cmd_list() {
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No expenses recorded yet."
        return
    fi

    printf '%-5s %-12s %-15s %-12s %s\n' \
        "ID" "AMOUNT" "CATEGORY" "DATE" "NOTE"

    printf '%s\n' "--------------------------------------------------------------"

    awk -F '\t' '
        NF >= 5 {
            printf "%-5s %-12s %-15s %-12s %s\n",
                $1, $2, $3, $4, $5
        }
    ' "$DATA_FILE"
}

# Delete an expense using its ID.
cmd_delete() {
    [[ $# -eq 1 ]] ||
        die "Usage: ./depenses.sh delete ID"

    local id="$1"
    local temp_file

[[ "$id" =~ ^[0-9]+$ ]] ||
    die "ID must be a positive number."

temp_file=$(mktemp "${DATA_FILE}.XXXXXX")

    if awk -F '\t' -v id="$id" '
        $1 == id {
            found = 1
            next
        }
        {
            print
        }
        END {
            if (!found) {
                exit 1
            }
        }
    ' "$DATA_FILE" > "$temp_file"; then
        mv "$temp_file" "$DATA_FILE"
        echo "Expense $id deleted successfully."
    else
        rm -f "$temp_file"
        die "Expense ID $id was not found."
    fi
}

# Calculate all-time expenses.
cmd_total() {
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "Total expenses: 0 FCFA"
        return
    fi

    awk -F '\t' '
        NF >= 5 {
            total += $2
            count++
        }
        END {
            printf "Number of expenses: %d\n", count
            printf "Total expenses: %.2f FCFA\n", total
        }
    ' "$DATA_FILE"
}

# Display current-month totals by category.
cmd_month() {
    local current_month

    current_month=$(date +%Y-%m)

    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No expenses recorded for this month."
        return
    fi

    echo "Expense report for $current_month"
    echo

    awk -F '\t' -v month="$current_month" '
        NF >= 5 && substr($4, 1, 7) == month {
            totals[$3] += $2
            overall += $2
            count++
        }
        END {
            if (count == 0) {
                print "No expenses recorded for this month."
                exit
            }

            printf "%-20s %s\n", "CATEGORY", "TOTAL (FCFA)"
            print "---------------------------------------"

            for (category in totals) {
                printf "%-20s %.2f\n", category, totals[category]
            }

            print "---------------------------------------"
            printf "%-20s %.2f\n", "TOTAL", overall
            printf "Number of expenses: %d\n", count
        }
    ' "$DATA_FILE"
}

# Main command dispatcher.
main() {
    local command="${1:-help}"

    if [[ $# -gt 0 ]]; then
        shift
    fi

    case "$command" in
        add)
            cmd_add "$@"
            ;;
        list)
            [[ $# -eq 0 ]] || die "Usage: ./depenses.sh list"
            cmd_list
            ;;
        delete)
            cmd_delete "$@"
            ;;
        total)
            [[ $# -eq 0 ]] || die "Usage: ./depenses.sh total"
            cmd_total
            ;;
        month)
            [[ $# -eq 0 ]] || die "Usage: ./depenses.sh month"
            cmd_month
            ;;
        help|-h|--help)
            [[ $# -eq 0 ]] || die "Usage: ./depenses.sh help"
            show_help
            ;;
        *)
            show_help
            die "Unknown command: $command"
            ;;
    esac
}

main "$@"
