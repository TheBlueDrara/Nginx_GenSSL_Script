#!usr/bin/env bash
###################################### Start Safe Header #################################
#Developed by Alex Umansky aka TheBlueDrara
#Purpose: Nginx https web server easy deployment
#Data 17.4.25
#Version 0.0.1
set -o nounset
set -o errexit
set -o pipefail
###################################### End Safe Header ###################################
#. user_conf
#. nginx_template

NULL=/dev/null
LOGFILE=~/Desktop/logs #Path to the logfile
TOOLS=("nginx" "apache2-utils" "nginx-extras") #List of tools to install





function main(){
    domain="" #Domain name variable - example bla.com
    config_file="" #Path for /etc/nginx/sites-avaiable/<config_file>
    dfile="index.html" #Default file for the html source
    ssl_cert="" #Path to ssl cert file
    ssl_key="" #Path to ssl key file
    htpasswd_file="/etc/nginx/.htpasswd" #Path to .htpasswd file
    htpasswd_url_path="" #Path that will be shown in the URL

cat << 'EOF'
    _         _      _   __        ___                                
   / \   _ __(_) ___| |  \ \      / (_)_ __ ___   __ _ ___  ___  _ __ 
  / _ \ | '__| |/ _ \ |   \ \ /\ / /| | '_ ` _ \ / _` / __|/ _ \| '__|
 / ___ \| |  | |  __/ |    \ V  V / | | | | | | | (_| \__ \ (_) | |   
/_/   \_\_|  |_|\___|_|     \_/\_/  |_|_| |_| |_|\__,_|___/\___/|_|   
                                                                      
EOF



    for index in ${TOOLS[@]}; do
        check_and_install "$index"
    done


while getopts "d:s:f:a:h" opt; do
    case $opt in
        d)
            domain="$OPTARG"
            if [[ -z "$domain" ]]; then
                echo "Syntax error: -d <domain name>"
                exit 1
            fi
            config_file="/etc/nginx/sites-available/$domain"
            rootdir="/var/www/$domain"
            ;;
        s)
            if [[ "$OPTARG" != *:* ]]; then
                echo "Syntax error: -s <path to cert_file>:<path to key_file>"
                exit 1
            fi

            IFS=":" read -r ssl_cert ssl_key <<< "$OPTARG"

            if [[ -z "$ssl_crt" ]] || [[ -z "$ssl_key" ]]; then
                echo :Syntax Error: -s "<path to cert_file>:<path to key_file>"
            fi
            ;;

        f)
            dfile=$OPTARG
            if [[ -z "$OPTARG" ]]; then
                echo "Syntax Error: -f <main html file>"
                exit 1
            fi
            ;;
        a)
            if [[ ! "$OPTARG" =~ ^[^:]+:[^:]+:[^:]+$ ]]; then
                echo "Syntax Error: -a <url_path>:<username>:<password>"
                exit 1
            fi
            IFS=":" read -r htpasswd_url_path htpasswd_user htpasswd_password <<< "$OPTARG"
            if [[ -z $htpasswd_url_path || -z $htpasswd_user || -z $htpasswd_password ]]; then
                echo "Syntax Error: -a <url_path>:<username>:<password>"
                exit 1
            fi
            ;;

    esac
done
   
    if [[ -z "$domain" ]] || [[ -z "$ssl_cert" ]] || [[ -z "$ssl_key" ]] || [[ -z "$

    





















}


#check if the packages are installed, if not, install
function check_and_install(){
    package=$1
    for tool in $package; do
        if ! dpkg -s $tool &>$NULL; then
            echo "Installing $tool please wait..."
            if ! sudo apt-get install $tool -y >> $LOGFILE 2>&1; then
                log ERROR "[check_and_install] Failed to install $tool"
                echo -e "Failed to install $tool\
                \nExisting Script..."
                return 1
            else
                log INFO "[check_and_install] Successfully installed $tool"
            fi
         else
            log INFO "[check_and_install] Tool already exists $tool"
        fi
    done
    return 0
}


#log template
function log(){
local level="$1"; shift
local message="$*"
local timestamp
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
echo "[$timestamp] [$level] $message" >> $LOGFILE
}


main "@&"
