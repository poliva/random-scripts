#!/bin/bash

#reboot router
echo "Rebooting router...."
(sleep 2; echo admin; sleep 2; echo PASSWORD; sleep 2; echo "reboot"; sleep 2; echo "exit"; sleep 2; echo "logout") | telnet vodafone

# wait for reboot
echo "Waiting for the router to reboot..."
sleep 90s 

# remove bogus iptables rule
echo "Removing bogus iptables rule..."
(sleep 2; echo admin; sleep 2; echo ktdna0ET; sleep 2; echo "sh"; sleep 2; echo "iptables -t nat -D PREROUTING_IN 1"; sleep 2; echo "exit"; sleep 2; echo "logout") | telnet vodafone

if [ $? == 0 ]; then echo "Done!" ; fi
