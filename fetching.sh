#!/bin/bash
set -eufo pipefail
source secret.sh # Export your JSESSIONID there

req(){
	curl --insecure -X POST -b "JSESSIONID=$JSESSIONID" "$@" | awk '
	BEGIN { status=0 }
	match($0, /<div id="error" class="grayBox" style="border: 1px solid #900;">([^<]+)<\/div>/, m) {
		print "\033[31mError occurred: " m[1] "\033[0m" > "/dev/stderr"; status=1; print
	}
	{print}
	END { exit status }
	'
}

gettemaviewstate(){
	req https://mester.inf.elte.hu/faces/tema.xhtml | grep -oP 'id="j_id1:javax\.faces\.ViewState:0" value="\K[^"]+(?=")' | tail -n 1 | tr -d "\n"
}

ogetszintlist(){
	req https://mester.inf.elte.hu/faces/tema.xhtml | awk '
	BEGIN { print "id\tszint" }
	/<select id="form:name"/,/<\/select>/ {
		if (match($0, /<option value="([0-9]+)"( selected="selected")?>(.*)<\/option>/, m)) { print m[1] "\t" m[3] }
	}
	'
}

szint(){
	result=$(req https://mester.inf.elte.hu/faces/tema.xhtml -d "form=form&form%3Aname=$1&form%3Atemalist=0&javax.faces.ViewState=`gettemaviewstate`&javax.faces.source=form%3Aname&javax.faces.partial.event=change&javax.faces.partial.execute=form%3Aname%20form%3Aname&javax.faces.partial.render=form%3Atemalist&javax.faces.behavior.event=change&javax.faces.partial.ajax=true")
	export szint=$(echo "$result" | grep -oP '<option value="[1-9][0-9]*" selected="selected">\K[^<]+(?=</option>)')
	echo "$result"
}

ogettemalist(){ # it requires szintID since it selects that
	szint $1 | gawk '
	BEGIN { print "id\tszint\ttema"; szint="'"${szint:-No szint captured}"'"; szintid="'"${1:-?}"'" }
	/<select id="form:name"/,/<\/select>/ {
		if (match($0, /<option value="([0-9]+)" selected="selected">(.*)<\/option>/, m)) {
			{ szintid=m[1]; szint=m[2] }
		}
	}
	/<select id="form:temalist"/,/<\/select>/ {
		if (match($0, /<option value="([0-9]+)">(.*)<\/option>/, m))
			{ print szintid " " m[1] "\t" szint "\t" m[2] }
	}
	'
}

ogetfulltemalist(){
	echo -e "id\tszint\ttema"
	while read szintid; do
		ogettemalist $szintid | tail -n +2
	done < <(ogetszintlist | tail -n +2 | cut -d$'\t' -f1)
}

getfulltemalist(){
	if [ -f "dl/temak.tsv" ]; then
		cat "dl/temak.tsv"
	else
		ogetfulltemalist
	fi
}

fulltemalist(){
	ogetfulltemalist >"dl/temak.tsv"
}

tema(){
	szint $1 >/dev/null
	result="$(req https://mester.inf.elte.hu/faces/tema.xhtml -d "form=form&javax.faces.ViewState=`gettemaviewstate`&form:j_idt16=választom&form:name=$1&form:temalist=$2")" || return 1
	echo "$result" | (! grep -oP '<ul id="javax_faces_developmentstage_messages".*<span>\s*\K.*(?=</span>)' 2>/dev/null) | (
		output=$(cat -)
		if [ -n "$output" ]; then
			echo -e "\033[31mUnhandled message: $output\033[0m"
		fi
	)
	export tema=$(echo "$result" | grep -oP '<h1>Felhasználó: .*, Téma: \K[^<]*(?=</h1>)')
	[ -n "$tema" ]
	mkdir -p "dl/$tema"

	echo "$result" | grep -oPz '(?s)(?<=<pre>).*(?=</pre>)' >"dl/$tema/leiras.txt"

	echo "$result"
}

t(){
	tema $1 $2 >/dev/null
}

ogetflist(){
	req https://mester.inf.elte.hu/faces/feladat.xhtml | gawk '
	BEGIN                                                                          { print "id\tfeladat\tnehezseg" }
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

f(){
	feladat $1 >/dev/null
}

getletoltviewstate(){
	req https://mester.inf.elte.hu/faces/letolt.xhtml | grep -oP 'id="j_id1:javax\.faces\.ViewState:0" value="\K[^"]+(?=")' | tail -n 1 | tr -d "\n"
}

letoltleiras(){
	req https://mester.inf.elte.hu/faces/letolt.xhtml -d "j_idt10=j_idt10&javax.faces.ViewState=`getletoltviewstate`&j_idt10:j_idt13=letölt&j_idt10:minta=pdf" >"dl/$tema/$feladat/feladat.pdf"
}

letoltminta(){
	req https://mester.inf.elte.hu/faces/letolt.xhtml -d "j_idt10=j_idt10&javax.faces.ViewState=`getletoltviewstate`&j_idt10:j_idt13=letölt&j_idt10:minta=zip" >"dl/$tema/$feladat/minta.zip"
}

letolt(){
	letoltleiras
	letoltminta
}

gettananyagviewstate(){
	req https://mester.inf.elte.hu/faces/tananyag.xhtml | grep -oP 'id="j_id1:javax\.faces\.ViewState:0" value="\K[^"]+(?=")' | tail -n 1 | tr -d "\n"
}

letoltmintafeladatleiras(){
	req https://mester.inf.elte.hu/faces/tananyag.xhtml -d "j_idt10=j_idt10&j_idt10:j_idt12=feladat+és+megoldása&javax.faces.ViewState=`gettananyagviewstate`" >"dl/$tema/mintafeladat.pdf"
}

letoltmintafeladatcpp(){
	req https://mester.inf.elte.hu/faces/tananyag.xhtml -d "j_idt10=j_idt10&j_idt10:j_idt13=C+++programkód&javax.faces.ViewState=`gettananyagviewstate`" >"dl/$tema/feladat.cpp"
}

letoltmintafeladatpas(){
	req https://mester.inf.elte.hu/faces/tananyag.xhtml -d "j_idt10=j_idt10&j_idt10:j_idt14=Pascal+programkód&javax.faces.ViewState=`gettananyagviewstate`" >"dl/$tema/feladat.pas"
}

if [ "$0" = "$BASH_SOURCE" ]; then
	if [ $# -eq 0 ]; then
		bash --init-file "$0" -x
	else
		eval "$@"
	fi
fi
