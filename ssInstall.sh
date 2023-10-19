#!/bin/sh

############################################################
# Help                                                     #
############################################################
Help(){
    # Display Help
    echo "This function installs the systemd files for the HEMsaw Adapter and the Agent."
    echo "To securly set up the agent an mtconnect user and group is created. The agent"
    echo "is run using this mtconnect group so that it has lower permissions, while the"
    echo "adapter is run using the default permissions."
    echo
    echo "Syntax: ssInstall.sh [-h|-a File_Name|-d File_Name|-u Serial_number]"
    echo "options:"
    echo "-h                    Print this Help."
    echo "-a File_Name          Declare the afg file name; Defaults to - SmartSaw_DC_HA.afg"
    echo "-d File_Name          Declare the MTConnect agent device file name; Defaults to - SmartSaw_DC_HA.xml"
    echo "-u Serial_number      Declare the serial number for the uuid; Defaults to - SmartSaw"
}

############################################################
# Installers                                               #
############################################################

InstallAdapter(){
    echo "Installing MTConnect Adapter and setting it as a SystemCTL..."

    mkdir -p /etc/adapter/
    cp -r ./adapter/. /etc/adapter/
    cp -r ./afg/$Afg_File /etc/adapter/
    chmod +x /etc/adapter/Adapter

    cp /etc/adapter/adapter.service /etc/systemd/system/
    systemctl enable adapter
    systemctl start adapter
    systemctl status adapter

    echo "MTConnect Adapter Up and Running"
}

InstallMTCAgent(){
    if service_exists docker; then
        echo "Shutting down any old Docker containers"
        docker-compose down
    fi

    echo "Moving MTConnect Files..."
    if ! user_exists mtconnect; then
        useradd -r -s /bin/false mtconnect
        chown mtconnect:mtconnect /var/log/mtconnect
    fi

    mkdir -p /etc/mtconnect/
    mkdir -p /etc/mtconnect/agent/
    mkdir -p /etc/mtconnect/devices/
    mkdir -p /etc/mtconnect/schema/
    mkdir -p /etc/mtconnect/styles/

    cp -r ./agent/. /etc/mtconnect/agent/
    sed -i '1 i\Devices = /etc/mtconnect/data/devices/'$Device_File /etc/mtconnect/agent/agent.cfg
    cp -r ./devices/$Device_File /etc/mtconnect/devices/
    sed -i "11 i\        <Device id=\"saw\" uuid=\"HEMSaw_$Serial_Number\" name=\"Saw\">" /etc/mtconnect/devices/$Device_File
    cp -r ./schema/. /etc/mtconnect/schema/
    cp -r ./styles/. /etc/mtconnect/styles/
    cp -r ./ruby/. /etc/mtconnect/ruby/
    chown -R mtconnect:mtconnect /etc/mtconnect

    if test -f /etc/mosquitto/passwd; then
        echo "Updating Mosquitto files..."
        cp -u ./mqtt/data/passwd /etc/mosquitto
        chmod 0700 /etc/mosquitto/passwd
        cp -u ./mqtt/data/acl /etc/mosquitto
        chmod 0700 /etc/mosquitto/acl
        cp -u ./mqtt/config/mosquitto.conf /etc/mosquitto/conf.d/
    else
        echo "Updating Mosquitto files..."
        mkdir -p /etc/mosquitto/conf.d/
        cp -u ./mqtt/data/passwd /etc/mosquitto
        chmod 0700 /etc/mosquitto/passwd
        cp -u ./mqtt/data/acl /etc/mosquitto
        chmod 0700 /etc/mosquitto/acl
        cp -u ./mqtt/config/mosquitto.conf /etc/mosquitto/conf.d/
    fi
}

InstallDocker(){
    if service_exists docker; then
        echo "Stopping the daemons..."
        systemctl stop agent

        apt update
        apt upgrade -y

        echo "Starting up the Docker image"
        docker-compose up --remove-orphans -d 
    else
        echo "Installing Docker..."
        apt update
        apt install -y docker-compose
        apt clean

        echo "Stopping the daemons..."
        systemctl stop agent

        echo "Starting up the Docker image"
        docker-compose up --remove-orphans -d 
    fi
    docker-compose logs
}


############################################################
# Service exists function                                  #
############################################################

service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

user_exists() {
    local n=$1
    if id -u "$n.user" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

if [[ $(id -u) -ne 0 ]] ; then echo "Please run ssInstall.sh as sudo" ; exit 1 ; fi

if user_exists mtconnect; 
    then echo 'mtconnect user found, run bash ssUpgrade.sh instead'; exit 1 
else
    echo 'Mtconnet user not found, continuing install...'
fi

# Set default variables
Afg_File="SmartSaw_DC_HA.afg"
Device_File="SmartSaw_DC_HA.xml"
Serial_Number="SmartSaw"

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":a:d:u:h" option; do
    case ${option} in
        h) # display Help
            Help
            exit;;
        a) # Enter an AFG file name
            Afg_File=$OPTARG;;
        d) # Enter a Device file name
            Device_File=$OPTARG;;
        u) # Enter a serial number for the UUID
            Serial_Number=$OPTARG;;
        \?) # Invalid option
            Help
            exit;;
    esac
done

### TODO Look at adding an option to the install or update scripts to create an https secure version of the agent

echo "Printing the Working Directory and options..."
echo "AFG file = "$Afg_File
echo "MTConnect Agent file = "$Device_File
echo "Mosquitto Config file = mosquitto.conf"
echo "MTConnect UUID = HEMSaw_"$Serial_Number
echo ""

echo ""
if service_exists docker; then
    echo "Shutting down any old Docker containers"
    docker-compose down
fi


InstallAdapter
InstallMTCAgent
InstallDocker
    

echo ""
echo "Check to verify containers are running:"
docker system prune -f
docker ps
