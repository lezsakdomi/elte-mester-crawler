#!/bin/bash -x
set -eufo pipefail
source secret.sh # Export your JSESSIONID there

req(){
	curl --insecure -X POST -b "JSESSIONID=$JSESSIONID" "$@"
}

gettemaviewstate(){
	req https://mester.inf.elte.hu/faces/tema.xhtml | grep -oP 'id="j_id1:javax\.faces\.ViewState:0" value="\K[^"]+(?=")' | tail -n 1 | tr -d "\n"
}

tema(){
	result=$(req https://mester.inf.elte.hu/faces/tema.xhtml -d "form=form&javax.faces.ViewState=`gettemaviewstate`&form:j_idt16=választom&form:name=$1&form:temalist=$2")
	echo "$result" | (! grep javax_faces_developmentstage_messages >/dev/null 2>&1)
	export tema=$(echo "$result" | grep -oP '<h1>Felhasználó: .*, Téma: \K[^<]*(?=</h1>)')
	[ -n "$tema" ]
	mkdir -p "dl/$tema"

	echo "$result" | grep -oPz '(?s)(?<=<pre>).*(?=</pre>)' >"dl/$tema/leiras.txt"

	echo "$result"
}

ogetflist(){
	req https://mester.inf.elte.hu/faces/feladat.xhtml | gawk '
	BEGIN                                                                          { print "id\tfeladat\t(nehezseg)" }
	match($0, /<option value="([0-9]+)">[0-9]+. ﻿?(.*)( \*+)?<\/option>/, m)  { print m[1] "\t" m[2] "\t" m[3] }
	'
}

getflist(){
	if [ -f "dl/$tema/flist.tsv" ]; then
		cat "dl/$tema/flist.tsv"
	else
		ogetflist
	fi
}

flist(){
	ogetflist >"dl/$tema/flist.tsv"
}

getfeladatviewstate(){
	req https://mester.inf.elte.hu/faces/feladat.xhtml | grep -oP 'id="j_id1:javax\.faces\.ViewState:0" value="\K[^"]+(?=")' | tail -n 1 | tr -d "\n"
}

feladat(){
	# assuming $1 is number
	result=$(req https://mester.inf.elte.hu/faces/feladat.xhtml -d "form=form&javax.faces.ViewState=`getfeladatviewstate`&form:j_idt13=választom&form:name=$1")
	echo "$result" | (! grep javax_faces_developmentstage_messages >/dev/null 2>&1)
	export feladat=$(getflist | grep -oP "^$1\t\\K[^\t]+")
	[ -n "$feladat" ]
	mkdir -p "dl/$tema/$feladat"

	echo "$result"
}

getletoltviewstate(){
	req https://mester.inf.elte.hu/faces/letolt.xhtml | grep -oP 'id="j_id1:javax\.faces\.ViewState:0" value="\K[^"]+(?=")' | tail -n 1 | tr -d "\n"
}

letoltleiras(){
	req https://mester.inf.elte.hu/faces/letolt.xhtml -d "j_idt11=j_idt11&javax.faces.ViewState=`getletoltviewstate`&j_idt11:j_idt14=letölt&j_idt11:minta=pdf" >"dl/$tema/$feladat/feladat.pdf"
}

letoltminta(){
	req https://mester.inf.elte.hu/faces/letolt.xhtml -d "j_idt11=j_idt11&javax.faces.ViewState=`getletoltviewstate`&j_idt11:j_idt14=letölt&j_idt11:minta=zip" >"dl/$tema/$feladat/minta.zip"
}

eval "$@"
