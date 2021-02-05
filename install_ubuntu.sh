#!/bin/bash
# Mod by Dolfies
# This is meant only for Ubuntu (confirmed working on Ubuntu Server 20.10)

#Step 1) Check if root--------------------------------------
if [[ $EUID -ne 0 ]]; then
   echo "Please execute script as root." 
   exit 1
fi
#-----------------------------------------------------------

#Step 2) Update repository----------------------------------
sudo apt-get update -y
#-----------------------------------------------------------

#Step 3) disable UART from retroflag install ---------------
cd /boot/firmware
File=config.txt
if grep -q "^enable_uart=1" "$File";
	then
		echo "UART is already enabled. Disableing now!"
		echo "Commenting out line - your CPU is not throttled anymore"
		sed -i -e "s|^enable_uart=1|#enable_uart=1|" "$File" &> /dev/null
	else
		echo "UART is disabled. CPU is working with full speed"
fi
#-----------------------------------------------------------

#Step 4) Install gpiozero module----------------------------
sudo apt-get install -y python3-gpiozero
#-----------------------------------------------------------

#Step 5) Download Python script-----------------------------
cd /opt
sudo mkdir -p RetroFlag
cd /opt/RetroFlag
script=SafeShutdown.py

if [ -e $script ];
	then
		echo "Script SafeShutdown.py already exists. Overwriting file now!"
		echo "Downloading ..."
	else
		echo "Script will be installed now! Downloading ..."
fi

wget -N -q --show-progress "https://raw.githubusercontent.com/crcerror/retroflag-picase/master/SafeShutdown.py"
wget -N -q --show-progress "https://raw.githubusercontent.com/crcerror/retroflag-picase/master/multi_switch.sh"
chmod +x multi_switch.sh

#-----------------------------------------------------------

#Step 6) Enable Python script to run on start up------------
cd /etc
RC=rc.local

if grep -q "sudo python3 \/opt\/RetroFlag\/SafeShutdown.py \&" "$RC";
	then
		echo "File /etc/rc.local already configured. Doing nothing."
	else
		if grep -q "exit 0 \&" "$RC";
			then
				sed -i -e "s/^exit 0/sudo python3 \/opt\/RetroFlag\/SafeShutdown.py \&\n&/g" "$RC"
				echo "File /etc/rc.local configured."
			else
				echo "#\!/bin/sh -e" >> $RC
				echo "sudo python3 /opt/RetroFlag/SafeShutdown.py" >> $RC
				echo "exit 0" >> $RC
				echo "File /etc/rc.local configured."
		fi
fi

chmod +x $RC

#-----------------------------------------------------------

#Step 7) enable overlay file for powercut ---------------
cd /boot/firmware
File=config.txt
if ! grep -q "^dtoverlay=gpio-poweroff,gpiopin=4,active_low=1,input=1" $File; then
    echo "Enable overlay file"
    echo "# Overlay setup for proper powercut, needed for Retroflag cases" >> "$File"
    echo "dtoverlay=gpio-poweroff,gpiopin=4,active_low=1,input=1" >> "$File"
fi

#-----------------------------------------------------------

#Step 8) Reboot to apply changes----------------------------
echo "RetroFlag Pi Case installation done. Will now reboot after 3 seconds."
sleep 3
sudo reboot
#-----------------------------------------------------------
