#!/usr/bin/env sh

preconfig="./nas_config"
found_preconfig=0
nas_name=""
#fstab_file="/etc/fstab"
fstab_file="./fstab-test"
nas_conf_dir="$HOME/.config/cae-nas"
cred_file="$nas_conf_dir/nas_creds"

function readPreConfig() {
	if [ -f "$preconfig" ] || [ -n "$nas_name" ]; then
		echo "Found existing NAS config"
		source $preconfig
		found_preconfig=1
	fi
}

function getUserInfo() {
	if [ $found_preconfig -eq 0 ]; then
		read -p "Enter the NAS IP/Servername: " nas_name
	fi
	read -p "Enter your username: " user
	read -s -p "Enter your password: " pass
	echo ""
	read -p "Enter your domain: " domain
	printf "Does this look correct?\nUsername:%18s\nPassword:%18s\nDomain:%20s\nNAS:%23s\n[Yes/No]" \
		"$user" \
		"$pass" \
		"$domain" \
		"$nas_name"
	read confirmed
	case $confirmed in
		[yY]*)
			createCredentials $user $pass $domain
			addToFstab;;
		*)
			printf "Cancelled.\n"
			if [ $found_preconfig -eq 1 ]; then
				echo "Consider deleting/modifying your nas_config file"
			fi;;
	esac
}

function createCredentials() {
	if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -z "`grep /etc/fstab -e $nas_name 2>&1`" ]; then
		cat << EOF > $cred_file
username=$1
password=$2
domain=$3
EOF
	chmod 0600 $cred_file
	fi
}

function addToFstab() {
	printf "%s\t%s\tcifs\t_netdev,credentials=%s,dir_mode=0777,uid=0,gid=0 0 0\n"	\
		"$nas_name"	\
		"/cae_nas"	\
		"$cred_file"	#>> /etc/fstab

}

function main() {
	mkdir -p $nas_conf_dir
	readPreConfig
	getUserInfo 
	# internally calls createCredentials and addToFstab
	# exits here if successful
	exit 0
}

if [ -z "$nas_name" ]; then
	nas_name="//test-server"
fi

main
