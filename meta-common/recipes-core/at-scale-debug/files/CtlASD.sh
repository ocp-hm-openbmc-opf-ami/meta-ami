#!/bin/sh

SERVICE_NAME=com.intel.AtScaleDebug.service

# Usage: 
#     ./CtlASD.sh "start" | "stop" | "is-enabled" | "is-active" | "enable" | "disable"
# 
# Return: 
#     "0" : disable | inactive
#     "1" : enable | active
#     "-1" : argument error
# 
#  -------------------+--------------------------------------
#       Redfish       |           shell script
#  -------------------+--------------------------------------
#                     |
#       [Input]       |
#       "start"       | systemctl start $SERVICE_NAME 
#                     | systemctl is-active $SERVICE_NAME
#                     |
#       [Output]      |  # return  
#       "0" / "1"     |  "1"= active   
#                     |  "0"= inactive 
#                     |
#  -------------------+--------------------------------------
#                     |
#       [Input]       |
#       "stop"        | systemctl stop $SERVICE_NAME 
#                     | systemctl is-active $SERVICE_NAME
#                     |
#       [Output]      |  # return 
#       "0" / "1"     |  "1"= active   
#                     |  "0"= inactive 
#                     |
#  -------------------+--------------------------------------
#                     |
#       [Input]       |
#     "is-enabled"    |
#                     | systemctl is-enabled $SERVICE_NAME
#                     |
#       [Output]      |  # return
#       "0" / "1"     |  "1"= enable   
#                     |  "0"= disable 
#                     |
#  -------------------+--------------------------------------
#                     |
#       [Input]       |
#     "is-active"     |
#                     | systemctl is-active $SERVICE_NAME
#                     |
#       [Output]      |  # return
#       "0" / "1"     |  "1"= active   
#                     |  "0"= inactive 
#                     |
#  -------------------+--------------------------------------
#                     |
#       [Input]       |
#       "enable"      |
#                     | systemctl enable $SERVICE_NAME
#                     |
#       [Output]      |  # return
#       "0" / "1"     |  "1"= enable   
#                     |  "0"= disable 
#                     |
#  -------------------+--------------------------------------
#                     |
#       [Input]       |
#       "disable"     |
#                     | systemctl disable $SERVICE_NAME
#                     |
#       [Output]      |  # return
#       "0" / "1"     |  "1"= enable   
#                     |  "0"= disable 
#                     |
#  -------------------+--------------------------------------

ret=-1

case "$1" in
    "is-enabled")
        if [ $(systemctl is-enabled $SERVICE_NAME) == "enabled" ]
        then 
            ret=1
        elif [ $(systemctl is-enabled $SERVICE_NAME) == "disabled" ]
        then
            ret=0
        fi

        #return: 1 = enable , 0 = disable
    ;;
    
    "is-active")
        if [ $(systemctl is-active $SERVICE_NAME) == "active" ]
        then 
            ret=1
        elif [ $(systemctl is-active $SERVICE_NAME) == "inactive" ]
        then
            ret=0
        fi

        #return:  1 = active , 0 = inactive
    ;;
    
    "start")
        systemctl start $SERVICE_NAME > /dev/null
        if [ $(systemctl is-active $SERVICE_NAME) == "active" ]
        then 
            ret=1
        elif [ $(systemctl is-active $SERVICE_NAME) == "inactive" ]
        then
            ret=0
        fi

        #return:  1 = active , 0 = inactive
    ;;
    
    "stop")
        systemctl stop $SERVICE_NAME > /dev/null
        if [ $(systemctl is-active $SERVICE_NAME) == "active" ]
        then 
            ret=1
        elif [ $(systemctl is-active $SERVICE_NAME) == "inactive" ]
        then
            ret=0
        fi

        #return:  1 = active , 0 = inactive
    ;;

     "enable")
        systemctl enable $SERVICE_NAME > /dev/null
        if [ $(systemctl is-enabled $SERVICE_NAME) == "enabled" ]
        then 
            ret=1
        elif [ $(systemctl is-enabled $SERVICE_NAME) == "disabled" ]
        then
            ret=0
        fi

        #return: 1 = enable , 0 = disable
    ;;

     "disable")
        systemctl disable $SERVICE_NAME > /dev/null
        if [ $(systemctl is-enabled $SERVICE_NAME) == "enabled" ]
        then 
            ret=1
        elif [ $(systemctl is-enabled $SERVICE_NAME) == "disabled" ]
        then
            ret=0
        fi

        #return: 1 = enable , 0 = disable
    ;;
   
esac

echo $ret
