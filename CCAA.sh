#!/bin/bash

#########################################################
# Auto Log in for Cisco Clean Access Agent 1.1		#
#########################################################
# Author: Peter Varney			   		#
# License:GNU GPL Version 2.x		   		#
#########################################################
# File Name: CCAA.sh					#
# To Use:						#
#	When you first run this script you		#
#  	need to provide a username, password		#
#  	and optionaly the ethernet card to    		#
#  	use.				  		#
#					   		#
#	/CCAA.sh user_name password			#
#	/CCAA.sh user_name password network_card	#
#########################################################

#make auth file
if [ "$1" != "" ] && [ "$2 != "" ] && [ "$3" != "" ]
then
	echo username=$1 > /etc/CCAAauth
	echo password=$2 >> /etc/CCAAauth
	echo nic=$3 >> /etc/CCAAauth
else if [ "$1" != "" ] && [ "$2" != "" ]
then
	echo username=$1 > /etc/CCAAauth
	echo password=$2 >> /etc/CCAAauth
fi

#load auth file or send error
if [ -e /etc/CCAAauth ]
then
	username=`cat /etc/CCAAauth | grep username | head -1 | awk -F '=' '{print $2}'`
	password=`cat /etc/CCAAauth | grep password | head -1 | awk -F '=' '{print $2}'`
	nic=`cat /etc/CCAAauth | grep nic | head -1 | awk -F '=' {print $3}'`
	#If the eth card isnt given default to eth0
	if [ '$nic'="" ]
	then
		nic=eth0
	fi
else
	#Print error and stop script
	echo 'Error: /etc/CCAAauth does not exist'
	echo 'Run ./CCAA.sh user_name password'
	echo 'Or ./CCAA.sh user_name password network_card'
	exit 1
fi

#some needed Values from the cisco clean access login page
reqForm=perfigo_simple_login.jsp
uri=http://www.google.com
cm=ws32vklm
userip=`ifconfig $nic | grep inet | head -1 |awk '{print $2}' | awk -F ':' '{print $2}'`
os=LINUX
index=0
provider=Student-DC

while [ 1 == 1 ]
do
        retval=`curl www.google.com 2>/dev/null | grep 'You are being redirected to the network authentication page.' | wc -l`
	
	#check if loged in already
        if [ "$retval" != 0 ]
        then
		#Need to log in

        	#log into cisco clean access
	        retval=`curl --insecure -d "reqForm=$reqForm&uri=$uri&cm=$cm&userip=$userip&os=$os&index=$index&username=$username&password=$password&provider=$provider" https://158.65.128.31/auth/perfigo_validate.jsp 2>/dev/null`
		
		#find out if you need to agree and handle it
		doAgree=`echo $retval | grep userkey | wc -l` 
		if [ "$doAgree" != 0 ]
		then
	        	#parse values from page
	        	userkey=`echo $retval | grep userkey | head -1 | awk -F '?' '{print $2}' | awk -F '&' '{print $1}' | awk -F '=' '{print $2}'`	
			#Agree to the network policy
        		retvar=`curl --insecure -d "uri=$uri&userip=$userip&os=$os&index=$index&username=$username&noreport=true&userkey=$userkey" https://158.65.128.31/auth/perfigo_cm_policy.jsp 2>/dev/null`
		fi

	        #make sure things logged in
        	retval=`curl www.google.com 2>/dev/null | grep 'You are being redirected to the network authentication page.' | wc -l`
	        if [ "$retval" == 0 ]
	        then
       		        echo Login Successful!
        	else
        		echo Error Signing On!
		fi
	else	
		#you are already loged on
	        echo Already Loged In.
        fi
	
	#pause for some time
	sleep 300
done
