#!/bin/bash

 # set -x


source ./functions.sh


if [[ $1 == *"help"* ]]; then
	print_help
	exit 0
fi

for ((i=1; i <= "$#"; ++i))
	do
		check_arguments ${!i}
	done

if $PREPARE_OS; then

	# check_type_tests
	clone_repo_from_git
	add_standart_results
	delete_past_reports
	download_webdriver
	download_files_for_analysis
	create_venv
	download_allure
	finish_print

elif $RUN_TESTS; then

	if [[ ! -d $path_to_web_tests ]] && [[ ! -d $path_to_cli_tests ]]; then
		print_error_and_die "Не найдены тесты в каталоге $path_to_tests.\nНеобходимо выолнить ./launch-qa-tests.sh --prepare-os"
	fi

	if [[ ! -f $path_to_web_tests/webdriver/geckodriver ]] && [[ ! -f $path_to_cli_tests/webdriver/geckodriver ]]; then
		print_error_and_die "WebDriver не обнаружен в $path_to_web_tests и(или) в $path_to_web_tests.\nНеобходимо выполнить ./launch-qa-tests.sh --prepare-os"
	fi

	if [[ -f $path_to_tests/venv/bin/python ]]; then
		python_venv=$python_venv_catalog/python
	else
		print_error_and_die "VENV не найден в каталоге $path_to_tests\nНеобходимо выполнить ./launch-qa-tests.sh --prepare-os"
	fi
	

	if [[ -n $AKVS_SERVER ]]; then
		AKVS_SERVER="--akvs-server=$AKVS_SERVER"
		echo "$AKVS_SERVER"
	fi


	if $RUN_WEB; then

		if $LOCAL_RUN; then
			if [[ -n $HEADLESS ]]; then
				HEADLESS="--headless"
			fi
			$path_to_tests/venv/bin/python -m pytest -sv -m web $path_to_web_tests $AKVS_SERVER --local-run $HEADLESS --alluredir=$path_to_allure_reports

		elif [[ -n $SELENIUM_SERVER ]]; then
			$path_to_tests/venv/bin/python -m pytest -sv -m web $path_to_web_tests $AKVS_SERVER --selenium-server=$SELENIUM_SERVER --alluredir=$path_to_allure_reports

		else
			print_warning "Для web-тестов нужно указать один из вариантов: --local-run или --selenium-server=VALUE \nПодробнее: ./launch-qa-tests.sh --help"

		fi
	fi

	if $RUN_CLI; then
		if $LOCAL_RUN; then
			$path_to_tests/venv/bin/python -m pytest -sv $path_to_cli_tests $AKVS_SERVER --local-run --alluredir=$path_to_allure_reports
		elif [[ -n $VIRTUAL_MACHINE ]] && [[ -n $SELENIUM_SERVER ]]; then
			$path_to_tests/venv/bin/python -m pytest -sv $path_to_cli_tests $AKVS_SERVER --virtual-machine=$VIRTUAL_MACHINE --username=$USERNAME --userpass=$USERPASS --selenium-server=$SELENIUM_SERVER --alluredir=$path_to_allure_reports
		else
			print_warning "Для cli-тестов нужно указать один из вариантов: --local-run или --virtual-machine=VALUE и --selenium-server=VALUE \nПодробнее: ./launch-qa-tests.sh --help"
		fi
	fi

	if $RUN_BENCH; then
		if [[ -n $BENCH_SERVER ]]; then
			if [[ -n $HEADLESS ]]; then
				HEADLESS="--headless"
			fi
			path_to_tests/venv/bin/python -m pytest -sv -m bench $AKVS_SERVER --local-run $HEADLESS --bench-server=$BENCH_SERVER --selenium-server=$SELENIUM_SERVER --alluredir=$path_to_allure_reports -
		else
			print_warning "Для эшелониум-тестов требуется указать --BENCH-server=VALUE\nПодробнее ./launch-qa-tests.sh --help"
		fi
	fi

else
	print_error_and_die "Необходимо указать один из вариантов запуска:\n--prepare-os Для подготовки системы (необходимо выполнить перед запуском тестов)\n--run-web, --run-cli или --run-bench\nПодробнее: ./launch-qa-tests.sh --help"
fi
