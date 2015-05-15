#!/usr/bin/env zsh

function buildBench() {
	tmpi=""
	isep=""
	for i in a b c d e f g h i j ; do
		tmpj=""
		jsep=""
		for j in a b c d e f g h i j  ; do
			tmpk=""
			ksep=""
			for k in a b c d e f g h i j ; do
				tmpl=""
				lsep=""
				for l in a b c d e f g h i j ; do
					echo "det $i$j$k$l() :- <$(((RANDOM%999 + 1)/1000.0)),$(((RANDOM%999 + 1)/1000.0))>."
					tmpl="$tmpl $lsep $i$j$k$l"
					lsep=","
				done
				echo "nondet $i$j$k() :- $tmpl ."
				tmpk="$tmpk $ksep $i$j$k"
				ksep=","
			done
			echo "nondet $i$j() :- $tmpk ."
			tmpj="$tmpj $jsep $i$j"
			jsep=","
		done
		echo "nondet $i() :- $tmpj ."
		tmpi="$tmpi $isep $i"
		isep=","
	done
	echo "nondet bench() :- $tmpi ."
}

time (buildBench > bench.myc)
echo "Created benchmark"
export TIME="+%e"
i=0
ax=0
while [[ $i -lt 10 ]] ; do
	tmpTime=$( ( (time  (./mycroft.lua -t bench.myc > /dev/null)) 2>&1 ) | sed 's/^.* \([0-9.][0-9.]*\) total.*$/\1/' )
	ax=$((ax+tmpTime))
	i=$((i+1))
	echo -e ".\c"
done
echo
timeOff=$((ax/i))
echo "Offset for startup time: $timeOff"

echo "?- bench()." >> bench.myc

i=0
ax=0
while [[ $i -lt 10 ]] ; do
	tmpTime=$( ( (time  (./mycroft.lua -t bench.myc > /dev/null)) 2>&1 ) | sed 's/^.* \([0-9.][0-9.]*\) total.*$/\1/' )
	ax=$((ax+tmpTime))
	i=$((i+1))
	echo -e ".\c"
done
avg=$((ax/i))
echo "Average execution time: $avg"
avg=$((avg-timeOff))
echo "Average adjusted execution time: $avg"
avg=$(((10**4)/avg))
if [[ $(echo $avg | cut -d. -f 1) -gt 1000 ]] ; then
	if [[ $(echo $avg | cut -d. -f 1) -gt 1000000 ]] ; then
		avg=$((avg/1000000))M
	else
		avg=$((avg/1000))K
	fi
fi

echo "Benchmark: ${avg}LIPS"

