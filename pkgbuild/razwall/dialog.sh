#!/bin/bash



choice=$(dialog --menu "Select an option:" 10 30 3 \

    1 "Option 1" \

    2 "Option 2" \

    3 "Option 3") 



case $choice in

    1) 

        echo "You selected Option 1"

        ;;

    2) 

        echo "You selected Option 2"

        ;;

    3) 

        echo "You selected Option 3"

        ;;

esac
