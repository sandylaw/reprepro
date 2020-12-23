#!/bin/bash
#v1.0 by sandylaw

repos(){
	sudo cp -f ./repos.conf /etc/apache2/sites-available/repos.conf
	sudo cp -f ./000-default.conf /etc/apache2/sites-available/000-default.conf
	sudo systemctl daemon-reload
	sudo systemctl reload apache2.service
	cat /etc/apache2/sites-available/repos.conf
	cat /etc/apache2/sites-available/000-default.conf
}

oldrepos(){
 	sudo cp -f ./old_repos.conf /etc/apache2/sites-available/repos.conf
 	sudo cp -f ./old_000-default.conf /etc/apache2/sites-available/000-default.conf
 	sudo systemctl daemon-reload
 	sudo systemctl reload apache2.service
	cat /etc/apache2/sites-available/repos.conf
	cat /etc/apache2/sites-available/000-default.conf
}
echo "Change default repos sites to repos or old repos? "
echo "1  repos"
echo "2  oldrepos"
read -r idx

if [[ '1' == "$idx" ]]; then
	eval "repos"
elif [[ '2' == "$idx" ]]; then
	eval "oldrepos"
else
	echo "no choice,exit!"
	exit
fi
