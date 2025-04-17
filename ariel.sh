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
. nginx_template

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
    htpasswd_user=""
    htpasswd_password=""


cat << 'EOF'
    _         _      _   __        ___                                
   / \   _ __(_) ___| |  \ \      / (_)_ __ ___   __ _ ___  ___  _ __ 
  / _ \ | '__| |/ _ \ |   \ \ /\ / /| | '_ ` _ \ / _` / __|/ _ \| '__|
 / ___ \| |  | |  __/ |    \ V  V / | | | | | | | (_| \__ \ (_) | |   
/_/   \_\_|  |_|\___|_|     \_/\_/  |_|_| |_| |_|\__,_|___/\___/|_|   
                                                                      
EOF


  #echo -e "***************************************************************************\
   # \n \
    #\n Hello dear user!\
    #\n 

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

    #Making sure every parameter is passed down 
    if [[ -z "$domain" ]] || [[ -z $htpasswd_url_path ]] || [[ -z $htpasswd_user ]] || [[ -z $htpasswd_password ]]; then
        echo "Missing one of the required parameters: -d <domain_name> -a <url_path>:<username>:<password>"
        exit 1
    fi
    #Making sure that we dont ruin an existing config file
    if [[ -e "$config_file" ]]; then
        echo "Error: config file already exists by that name in /etc/nginx/site-available"
        exit 1
    fi

    https_opts $domain $dfile $ssl_key $ssl_cert $rootdir $config_file
    auth_opts $htpasswd_file $htpasswd_url_path $htpasswd_user $htpasswd_password $config_file
    create_link $config_file
    add_domain_to_hosts $domain
    restart_nginx

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


function https_opts(){
    odomain=$1
    ofile=$2
    ossl_key=$3
    ossl_cert=$4
    oroot_dir=$5
    oconfig_file=$6

    eval "echo \"$https_config\"" | sudo tee -a $oconfig_file > $NULL
    check_and_download_ssl $ossl_cert $ossl_key
}


function auth_opts(){
    oh_file=$1
    oh_path=$2
    oh_user=$3
    oh_password=$4
    oh_config_file=$5
    oh_root_path=$6
    if ! htpasswd -b -c "$oh_file" "$oh_user" "$oh_password"; then
        echo "An error happend during auth creation in htpasswd, please check your syntax and try again."
    fi
    mkdir -p $oh_root_path/$oh_path
    eval "echo \"$auth_config\"" | sudo tee -a $oh_config_file > $NULL
}


function check_syntax(){
    if sudo nginx -t 2>&1 | grep -E "syntax is ok|test is successful"; then
        echo "Syntax and test are golden"
        return 0
    else
        echo "You should check your configuration file for any incorrect inputs"
        return 1
    fi
}


function restart_nginx(){
        read -p "Would you like to restart nginx [y/n]: " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            sudo service nginx restart
        elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
            echo "Restart was not required, exiting script"
            return 0
        else
            echo "Invalid input. Please enter y or n."
            return 1
        fi
}


function create_link(){
    oconfig=$1
    if check_syntax; then
        read -p "Would you like to create a symlink [y/n]: " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        ln -s "$oconfig" /etc/nginx/sites-enabled/
        echo "Symlink was created at /etc/nginx/sites-enabled/"
            elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
            echo "Creating a link was not required exiting script"
        else
            echo "Invalid input. Please enter y or n."
        fi
    else
        echo "Please check your coniguration file for any incorrect syntax link was not established"
    fi
}


function validate_ip(){
    local ip=$1
    local regex='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'

    if [[ $ip =~ $regex ]]; then
        oct1=${BASH_REMATCH[1]}
        oct2=${BASH_REMATCH[2]}
        oct3=${BASH_REMATCH[3]}
        oct4=${BASH_REMATCH[4]}
        if (( oct1 >= 0 && oct1 <= 255 )) && \
           (( oct2 >= 0 && oct2 <= 255 )) && \
           (( oct3 >= 0 && oct3 <= 255 )) && \
           (( oct4 >= 0 && oct4 <= 255 ))
           then
           return 0
        else
            echo "Invalid IP Address"
            return 1
        fi
    else
        echo "Invalid IP Address"
        return 1
    fi

    if grep -q "$ip" /etc/hosts; then
        echo "The IP address: $ip already exists in /etc/hosts"
        return 1
    fi
}


function add_domain_to_hosts (){
    local domain=$1
    local ip=""
    read -p "Do you want to add a domain to /etc/hosts (loopback address)? [y/n]: " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            if grep -q "$domain" /etc/hosts; then
                echo "The domain is already present in /etc/hosts."
                return 1
            else
                read -p "Enter the loopback address (example 127.0.0.1): " loopback_address
                if validate_ip $loopback_address; then
                    echo "$loopback_address $domain" | sudo tee -a /etc/hosts > /dev/null
                    echo "Domain '$domain' added to /etc/hosts with the address $loopback_address."
                else 
                    echo "There was an error in adding the record $loopback_address $domain to /etc/hosts"
                    return 1
                fi
            fi
        fi

}


function check_and_download_ssl(){
    local cert_file=$1
    local key_file=$2
    local ssl_dir=$(dirname "$key_file")
    if [[ ! -e $cert_file || ! -e $key_file ]]; then 
        read -p "Looks like the cert and key file don't exist, would you like to to create them? [y/n] " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            mkdir -p "$ssl_dir"
        if  openssl req -x509 -newkey rsa:4096 -keyout "$key_file" -out "$cert_file" -days 365 -nodes; then
            echo "SSL key and cery were created at keyfile: "$key_file" certfile: "$cert_file""
            return 0
       else
           echo "There was an error in crearing the key and cert files"
           return 1
       fi
           return 0
    elif [[ "$user_input" == "n" || "$user_input" == "N" ]]; then
        return 1
    else 
        echo "Invalid input [y/n]"
        return 1
    fi
       echo "The cert and key file already exist"
    fi
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
