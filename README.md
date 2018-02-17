# ELTE's *MESTER online programozási feladatbank* crawler
This script is intended to download the data from the hardly usable <https://mester.inf.elte.hu> to make later processing easier.
It fills up the `dl` directory with the gathered data.

The included Makefile contains a rule for creating the `szintek` folder, which organises temas in szints using symlinks.

## Directory structure
The `dl` directory gets filled up with the following contents:
- `dl`
	- `temak.tsv`
	- *temaMegnevezes*
		- `leiras.txt`
		- `flist.tsv`
		- *feladatMegnevezes*
			- `feladat.pdf`
			- `minta.zip`
- `szintek`
	- *szintNev*
		- *temaMegnevezes* -> ../../dl/*temaMegnevezes*

## Usage
First of all, you need to create the `secret.sh` yourself.
To do this, follow this list:
1. Login on <https://mester.inf.elte.hu>
2. Press `F12`
3. Find the list of the cookies
4. Export your JSESSIONID in the `secret.sh`, like so:
	`export JSESSIONID=abc123ghijksomerandomdata185`

Otherwise, the `temak.tsv` should point to a valid file.
You have three options getting it:
* Download from *elte-mester-data*: `rm temak.tsv && wget https://raw.githubusercontent.com/lezsakdomi/elte-mester-data/master/temak.tsv`
* Clone the *elte-mester-data* (which eliminates the need for this repo): `git submodule update --init dl`
* Create by hand. Syntax: *kategoriaID*`space`*temaID*`tab`*kategoriaMegnevezes*`tab`*temaMegnevezes* with a one line header. (only the first field is required really)

### Manual
`fetching.sh` has a check whether it is sourced or invoked directly. Use that file for manual management.

#### Commands
Basically every function in `fetching.sh`, i'm listing here the endpoint-candidates:

| Function			| Purpose |
|:------------------------------|:--------|
| tema  *kategoriaID* *temaID*	| Set tema |
| t *tema*			| alias for `tema` (no output) |
| getflist			| Shows a feladat list |
| ogetflist			| Force a fresh, online version |
| flist				| (re-)Download `flist.txt` (feladat list) |
| feladat *feladatID*		| Set feladat in this tema |
| f *feladat*			| alias for `feladat` (no output) |
| letoltleiras			| (re-)Download `leiras.pdf` (the feladat itself) |
| letoltminta			| (re-)Download `minta.zip` (sample input/output) |
| letolt			| (re-)Download all files (both `leiras.pdf` and `minta.zip`) |

#### Command line usage
The `fetching.sh` could be invoked directly. In that case, it contains the following line near the end:
```
eval "$@"
```

So example invocation:
```
./fetching.sh "tema 2 24 && ogetflist"
```

For further details, see [the Commands section](#commands).

#### Interactive invocation
When the `fetching.sh` invoked without arguments, it drops a bash shell where you can run individual commands like in [argumented invocation](#command-line-usage).
See [Commands](#commands)

### Scripted
There's a `dlall.sh` given, which iterates over `dl/temak.tsv` and downloads each *feladat* in every *tema*.
It can be controlled with two environment variables: `SKIP_TEMA` and `SKIP_FELADAT`. When they are given, the script skips the first `SKIP_TEMA` *tema*, and continues the processing with the `$SKIP_TEMA+1`th. In the first *tema*, it skips `SKIP_FELADAT` pieces of *feladat*s.
