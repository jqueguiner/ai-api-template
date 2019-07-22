replace_in_file(){
        file=$1
        look_for=$2
        replace_with=$3
        replace_char_separator=$4

        if [ "$replace_char_separator" = "" ]; then
                replace_char_separator="/"
        fi;

        if [ "$file" = "Mac" ]; then
                sed -i '' "s$replace_char_separator$look_for$replace_char_separator$replace_with/g" $file
        else
                sed -i "s$replace_char_separator$look_for$replace_char_separator$replace_with$replace_char_separatorg/g" $file
        fi;
}

get_current_machine(){
        unameOut="$(uname -s)"
        case "${unameOut}" in
                Linux*)     machine=Linux;;
                Darwin*)    machine=Mac;;
                CYGWIN*)    machine=Cygwin;;
                MINGW*)     machine=MinGw;;
                *)          machine="UNKNOWN:${unameOut}"
        esac
        MACHINE=${machine}
}

get_current_machine

current_dir="${PWD##*/}"

usage="$(basename "$0") [-h] [-f i c p n] -- build and run your docker

where:
    -h  show this help text
    -f  set the dockerfile to build | default \"Dockerfile\"
    -i  interactive mode once docker is launched | default \"y\"
    -c  force no-cache mode for docker | default \"no\"
    -p  docker port | default 5000
    -n  nvidia-docker | default \"no\"
    "

dockerfile='Dockerfile'
interactive='y'
nocache=''
port=5000
nvidia='n'
while getopts ':hficpn:' option; do
	case "$option" in
		h) 	echo "$usage"
			exit
			;;
		f) 	dockerfile=$OPTARG
			;;
		i) 	interactive=$OPTARG
			;;
		c)	nocache=$OPTARG
			;;
		p)	port=$OPTARG
			;;
		n)	nvidia=$OPTARG
			;;
		:)	printf "missing argument for -%s\n" "$OPTARG" >&2
			echo "$usage" >&2
			exit 1
			;;
		\?)	printf "illegal option: -%s\n" "$OPTARG" >&2
			echo "$usage" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))


case $interactive in
	[yYoO]*)
		echo "Running in interactive mode"
		replace_in_file $dockerfile "ENTRYPOINT" "#ENTRYPOINT"
    		;;
	*)   
		replace_in_file $dockerfile "#ENTRYPOINT" "ENTRYPOINT"
		replace_in_file $dockerfile "#CMD" "CMD"
    		;;
esac

docker_name=$(echo $current_dir | awk '{print tolower($0)}')

case $nocache in
	[yYoO]*)
		echo "Building in no-cache mode"
		docker build -t $docker_name --no-cache -f $dockerfile .
		;;
	*)   
		docker build -t $docker_name -f $dockerfile .
		;;
esac

case $nvidia in
	[yYoO]*)
		echo "Running with nvidia-docker"
		nvidia-docker run -ipc=host -it -p $port:5000 $docker_name
		;;
	*)
		docker run -it -p $port:5000 $docker_name
		;;
esac



