#!/bin/bash

# set -x


source ./creating-venv.sh

path_to_this_catalog=$(dirname $(realpath -s $0))
path_to_tests=$HOME/qa_tests
path_to_web_tests=$path_to_tests/ci_qa_web
path_to_cli_tests=$path_to_tests/ci_qa_cli
path_to_files_for_analysis=$path_to_tests/files_for_analysis
geckodriver=https://github.com/mozilla/geckodriver/releases/download/v0.31.0/geckodriver-v0.31.0-linux64.tar.gz
geckodriver_name=geckodriver-v0.31.0-linux64.tar.gz
path_to_standart_results=$path_to_this_catalog/results_analysis.json
path_to_allure_reports=$path_to_tests/AllureReports


ERROR_DOWNLOAD_FILES=false
RUN_TESTS=false
RUN_WEB=false
RUN_CLI=false
RUN_BENCH=false
LOCAL_RUN=false
ARHIVES=(test_cpp.zip test_cpp.probed.zip test_cs.zip test_cs.probed.zip test_java.zip test_java.probed.zip)
USE_VENV=true
UI_TESTS=false
CLI_TESTS=false
AVS_SERVER=
SELENIUM_SERVER=
BENCH_SERVER=
HEADLESS=
VIRTUAL_MACHINE=
USERNAME="echelon"
USERPASS="ospass"
DELETE_REPORTS=false
PREPARE_OS=false
STNDR_RESULT=true
CLONE_REPO=true

#COLORS:
RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
YELLOW_COLOR='\033[0;33m'
COLOR_OFF='\033[0m'



print_help() {
	echo " 
	Запуск: ./launch-qa-tests.sh [--prepare-os] [--standart-result]
	
	или

	Запуск: ./launch-qa-tests.sh [--use-venv=VALUE] [--ui-tests] [--cli-tests]
	[--server=VALUE] [--virtual-machine=VALUE] [--selenium-server=VALUE]
	[--local-run] [--username=VALUE] [--userpass=VALUE]
	[--delete-last-report=VALUE] [--standart-result]
	[--username=VALUE] [--userpass=VALUE] [--delete-last-report=VALUE]
	Ключ --prepare-os подготавливает машину для тестов:
	                  1. Клонирует тесты
	                  2. Устанавливает ВебДрайвер
	                  3. Устанавливает Алюр
	                  3. Устанавливает Венв
	Ключ --run-web - запустит ui тесты
	    (можно использовать с --cli-tests ключом)
	Ключ --run-cli - запустит cli тесты
	    (можно использовать с --ui-tests ключом)
	Ключ --avs-server=[VALUE] - указывает ip:port сервера АВС,
	     по умолчанию: 127.0.0.1:11000 (используется для ui-tests и cli-tests)
	Ключ --virtual-machine - указывает ip виртуальной машины
	     на которой будут выполняться тесты, поддерживает ввод как одного
	     значения: --virtual-machine=192.168.0.1, так и нескольких:
	     --virtual-machine=192.168.0.1,192.168.0.2 (через ',')
	     по умолчанию: 127.0.0.1 (используется для ui-tests и cli-tests)
	Ключ --selenium-server=[VALUE] - ip:port selenium сервера запущенного на
	     виртуальной машине, по умолчанию: --virtual-machine:4444
	     (используется для ui-tests и cli-tests)
	Ключ --local-run - указывает на запуск тестов локально
	Ключ --username - указывает Логин пользователя Linux для авторизации
	     при подключении по ssh,
	     по умолчанию echelon (используется только для cli-tests)
	Ключ --userpass - указывает Пароль пользователя Linux для авторизации при
	     подключении по ssh,
	     по умолчанию echelon ospass (используется только для cli-tests)
	Ключ --delete-last-report - если =1 удаляет предыдущий сохраненый отчет
	     Allure перед запуском тестов
	     по умолчанию =0
	Ключ --standart-result - сохраняет стандартные результаты в ~/
	     для сравнения во время тестов с полученным результатом

	Пример команды:

	./launch-qa-tests.sh --run-web --run-cli --avs-server=127.0.0.1:11000
	--virtual-machine=192.168.122.1 --selenium-server=192.168.122.1:4444
	--username=Admin --userpass=Admin

	Перед запуском тестов будут проверены на существования каталоги
	ci_qa_web и ci_qa_cli"
}

check_arguments() {


	if [[ "$1" == *"run"* ]]; then
		RUN_TESTS=true
	fi


	if [ "$1" == "--delete-last-reports" ]; then
		DELETE_REPORTS=true
		# echo "$1"    

	elif [[ "$1" == *"avs-server"* ]]; then
		AVS_SERVER=${1:14}
		echo $AVS_SERVER	

	elif [[ "$1" == *"--selenium-server"* ]]; then
		SELENIUM_SERVER=${1:18}
		echo "$1" 	

	elif [[ "$1" == "--headless" ]]; then
	    	HEADLESS=true   

	elif [[ "$1" == *"--virtual-machine"* ]]; then
		VIRTUAL_MACHINE=${1:18}
		echo "$1"  

	elif [[ "$1" == *"--username"* ]]; then
		USERNAME=${1:11}
		echo "$1"    
	    
	elif [[ "$1" == *"--userpass"* ]]; then
		USERPASS=${1:11}
		echo "$1" 

	elif [[ "$1" == *"--bench-server"* ]]; then
		BENCH_SERVER=${1:20}
		echo "$1" 

	elif [ "$1" == "--prepare-os" ]; then
		PREPARE_OS=true
		# echo "$1"    
	    
	elif [ "$1" == "--standart-result=false" ]; then
		STNDR_RESULT=false
		# echo "$1" 
	    
	elif [ "$1" == "--clone-repo=false" ]; then
		CLONE_REPO=false
		# echo "$1"

	elif [ "$1" == "--run-web" ]; then
		RUN_WEB=true

	elif [ "$1" == "--run-cli" ]; then
		RUN_CLI=true

	elif [ "$1" == "--run-bench" ]; then
		RUN_BENCH=true

	elif [ "$1" == "--local-run" ]; then
		LOCAL_RUN=true

	else
	    echo "$1"
		echo -e " \nUnknown argument: $1";
		exit;
	fi
}
# check_type_tests() {
# 	if [ $UI_TESTS == "0" ] && [ $CLI_TESTS == "0" ]; then
# 		if [ $PREPARE_OS == "0" ]; then
# 			echo "Не указан вид теста (или prepare_os)! Подробнее: --help"
# 			exit 0
# 		fi
		
# 	fi
# }

print_error_and_die() {
	echo -e "\n\n${RED_COLOR}$1${COLOR_OFF}"
	exit 1
}

print_warning() {
	echo -e "\n\n${YELLOW_COLOR}$1${COLOR_OFF}\n"
}

print_successful() {
	echo -e "${GREEN_COLOR}$1${COLOR_OFF}"
}

add_standart_results() {
	if $STNDR_RESULT; then
		echo -e "\nДобавляю стандартные результаты...\n"
		cp $path_to_standart_results $path_to_tests
	fi
}

check_installed_git() {
	if ! git --version 2>/dev/null; then
		confirm "Для клонирования репозитория требуется git, установить?"
		if [[ $confirm_return_reply == "y" ]]; then
			echo "Устанавливаю git. Логи перенаправлены в common/logs_install.txt"
			sudo apt -y install git >> logs_install.txt
			echo "Проверяю установленную версию:"
			check_installed_git
		else 
			print_warning "Пропускаю установку GIT..."
			git_install=false
		fi
	else
		git_install=true
	fi
}

check_connected_gitlab() {
	echo "Попытка подключения к git@gitlab.echelon.lan ..."	
	info=$(ssh -o BatchMode=yes -o ConnectTimeout=5 git@gitlab.echelon.lan)

	if [[ $info == *"Welcome"* ]] ; then
  		print_successful "Удачно"
  		connect_to_git=true
	else
		print_warning "Ошибка во время подключения к git@gitlab.echelon.lan"
		connect_to_git=false	
	fi
}

delete_past_reports() {
	if $DELETE_REPORTS; then
		echo "Удаляю прошлый отчет..."
		sudo rm -R $path_to_reportAllure	
	fi
}

clone_repo_from_git() {
	if $CLONE_REPO; then
		echo "Клонирую репозитории с git..."
		check_installed_git
		if $git_install; then
			check_connected_gitlab
			if $connect_to_git; then
				rm -rf $path_to_tests
				mkdir $path_to_tests
				echo -e "\nКлонирую в $path_to_tests:\nКлонирую ci_qa_cli ...\n"
				git clone 
				echo -e "\nКлонирую ci_qa_web ...\n"
				git clone 
			else 
				print_warning "Не удалось подключится к git@gitlab.echelon.lan Проверьте соединение и повторите попытку"
				confirm "Завершить работу скрипта?l"
				if [[ $confirm_return_reply == "y" ]]; then
					exit 1
				else
					print_warning "Пропускаю клонирование репозиториев"
					mkdir $path_to_tests 
				fi
				
			fi
		else
			print_warning "Git не был установлен. Пропускаю клонирование репозиториев..."
		fi
	fi
}

install_curl() {
	I=`dpkg-query -W --showformat='${Status}' curl | grep "install ok installed" `
	if [ -z "$I" ]; then
		confirm "curl не найден. Необходим для скачивания файлов для анализа. Установить?"
		if [[ $confirm_return_reply == "y" ]]; then
		 	echo "Устанавливаю curl. Логи перенаправлены в common/logs_install.txt"
			sudo apt-get -y install curl >> logs_install.txt
			install_curl
			curl_install=true
		else 
			print_warning "Curl не был установлен"
			curl_install=false
		fi
	else
		print_successful "Curl установлен."
		curl_install=true
	fi
}

download_files_for_analysis() {
	if [ ! -d $path_to_files_for_analysis ]; then
		print_warning "Не найдена директория с файлами для анализа. Скачиваю..."
		install_curl		
		if $curl_install; then
			echo -e "\nСкачиваю архивы в $path_to_files_for_analysis"
			mkdir $path_to_files_for_analysis
			for item in ${ARHIVES[*]}
			do
			    echo $item
			    curl -u avs
			    if [[ ! -f $path_to_files_for_analysis/$item ]]; then
			    	ERROR_DOWNLOAD_FILES=true
			    fi
			done
			if ERROR_DOWNLOAD_FILES; then
				print_warning "Один или несколько файлов для анализа не были скачаны. Повторите попытку вручную"
			fi
		else
			print_warning "Пропускаю скачивани файлов для анализа"
		fi
	
	fi
}

create_venv() {
	check_version_python
	if $install_python; then
		install_venv $path_to_tests/venv
		if [[ -n $python_venv ]]; then
			install_requirements $path_to_web_tests/requirements.txt $path_to_cli_tests/requirements.txt
			print_successful "\nVENV успешно развернут"
		else
			print_warning "VENV не был развернут, требуется установить вручную."
		fi
	fi
}

download_webdriver() {
	echo -e "Скачиваю WebDriver. Логи перенаправлены в common/logs_install.txt\n\n"
	wget $geckodriver >> logs_install.txt
	mkdir -p webdriver && tar -C webdriver -xvf $geckodriver_name

	for item in "$path_to_web_tests" "$path_to_cli_tests"
	do
		if [[ -d $item ]]; then
			rm -Rf $item/webdriver
			cp -r webdriver $item

		fi
	done

	rm -rf webdriver geckodriver-v0.31.0-linux64.tar.gz
}

download_allure() {
	if ! dpkg -s allure 2>/dev/null; then
	   print_warning "Необходимо установить Allure..."	   
	   if ! java -version 2>/dev/null; then
	   	print_warning "Устанавливаю Java8 для работы с Allure. Логи перенаправлены в common/logs_install.txt"
		sudo apt -y install openjdk-8-jdk >> logs_install.txt
	   fi
	   echo -e "\nУстановка Allure:"
	   wget https://github.com/allure-framework/allure2/releases/download/2.19.0/allure_2.19.0-1_all.deb
	   sudo  dpkg -i allure_2.19.0-1_all.deb
	   rm -R allure_2.19.0-1_all.deb
	   print_successful "Установлено..."
	fi
}


finish_print() {
	print_successful "Подготовка ОС завершена."
}


confirm() {
	declare -r message=$1
	declare -r default=${2-y}
	confirm_return_reply=''

	declare reply="${default}"

	if [[ "${QUIET-}" != "1" ]]; then
	read -r -e -p "$message [y/n]: " -i "$default" reply
	while [[ "$reply" != "n" ]] && [[ "$reply" != "y" ]]; do
	  read -r -e -p "Ответом может быть только 'y' или 'n'. Повторите ввод: " -i "$default"
	done
	fi

	confirm_return_reply="$reply"
} 

get_ip_from_machine() {
	machine_info="$(virsh -c qemu:///system domifaddr $1 | grep 192*)"
	only_network_info=(${machine_info// / })
	ip_and_port=${only_network_info[3]}
	ip_add=${ip_and_port::-3}
	echo $ip_add
}

"$@"