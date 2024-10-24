#!/bin/bash
 
    # Run 'free' command in kilobytes and display the output
    free_output=$(free -k)
    echo "Free command output before dropcache:"
    echo "$free_output"
#    echo "---------------------------------------------"
# 
    echo 3 > /proc/sys/vm/drop_caches
#    echo "---------------------------------------------"
#    echo "Dropcache done"
#    echo "---------------------------------------------"
 
    free_output=$(free -k)
    echo "Free command output after dropcache:"
    echo "$free_output"
#    echo "---------------------------------------------"
