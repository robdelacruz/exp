#!/bin/sh

EXPFILE=${EXPFILE:-~/.expenses}

desc=$1
amt=$2
cat=$3
dt=$4
tm=$5

print_usage() {
    echo 'Usage:
    exp-add.sh DESC AMT CAT [DATE] [TIME]

    DESC : short description of expense
    AMT  : numeric amount
    CAT  : unique category name
    DATE : optional - date in iso date format YYYY-MM-DD
    TIME : optional - time in HH:MM format

    if DATE and TIME are not specified, the current date and time will be used.

Example:
    exp-add.sh "expense description" 1.23 category_name 2019-04-01 17:30
    exp-add.sh "buy groceries" 250.00 groceries
'
}

if [ "$desc" = "" ]; then
    print_usage
    exit 1
fi

# no amount specified
if [ "$amt" = "" ]; then
    print_usage
    exit 1
fi

# no cat specified
if [ "$cat" = "" ]; then
    print_usage
    exit 1
fi

# no date specified, use current date.
if [ "$dt" = "" ]; then
    dt=$(date +%Y-%m-%d)
fi

# no time specified, use current time.
if [ "$tm" = "" ]; then
    tm=$(date +%H:%M)
fi

# invalid date format
echo "$dt" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
if [ $? != 0 ]; then
    printf "Invalid date entered: '%s'\nUse YYYY-MM-DD format.\n" "$dt"
    exit 1
fi

# invalid date format
echo "$tm" | grep -Eq '^[0-9]{2}:[0-9]{2}$'
if [ $? != 0 ]; then
    printf "Invalid time entered: '%s'\nUse HH:MM format.\n" "$tm"
    exit 1
fi

printf "%s; %s; %s; %s; %s\n" "$dt" "$tm" "$desc" "$amt" "$cat"
printf "%s; %s; %s; %s; %s\n" "$dt" "$tm" "$desc" "$amt" "$cat" >> "$EXPFILE"
exit 0



