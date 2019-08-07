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

function is_cat(s) {
    if (is_yyyy(s) || is_yyyy_mm(s) || is_yyyy_mm_dd(s)) {
        return 0
    }
    return 1
}

function print_params() {
    print "------------------------------"
    printf("cat: '%s'\n", cat)
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
    # Unlike traditional awk scripts, you can't specify the input files as args in this one.
    #

    # Separator: single semi-colon followed by any number of whitespace.
    FS=";[\t ]*"

    # expense file is determined by the following settings, in order of priority:
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

    cat = ""
    yyyy = ""
    yyyy_mm = ""
    yyyy_mm_dd = ""
    startdt = ""
    enddt = ""

    i=1
    if (is_cat(ARGV[i])) {
        cat = ARGV[i]
        ARGV[i]=""
        i++
    }

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
        } else if (ARGV[i] != "--recno") {
            printf("Illegal parameter '%s'\n", ARGV[i])
            exit 1
        }
    }

    if (ARGV[i] == "--recno") {
        show_recno = 1
        i++
    }

    if (i < ARGC) {
        printf("Illegal parameter '%s'\n", ARGV[i])
        is_exit = 1
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
    if (is_exit) exit 1

    if (sum_amt > 0) {
        printf("--------------------------------------------------------------------\n")
        printf("%-12s %-30s %9.2f    %-10s\n", "Totals", "", sum_amt, "")
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

function print_rec() {
    #printf("%-12s %-30s %9.2f  %-10s\n", $1, substr($3, 0, 30), $4, $5)

    if (show_recno)
        printf("#%-5d %-12s %-30s %9.2f  %-10s\n", NR, $1, substr($3, 0, 30), $4, $5)
    else 
        printf("%-12s %-30s %9.2f  %-10s\n", $1, substr($3, 0, 30), $4, $5)

    sum_amt = sum_amt + $4
}

(!cat || $5 == cat) && (yyyy && $1 ~ yyyy)          { print_rec(); next }
(!cat || $5 == cat) && (yyyy_mm && $1 ~ yyyy_mm)    { print_rec(); next }
(!cat || $5 == cat) && (yyyy_mm_dd && $1 == yyyy_mm_dd)  { print_rec(); next }
(!cat || $5 == cat) && ($1 >= startdt && $1 <= enddt)    { print_rec(); next }

