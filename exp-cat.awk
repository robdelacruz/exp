#!/usr/bin/awk -f

function is_yyyy(s) {
    return s ~ /^[0-9]{4}$/
}

function is_yyyy_mm(s) {
    return s ~ /^[0-9]{4}-[0-9]{2}$/
}

function is_yyyy_mm_dd(s) {
    return s ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
}

function print_params() {
    print "------------------------------"
    printf("yyyy: '%s'\n", yyyy)
    printf("yyyy_mm: '%s'\n", yyyy_mm)
    printf("yyyy_mm_dd: '%s'\n", yyyy_mm_dd)
    printf("startdt: '%s'\n", startdt)
    printf("enddt: '%s'\n", enddt)
    printf("\nexpfile: '%s'\n", expfile)
    print "------------------------------"
}

BEGIN {
    # Use default ~/.expenses file:
    #   exp-list.awk [cat] [startdt] [enddt]
    #
    # Specify an expenses file, ex. 'items.txt'
    #   exp-list.awk -v expfile="items.txt" [cat] [startdt] [enddt]
    #
    # Any additional cmd arguments will be flagged as an error.
    #

    # expense input file is determined by the following settings, in order of priority:
    # awk -v expfile="expenses.txt" (pre-set expfile var)
    # EXPFILE="expenses.txt"        (EXPFILE environment var)
    # "~/.expenses"                 (default, if none of the above were set)
    #
    if (!expfile) {
        "echo $EXPFILE" | getline expfile
        if (!expfile) {
            "echo ~" | getline homedir
            expfile = homedir "/.expenses"
        }
    }

    # Fields are separated by a semi-colon followed by zero or more whitespace chars.
    FS=";[\t ]*"

    yyyy = ""
    yyyy_mm = ""
    yyyy_mm_dd = ""
    startdt = ""
    enddt = ""

    i=1
    if (is_yyyy(ARGV[i])) {
        yyyy = "^" ARGV[i]
        ARGV[i]=""
        i++
    } else if (is_yyyy_mm(ARGV[i])) {
        yyyy_mm = "^" ARGV[i]
        ARGV[i]=""
        i++
    } else if (is_yyyy_mm_dd(ARGV[i])) {
        yyyy_mm_dd = ARGV[i]
        ARGV[i]=""
        i++
    }

    if (yyyy_mm_dd && i < ARGC) {
        if (is_yyyy_mm_dd(ARGV[i])) {
            startdt = yyyy_mm_dd
            enddt = ARGV[i]

            ARGV[i]=""
            yyyy_mm_dd = ""
            i++
        } else {
            printf("Illegal parameter '%s'\n", ARGV[i])
            exit 1
        }
    }

    if (i < ARGC) {
        printf("Illegal parameter '%s'\n", ARGV[i])
        exit 1
    }

    # If no date specified, default to current yyyy-mm
    if (!yyyy && !yyyy_mm && !yyyy_mm_dd && !startdt) {
        "date +%Y-%m" | getline yyyy
        yyyy = "^" yyyy
    }

    # Force awk to always read expense file as the only input file.
    ARGV[1] = expfile
    ARGC = 2

#    print_params()
}

END {
    # Print categories from highest to lowest total expense amount.
    # Category subtotals are stored in cat_total array. Ex.
    #   cat_total["commute"]:  120.35
    #   cat_total["grocery"]:  150.50
    #   cat_total["dine_out"]: 200.00
    #   ...

    longest_catlen = 0
    for (cat in cat_total) {
        if (length(cat) > longest_catlen) {
            longest_catlen = length(cat)
        }
    }

    sum_amt = 0.0
    for (;;) {
        high_val = 0.0
        high_cat = ""
        for (cat in cat_total) {
            if (cat_total[cat] >= high_val) {
                high_cat = cat
                high_val = cat_total[high_cat]
            }
        }
        if (high_cat == "") break

        printf("%-*s   %12.2f\n", longest_catlen, high_cat, cat_total[high_cat])
        sum_amt += cat_total[high_cat]

        delete cat_total[high_cat]
    }

    if (sum_amt > 0) {
        printf("----------------------------\n")
        printf("%-*s   %12.2f\n", longest_catlen, "Totals", sum_amt)
    }
}

#
# Fields:
#
# $1: date YYYY-MM-DD
# $2: time HH:MM
# $3: description
# $4: amt
# $5: category
#
# Ex. 2019-07-27;01:16;cat food at rustan's;123.45;grocery
#

function process_rec() {
    # cat_total[category] += amt
    cat_total[$5] += $4
}

yyyy && $1 ~ yyyy               { process_rec(); next }
yyyy_mm && $1 ~ yyyy_mm         { process_rec(); next }
yyyy_mm_dd && $1 == yyyy_mm_dd  { process_rec(); next }
$1 >= startdt && $1 <= enddt    { process_rec(); next }

