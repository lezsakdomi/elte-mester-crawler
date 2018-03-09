#!/bin/bash
set -eufo pipefail
source fetching.sh

echo "Fetching tema list" >&2
fulltemalist 2>/dev/null

while read temaid; do
	if [ ${SKIP_TEMA:-0} -gt 0 ]; then
		echo "  (skipping tema $temaid)" >&2
		let SKIP_TEMA--
		continue
	fi
	echo "> Processing tema $temaid" >&2
	t $temaid 2>/dev/null

	if [ ! -f "dl/$tema/flist.tsv" ]; then
		echo ">> Downloading flist" >&2
		flist 2>/dev/null
	else
		echo "   (flist already downloaded)" >&2
	fi

	if [ ! -f "dl/$tema/mintafeladat.pdf" ]; then
		echo ">> Downloading mintafeladat leiras" >&2
		if letoltmintafeladatleiras 2>/dev/null; then
			echo ">>> Converting to txt" >&2
			pdftotext -layout "dl/$tema/mintafeladat.pdf" || { echo -e "    > \033[41mFailed\033[0m"; >"dl/$tema/mintafeladat.txt"; }
		else
			echo -e "   > \033[41mFailed\033[0m" >&2; >"dl/$tema/mintafeladat.pdf"
		fi
	else
		echo "   (mintafeladatleiras already downloaded)" >&2
	fi

	if [ ! -f "dl/$tema/feladat.cpp" ]; then
		echo ">> Downloading mintafeladat C++ megoldas" >&2
		letoltmintafeladatcpp 2>/dev/null || { echo -e "   > \033[41mFailed\033[0m"; >"dl/$tema/feladat.cpp"; }
	else
		echo "   (mintafeladatcpp already downloaded)" >&2
	fi

	if [ ! -f "dl/$tema/feladat.pas" ]; then
		echo ">> Downloading mintafeladat pascal megoldas" >&2
		letoltmintafeladatpas 2>/dev/null || { echo -e "   > \033[41mFailed\033[0m"; >"dl/$tema/feladat.pas"; }
	else
		echo "   (mintafeladatpas already downloaded)" >&2
	fi
	
	while read feladatid; do
		if [ ${SKIP_FELADAT:-0} -gt 0 ]; then
			echo "  (skipping feladat $feladatid)" >&2
			let SKIP_FELADAT--
			continue
		fi

		tmpfeladat=$(getflist | grep -oP "^$feladatid"'\t\K[^\t]*')
		if [ -f "dl/$tema/$tmpfeladat/feladat.pdf" -a -f "dl/$tema/$tmpfeladat/feladat.txt" -a -f "dl/$tema/$tmpfeladat/minta.zip" ]; then
			echo "  (auto-skipping feladat $tmpfeladat)" >&2
			continue
		fi

		echo ">> Processing feladat $feladatid" >&2
		f $feladatid 2>/dev/null
		
		if [ ! -f "dl/$tema/$feladat/feladat.pdf" ]; then
			echo ">>> Downloading leiras" >&2
			if letoltleiras 2>/dev/null; then
				echo ">>>> Converting to txt" >&2
				pdftotext -layout "dl/$tema/$feladat/feladat.pdf" \
					|| { echo -e "     > \033[41mFailed\033[0m"; >"dl/$tema/$feladat/feladat.txt"; }
			else
				echo -e "   > \033[41mFailed\033[0m" >&2; >"dl/$tema/$feladat/feladat.pdf"
			fi
		else
			echo "    (leiras already downloaded)" >&2
		fi
		
		if [ ! -f "dl/$tema/$feladat/minta.zip" ]; then
			echo ">>> Downloading minta" >&2
			letoltminta 2>/dev/null || { echo -e "    > \033[41mFailed\033[0m"; >"dl/$tema/$feladat/minta.zip"; }
		else
			echo "    (minta already downloaded)" >&2
		fi
	done < <(getflist | tail -n +2 | cut -d$'\t' -f1)
done < <(getfulltemalist | tail -n +2 | cut -d$'\t' -f1)
