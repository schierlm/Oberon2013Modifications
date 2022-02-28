#!/bin/sh
set -e

rm -rf work
mkdir work
for i in Kernel FileDir Files Modules Fonts Input Display Viewers Texts Oberon MenuViewers TextFrames System Edit Graphics GraphicFrames ORS ORB ORG ORP BootLoad SCC RS232; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work
	dos2unix work/$i.Mod.txt
done
for i in ORS ORB ORG ORP; do
	cp work/$i.Mod.txt work/LSPh$i.Mod.txt
done
