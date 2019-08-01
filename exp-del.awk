#!/usr/bin/awk -f

function print_params() {
    print "------------------------------"
    printf("recno: '%d'\n", recno)
    printf("tmpfile: '%s'\n", tmpfile)
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


    if (ARGC > 2) {
        printf("Illegal parameter '%s'\n", ARGV[2])
        is_exit = 1
        exit 1
    }

    if (ARGV[1] ~ /^[0-9]+$/) {
        recno = ARGV[1]
    } else {
        printf("Specify record number to delete\n")
        is_exit = 1
        exit 1
    }

    #$$ Need to clean up tmp files?
    "echo /tmp/expenses$$" | getline tmpfile
    system("rm -f " tmpfile)
    system("touch " tmpfile)

    # Force awk to always read expense file as the only input file.
    ARGV[1] = expfile
    ARGC = 2

#    print_params()
}

END {
    if (is_exit) exit 1

    if (recline == "") {
        print "No record to delete."
        exit 1
    }

    print recline
    printf("Delete? (y/n): ")
    getline ans < "-"
    if (ans != "y" && ans != "Y") {
        exit 1
    }

    # cp /tmp/expenses$$ /home/user/.expenses
    "echo ~" | getline homedir
    cmd = "cp " tmpfile " " homedir "/.expenses"
    system(cmd)

    print "Record deleted."
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

recno != NR { print >> tmpfile }
recno == NR { recline = $0 }

