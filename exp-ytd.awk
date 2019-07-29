#!/usr/bin/awk -f

function is_yyyy(s) {
    return s ~ /^[0-9]{4}$/
}

function print_params() {
    print "------------------------------"
    printf("yyyy: '%s'\n", yyyy)
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

    i=1
    if (is_yyyy(ARGV[i])) {
        yyyy = "^" ARGV[i]
        ARGV[i]=""
        i++
    }

    if (i < ARGC) {
        printf("Illegal parameter '%s'\n", ARGV[i])
        is_exit = 1
        exit 1
    }

    # If no date specified, default to current yyyy
    if (!yyyy) {
        "date +%Y" | getline yyyy
        yyyy = "^" yyyy
    }

    # Force awk to always read expense file as the only input file.
    ARGV[1] = expfile
    ARGC = 2

    month_name[1] = "January"
    month_name[2] = "February"
    month_name[3] = "March"
    month_name[4] = "April"
    month_name[5] = "May"
    month_name[6] = "June"
    month_name[7] = "July"
    month_name[8] = "August"
    month_name[9] = "September"
    month_name[10] = "October"
    month_name[11] = "November"
    month_name[12] = "December"

#    print_params()
}

END {
    if (is_exit) exit 1

     # Print totals for each month (January - December)

    longest_monthlen = 0
    for (i=1; i <= 12; i++) {
        if (length(month_name[i]) > longest_monthlen) {
            longest_monthlen = length(month_name[i])
        }
    }

    sum_amt = 0.0
    for (i=1; i <= 12; i++) {
        printf("%-*s   %12.2f\n", longest_monthlen, month_name[i], month_total[i])
        sum_amt += month_total[i]
    }

    printf("------------------------\n")
    printf("%-*s   %12.2f\n", longest_monthlen, "Totals", sum_amt)
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
    split($1, parts, "-")
    month_num = parts[2]+0  # 1=January, 2=February, 3=March ...

    month_total[month_num] += $4
}

yyyy && $1 ~ yyyy               { process_rec(); next }

