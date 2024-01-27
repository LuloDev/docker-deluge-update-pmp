#!/bin/bash
# Credit to https://www.reddit.com/r/ProtonVPN/comments/10owypt/successful_port_forward_on_debian_wdietpi_using/
#Determine protonvpn port and update/restart deluge
#Add the following to sudo crontab -e
#* * * * * sleep 50; /bin/sh /usr/local/bin/update_deluge_port.sh

#Function to parse the active port from the deluge configuration file
findconfiguredport()
{
        /bin/grep -zoP '\"listen_ports\": \[\n\K.*(?=,\n)' /config/core.conf|/bin/tr -d '\0'|/bin/xargs;
}

#Function which uses natpmp to determine the active port
findactiveport()
{
        /usr/bin/python3 /scripts/py-natpmp/natpmp/natpmp_client.py -g 10.2.0.1 0 0 | /bin/grep -oP '(?<=public port ).*(?=,)'|/bin/xargs;
}

#Execute the above functions and set variables
previous_configured_port=$(findconfiguredport);
current_active_port=$(findactiveport);

#Determine if the port has changed from what is configured
if [ ${previous_configured_port} != ${current_active_port} ]; then
	#Notify of port change
         /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') The port has changed from ${previous_configured_port} to ${current_active_port}"

        #If the port has changed then we should remove the allowed entry from ufw
        #/bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Deleting previous allow rule from ufw: $(/usr/sbin/ufw delete allow ${previous_configured_port})";
 
        #Now use deluge-console to update the active configuration and wait 5 seconds for the configuration to update in the background
		/bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Updating Deluge with the new port: $(deluge-console -d 127.0.0.1 -p 58846 -U cron -P MyC0mpL3xPass status "config -s listen_ports (${current_active_port},${current_active_port})").. waiting 5 seconds for configuration to update. $(/bin/sleep 5)"; 

        #Run function again to find the updated port in the Deluge configuration
        updated_configured_port=$(findconfiguredport);

        #Verify the configured port now matches the active port
        if [ ${updated_configured_port} = ${current_active_port} ]; then
		#If port is correct write out the success to the specified log file
                /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Verified port ${previous_configured_port} was successfully updated to port ${updated_configured_port}.";
				
                #Add new allow entry to ufw
               ## /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Adding new allow rule to ufw: $(/usr/sbin/ufw allow ${updated_configured_port})";
        else
                #We attempted to update Deluge, but the values don't match so time to panic
                /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Something went wrong.";
        fi
else
        #Nothing needs to be done because the values already match
        /bin/echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') Configured port ${previous_configured_port} is already correct";
fi