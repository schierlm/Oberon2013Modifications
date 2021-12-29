#!/bin/sh
set -e

wget -nc https://github.com/schierlm/Oberon2013Modifications/releases/download/2020.05/CommandLineCompiler.zip

for i in MenuViewers Rectangles Curves Draw MacroTool ORS PCLink1 ORTool; do
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
for i in *.txt debug/*.txt rescue/*.txt debugrescue/*.txt; do unix2mac $i; mv $i ${i%.txt}; done

unzip ../CommandLineCompiler.zip
gcc main.c disk.c risc.c risc-fp.c -o risc

cp base.dsk mods.dsk
: > .cmds
for i in *.Mod *.Text *.Tool; do echo +$i >> .cmds; done
./risc mods.dsk < .cmds
head -n 4 ../BuildModifications.Tool.txt > .cmds
./risc mods.dsk < .cmds
head -n -6 ../BuildModifications.Tool.txt | tail -n +6 > .cmds
echo 'ORP.Compile CommandLineSystem.Mod OberonX.Mod PCLink1.Mod ~' >> .cmds
./risc mods.dsk < .cmds
cp mods.dsk mods0.dsk
echo 'ORP.Compile DefraggerX.Mod/s ~' > .cmds
echo 'System.DeleteFiles OberonX.Mod DefraggerX.Mod ~' >> .cmds
echo 'Defragger.Load' >> .cmds
echo 'ORP.Compile Oberon.Mod Defragger.Mod/s ~' >> .cmds
echo 'Defragger.Defrag' >> .cmds
./risc mods.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh mods.dsk
mv mods.dsk_trimmed OberonModifications.dsk

cd rescue
echo 'ORP.Compile Oberon.Mod ~' > .cmds
echo 'System.RenameFiles Oberon.rsc => Oberon.rsc.RS ~' >> .cmds
for i in *; do echo +$i >> .cmds; done
echo 'ORP.Compile RescueSystemTool.Mod/s RescueSystemLoader.Mod/s OberonX.Mod ~' >> .cmds
echo 'ORP.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'ORL.Load Modules.bin ~' >> .cmds
echo 'RescueSystemTool.MoveFilesystem' >> .cmds
../risc ../mods0.dsk < .cmds
sed 's/Modules.Load("System"/Modules.Load("CommandLineSystem"/' <Oberon.Mod >OberonX.Mod
echo '+OberonX.Mod' > .cmds
echo 'ORP.Compile Modules.RS.Mod Fonts.Embedded.Mod System.RS.Mod ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'System.RenameFiles Modules.bin => Modules.bin.RS Fonts.rsc => Fonts.rsc.RS System.rsc => System.rsc.RS ~' >> .cmds
echo 'ORP.Compile Modules.Mod Fonts.Mod System.Mod OberonX.Mod ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'System.CopyFiles Input.rsc => Input.rsc.RS Display.rsc => Display.rsc.RS Viewers.rsc => Viewers.rsc.RS' \
     'Texts.rsc => Texts.rsc.RS MenuViewers.rsc => MenuViewers.rsc.RS TextFrames.rsc => TextFrames.rsc.RS' \
     'Edit.rsc => Edit.rsc.RS PCLink1.rsc => PCLink1.rsc.RS Clipboard.rsc => Clipboard.rsc.RS' \
     'ORS.rsc => ORS.rsc.RS ORB.rsc => ORB.rsc.RS ORG.rsc => ORG.rsc.RS ORP.rsc => ORP.rsc.RS ORL.rsc => ORL.rsc.RS ~' >> .cmds
echo 'RescueSystemTool.LoadRescue' >> .cmds
echo 'System.DeleteFiles Fonts.Embedded.Mod Modules.RS.Mod System.RS.Mod ~' >> .cmds
../risc ../mods0.dsk < .cmds
cd ..
./risc mods0.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh mods0.dsk
mv mods0.dsk_trimmed OberonModificationsWithRescue.dsk

mv debug/* .
cp base.dsk dbgmods.dsk
: > .cmds
for i in *.Mod *.Text *.Tool; do echo +$i >> .cmds; done
./risc dbgmods.dsk < .cmds
head -n 4 ../BuildModifications.Tool.txt > .cmds
./risc dbgmods.dsk < .cmds
grep -v 'DEBUG VERSION ONLY' ../BuildModifications.Tool.txt | tail -n +6 | sed 's#/s#/s/d#g' > .cmds
echo 'ORP.Compile CommandLineSystem.Mod/s/d OberonX.Mod PCLink1.Mod/s/d ~' >> .cmds
./risc dbgmods.dsk < .cmds
cp dbgmods.dsk dbgmods0.dsk
echo 'ORP.Compile DefraggerX.Mod/s ~' > .cmds
echo 'System.DeleteFiles OberonX.Mod DefraggerX.Mod ~' >> .cmds
echo 'Defragger.Load' >> .cmds
echo 'ORP.Compile Oberon.Mod/s/d Defragger.Mod/s/d ~' >> .cmds
echo 'Defragger.Defrag' >> .cmds
./risc dbgmods.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh dbgmods.dsk
mv dbgmods.dsk_trimmed OberonModificationsDebug.dsk

rm rescue/OberonX.Mod
mv debugrescue/* rescue
cd rescue
echo 'System.RenameFiles Oberon.Mod => OberonY.Mod ~' > .cmds
for i in *; do echo +$i >> .cmds; done
echo 'ORP.Compile RescueSystemTool.Mod/s/d RescueSystemLoader.Mod/s/d OberonX.Mod/d ~' >> .cmds
echo 'ORP.Compile Kernel.Mod/d FileDir.Mod/d Files.Mod/d Modules.Mod/d ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'ORL.Load Modules.bin ~' >> .cmds
echo 'RescueSystemTool.MoveFilesystem' >> .cmds
../risc ../dbgmods0.dsk < .cmds
sed 's/Modules.Load("System"/Modules.Load("CommandLineSystem"/' <Oberon.Mod >OberonX.Mod
echo '+OberonX.Mod' > .cmds
echo 'ORP.Compile Modules.RS.Mod Fonts.Embedded.Mod/s Texts.Mod/s OberonY.Mod/s ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'ORP.Compile MenuViewers.Mod/s TextFrames.Mod/s System.RS.Mod/s Edit.Mod/s ORL.Mod/s ~' >> .cmds
echo 'ORP.Compile ORS.Mod/s ORB.Mod/s ~' >> .cmds
echo 'ORP.Compile ORG.Mod/s ORP.Mod/s ~' >> .cmds
echo 'System.RenameFiles Modules.bin => Modules.bin.RS Fonts.rsc => Fonts.rsc.RS' \
     'Texts.rsc => Texts.rsc.RS MenuViewers.rsc => MenuViewers.rsc.RS' \
     'TextFrames.rsc => TextFrames.rsc.RS Edit.rsc => Edit.rsc.RS' \
     'System.rsc => System.rsc.RS Oberon.rsc => Oberon.rsc.RS ORL.rsc => ORL.rsc.RS' \
     'ORS.rsc => ORS.rsc.RS ORB.rsc => ORB.rsc.RS ORG.rsc => ORG.rsc.RS ORP.rsc => ORP.rsc.RS ~' >> .cmds
echo 'ORP.Compile Modules.Mod/d Fonts.Mod/s/d Texts.Mod/s/d OberonX.Mod/s/d ~' >> .cmds
echo 'ORP.Compile MenuViewers.Mod/s/d TextFrames.Mod/s/d System.Mod/s/d Edit.Mod/s/d ORL.Mod/s/d ~' >> .cmds
echo 'ORP.Compile ORS.Mod/s/d ORB.Mod/s/d ~' >> .cmds
echo 'ORP.Compile ORG.Mod/s/d ORP.Mod/s/d ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'System.CopyFiles Input.rsc => Input.rsc.RS Display.rsc => Display.rsc.RS Viewers.rsc => Viewers.rsc.RS' \
     'PCLink1.rsc => PCLink1.rsc.RS Clipboard.rsc => Clipboard.rsc.RS'  >> .cmds
echo 'RescueSystemTool.LoadRescue' >> .cmds
echo 'System.DeleteFiles Fonts.Embedded.Mod OberonY.Mod Modules.RS.Mod System.RS.Mod ~' >> .cmds
../risc ../dbgmods0.dsk < .cmds
cd ..
./risc dbgmods0.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh dbgmods0.dsk
mv dbgmods0.dsk_trimmed OberonModificationsDebugWithRescue.dsk

cd ..

echo Done.
