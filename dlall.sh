#!/bin/bash
set -eufo pipefail
source fetching.sh
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
	
	while read feladatid; do
		if [ ${SKIP_FELADAT:-0} -gt 0 ]; then
			echo "  (skipping feladat $feladatid)" >&2
			let SKIP_FELADAT--
			continue
		fi

		echo ">> Processing feladat $feladatid" >&2
		f $feladatid 2>/dev/null
		
		if [ ! -f "dl/$tema/$feladat/feladat.pdf" ]; then
			echo ">>> Downloading leiras" >&2
			letoltleiras 2>/dev/null
		else
			echo "    (leiras already downloaded)" >&2
		fi
		
		if [ ! -f "dl/$tema/$feladat/minta.zip" ]; then
			echo ">>> Downloading minta" >&2
			letoltminta 2>/dev/null
		else
			echo "    (minta already downloaded)" >&2
		fi
	done < <(getflist | tail -n +2 | cut -d$'\t' -f1)
done < <(cat temak.tsv | tail -n +2 | cut -d$'\t' -f1)
