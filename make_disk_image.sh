#!/bin/sh
set -e

wget -nc https://github.com/schierlm/Oberon2013Modifications/releases/download/2020.05/CommandLineCompiler.zip

for i in Rectangles.Mod Curves.Mod Draw.Mod Draw.Tool MacroTool.Mod PCLink1.Mod ORTool.Mod; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.txt work/$i
	dos2unix work/$i
	unix2mac work/$i
done

cd work
echo '@Startup: CommandLineSystem.Run' >System0.Tool.txt
cp ../Clipboard.Mod.txt .
cp ../CommandLineCompiler/Comm*.Mod.txt .
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
echo 'ORP.Compile CommandLineSystem.Mod/s CommandLineDefragger.Mod PCLink1.Mod Clipboard.Mod ~' >> .cmds
echo 'System.RenameFiles System.Tool => System1.Tool System0.Tool => System.Tool ~' >> .cmds
./risc mods.dsk < .cmds
cp mods.dsk mods0.dsk
echo 'CommandLineDefragger.Load' > .cmds
echo 'System.DeleteFiles CommandLineDefragger.Mod CommandLineDefragger.rsc CommandLineSystem.Mod CommandLineSystem.rsc ~' >> .cmds
echo 'System.RenameFiles System1.Tool => System.Tool ~' >> .cmds
echo 'CommandLineDefragger.Defrag' >> .cmds
./risc mods.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh mods.dsk
mv mods.dsk_trimmed OberonModifications.dsk

cd rescue
echo 'System.RenameFiles Oberon.rsc => Oberon.rsc.RS ~' > .cmds
for i in *; do echo +$i >> .cmds; done
echo 'ORP.Compile RescueSystemTool.Mod/s RescueSystemLoader.Mod/s ~' >> .cmds
echo 'ORP.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod Oberon.Mod ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'ORL.Load Modules.bin ~' >> .cmds
echo 'RescueSystemTool.MoveFilesystem' >> .cmds
../risc ../mods0.dsk < .cmds
echo 'ORP.Compile Modules.RS.Mod Fonts.Embedded.Mod System.RS.Mod ~' > .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'System.RenameFiles Modules.bin => Modules.bin.RS Fonts.rsc => Fonts.rsc.RS System.rsc => System.rsc.RS ~' >> .cmds
echo 'System.RenameFiles DisplayM.rsc => DisplayM.rsc.RS DisplayC.rsc => DisplayC.rsc.RS ~' >> .cmds
echo 'ORP.Compile Modules.Mod Fonts.Mod System.Mod DisplayM.Mod DisplayC.Mod ~' >> .cmds
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
echo 'ORP.Compile CommandLineSystem.Mod/s/d CommandLineDefragger.Mod/s PCLink1.Mod/s/d Clipboard.Mod/s/d ~' >> .cmds
echo 'System.RenameFiles System.Tool => System1.Tool System0.Tool => System.Tool ~' >> .cmds
./risc dbgmods.dsk < .cmds
cp dbgmods.dsk dbgmods0.dsk
echo 'CommandLineDefragger.Load' > .cmds
echo 'System.DeleteFiles CommandLineDefragger.Mod CommandLineDefragger.rsc CommandLineSystem.Mod CommandLineSystem.rsc ~' >> .cmds
echo 'System.RenameFiles System1.Tool => System.Tool ~' >> .cmds
echo 'CommandLineDefragger.Defrag' >> .cmds
./risc dbgmods.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh dbgmods.dsk
mv dbgmods.dsk_trimmed OberonModificationsDebug.dsk

mv debugrescue/* rescue
cd rescue
echo 'System.RenameFiles Oberon.Mod => OberonY.Mod ~' > .cmds
for i in *; do echo +$i >> .cmds; done
echo 'ORP.Compile RescueSystemTool.Mod/s/d RescueSystemLoader.Mod/s/d ~' >> .cmds
echo 'ORP.Compile Kernel.Mod/d FileDir.Mod/d Files.Mod/d Modules.Mod/d ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'ORL.Load Modules.bin ~' >> .cmds
echo 'RescueSystemTool.MoveFilesystem' >> .cmds
../risc ../dbgmods0.dsk < .cmds
echo 'ORP.Compile Modules.RS.Mod Fonts.Embedded.Mod/s Texts.Mod/s OberonY.Mod/s ~' > .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'ORP.Compile MenuViewers.Mod/s TextFrames.Mod/s System.RS.Mod/s Edit.Mod/s Clipboard.Mod/s PCLink1.Mod/s ORL.Mod/s ~' >> .cmds
echo 'ORP.Compile ORS.Mod/s ORB.Mod/s ~' >> .cmds
echo 'ORP.Compile ORG.Mod/s ORP.Mod/s ~' >> .cmds
echo 'System.RenameFiles Modules.bin => Modules.bin.RS Fonts.rsc => Fonts.rsc.RS' \
     'Texts.rsc => Texts.rsc.RS MenuViewers.rsc => MenuViewers.rsc.RS' \
     'DisplayM.rsc => DisplayM.rsc.RS DisplayC.rsc => DisplayC.rsc.RS' \
     'TextFrames.rsc => TextFrames.rsc.RS Edit.rsc => Edit.rsc.RS Clipboard.rsc => Clipboard.rsc.RS' \
     'System.rsc => System.rsc.RS Oberon.rsc => Oberon.rsc.RS ORL.rsc => ORL.rsc.RS PCLink1.rsc => PCLink1.rsc.RS' \
     'ORS.rsc => ORS.rsc.RS ORB.rsc => ORB.rsc.RS ORG.rsc => ORG.rsc.RS ORP.rsc => ORP.rsc.RS ~' >> .cmds
echo 'ORP.Compile Modules.Mod/d DisplayM.Mod/s/d DisplayC.Mod/s/d Fonts.Mod/s/d Texts.Mod/s/d Oberon.Mod/s/d ~' >> .cmds
echo 'ORP.Compile MenuViewers.Mod/s/d TextFrames.Mod/s/d System.Mod/s/d Edit.Mod/s/d Clipboard.Mod/s/d PCLink1.Mod/s/d ORL.Mod/s/d ~' >> .cmds
echo 'ORP.Compile ORS.Mod/s/d ORB.Mod/s/d ~' >> .cmds
echo 'ORP.Compile ORG.Mod/s/d ORP.Mod/s/d ~' >> .cmds
echo 'ORL.Link Modules ~' >> .cmds
echo 'System.CopyFiles Input.rsc => Input.rsc.RS Display.rsc => Display.rsc.RS Viewers.rsc => Viewers.rsc.RS ~'  >> .cmds
echo 'RescueSystemTool.LoadRescue' >> .cmds
echo 'System.DeleteFiles Fonts.Embedded.Mod OberonY.Mod Modules.RS.Mod System.RS.Mod ~' >> .cmds
../risc ../dbgmods0.dsk < .cmds
cd ..
./risc dbgmods0.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh dbgmods0.dsk
mv dbgmods0.dsk_trimmed OberonModificationsDebugWithRescue.dsk

cd ..

echo Done.
