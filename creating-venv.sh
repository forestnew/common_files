#!/bin/bash
# set -e





check_version_python() {
python_version_full=$(python3 --version)
python_version=${python_version_full:7:3}
if [[ $python_version == "3.7" ]] || [[ $python_version == "3.8" ]] || [[ $python_version == "3.9" ]] || [[ $python_version_full == *"3.10"* ]]; then
	echo "Версия Python - $python_version. Установка не требуется."
	install_python=true
	python_main=python3
else
    echo -e "\n\nТекущая версия Python -$python_version. Устанавливаю 3.8"
	echo "Установка требующихся компонентов. Логи перенаправлены в common/logs_install.txt"
	sudo apt -y install build-essential checkinstall >> logs_install.txt
	sudo apt -y install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev >> logs_install.txt
	sudo apt-get -y install python3-venv >> logs_install.txt
	echo "Устанавливаю Python. Логи перенаправлены в common/logs_install.txt"
	sudo apt -y install python3.8 >> logs_install.txt
	#sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
	python_main=python3.8
	version_check=$(python3.8 --version)
	if [[ $version_check == *"3.8"* ]]; then
		echo "Установка python3.8 завершена"
		install_python=true
	else
		echo "Python3.8 не был установлен. Требуется установка вручную"
		install_python=false
	fi
	
fi
}

install_venv() {
pt_venv=$1
echo -e "Разворачиваю venv.\nУстанавливаю $python_main-venv. Логи перенаправлены в common/logs_install.txt"
sudo apt-get -y install $python_main-venv >> logs_install.txt
echo "Устанавливаю в $pt_venv"
rm -rf $pt_venv
mkdir $pt_venv
$python_main -m venv $pt_venv
sudo chown -R $USER $pt_venv
python_venv_catalog=$pt_venv/bin
echo -e "\n\nУстанавливаю requirements. Логи перенаправлены в common/logs_install.txt"
$python_venv_catalog/pip install --upgrade pip >> logs_install.txt
$python_venv_catalog/pip install wheel >> logs_install.txt
if [[ -f $python_venv_catalog/python ]]; then
	python_venv=$python_venv_catalog/python
fi
}



install_requirements() {
for requirements in $1 $2
do
	echo "$requirements"
	if [ -f $requirements ]; then
		echo "Installing libraries from requirements.txt"
		$python_venv_catalog/pip install -r $requirements
	else
		echo "requirements was not found in $requirements"
	fi
done
}

