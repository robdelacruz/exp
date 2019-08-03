#!/usr/bin/awk -f

function print_params() {
    print "------------------------------"
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
    # Sort tmpfile in place: sort -o /tmp/expenses$$ /tmp/expenses$$
    cmd = "sort -o " tmpfile " " tmpfile
    system(cmd)

    # cp /tmp/expenses$$ /home/user/.expenses
    cmd = "cp " tmpfile " " expfile
    system(cmd)
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

# Skip over any blank lines.
$0 !~ /^[ \t]*$/ { print >> tmpfile }

