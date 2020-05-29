#!/bin/sh
set -e

wget -nc https://github.com/schierlm/Oberon2013Modifications/releases/download/2020.05/CommandLineCompiler.zip

for i in Display Viewers MenuViewers Rectangles Curves Draw MacroTool ORS PCLink1 ORTool; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work/$i.Mod
	dos2unix work/$i.Mod
	unix2mac work/$i.Mod
done

cd work
sed 's/Modules.Load("System"/Modules.Load("CommandLineSystem"/' <Oberon.Mod.txt >OberonX.Mod.txt
cp Defragger.Mod.txt Defragger0.Mod.txt
patch <../CommandLineCompiler/CommandLineDefragger.patch
mv Defragger.Mod.txt DefraggerX.Mod.txt
mv Defragger0.Mod.txt Defragger.Mod.txt
cp ../Clipboard.Mod.txt .
for i in *.txt debug/*.txt; do unix2mac $i; mv $i ${i%.txt}; done

unzip ../CommandLineCompiler.zip
gcc main.c disk.c risc.c risc-fp.c -o risc

cp base.dsk mods.dsk
: > .cmds
for i in *.Mod *.Text *.Tool; do echo +$i >> .cmds; done
./risc mods.dsk < .cmds
head -n -6 ../BuildModifications.Tool.txt > .cmds
echo 'ORP.Compile CommandLineSystem.Mod OberonX.Mod ~' >> .cmds
./risc mods.dsk < .cmds
echo 'ORP.Compile DefraggerX.Mod/s ~' > .cmds
echo 'System.DeleteFiles OberonX.Mod DefraggerX.Mod ~' >> .cmds
echo 'Defragger.Load' >> .cmds
echo 'ORP.Compile Oberon.Mod Defragger.Mod/s ~' >> .cmds
echo 'Defragger.Defrag' >> .cmds
./risc mods.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh mods.dsk
mv mods.dsk_trimmed OberonModifications.dsk

mv debug/* .
cp base.dsk dbgmods.dsk
: > .cmds
for i in *.Mod *.Text *.Tool; do echo +$i >> .cmds; done
./risc dbgmods.dsk < .cmds
grep -v 'DEBUG VERSION ONLY' ../BuildModifications.Tool.txt | sed '5,$s#/s#/s/d#g' > .cmds
echo 'ORP.Compile CommandLineSystem.Mod/s/d OberonX.Mod ~' >> .cmds
./risc dbgmods.dsk < .cmds
echo 'ORP.Compile DefraggerX.Mod/s ~' > .cmds
echo 'System.DeleteFiles OberonX.Mod DefraggerX.Mod ~' >> .cmds
echo 'Defragger.Load' >> .cmds
echo 'ORP.Compile Oberon.Mod/s/d Defragger.Mod/s/d ~' >> .cmds
echo 'Defragger.Defrag' >> .cmds
./risc dbgmods.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh dbgmods.dsk
mv dbgmods.dsk_trimmed OberonModificationsDebug.dsk

cd ..

echo Done.
