#!/bin/sh
set -e
cd ..
rm -rf work
mkdir work

for i in Kernel FileDir Files Modules Input Display Viewers Fonts Texts Oberon MenuViewers TextFrames System Edit ORS ORB ORG ORP PCLink1; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work
	dos2unix work/$i.Mod.txt
done

cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/System.Tool.txt work
dos2unix work/System.Tool.txt

cp DefragmentFreeSpace/DefragFiles.Mod.txt DefragmentFreeSpace/Defragger.Mod.txt ORL.Mod.txt ReproducibleBuild/BuildTools.Mod.txt ReproducibleBuild/BuildReproducibly.Tool.txt work

patch -d work <ReproducibleBuild/ReproducibleDefragger.patch
patch -d work <ReproducibleBuild/ReproducibleORL.patch

cd work
for i in *.txt; do unix2mac $i; mv $i ${i%.txt}; done
tar --sort=name --mode="ugo-rwx" --mtime='1970-01-01' --owner=0 --group=0 --numeric-owner -cf oberon-reproducible.tar *.Mod *.Tool

echo 'de6837b84320e37fc2025fde8060b17aa0f688da266651e7b6976d8cb3875d50 *oberon-reproducible.tar' | sha256sum -c

cd ..

wget -nc https://github.com/schierlm/Oberon2013Modifications/releases/download/2020.05/CommandLineCompiler.zip

cd work
sed 's/Oberon.RetVal/0/' <../CommandLineCompiler/CommandLineSystem.Mod.txt >CommandLineSystem.Mod
mac2unix Oberon.Mod
sed 's/Modules.Load("System"/Modules.Load("CommandLineSystem"/' <Oberon.Mod >OberonX.Mod
unix2mac Oberon.Mod OberonX.Mod CommandLineSystem.Mod
mac2unix Defragger.Mod
mv Defragger.Mod Defragger.Mod.txt
patch <../CommandLineCompiler/CommandLineDefragger.patch
mv Defragger.Mod.txt Defragger.Mod
unix2mac Defragger.Mod

unzip ../CommandLineCompiler.zip
gcc main.c disk.c risc.c risc-fp.c -o risc

cp base.dsk work.dsk
: > .cmds
for i in *.Mod *.Tool; do echo +$i >> .cmds; done
./risc work.dsk < .cmds

head -n 4 ../ReproducibleBuild/BuildReproducibly.Tool.txt > .cmds
./risc work.dsk < .cmds

tail -n +6 ../ReproducibleBuild/BuildReproducibly.Tool.txt | head -n 16 > .cmds
echo 'ORP.Compile CommandLineSystem.Mod OberonX.Mod ~' >> .cmds
./risc work.dsk < .cmds

tail -n +25 ../ReproducibleBuild/BuildReproducibly.Tool.txt | head -n 22 | tr -d '\n' | \
  sed 's/~/ CommandLineSystem.rsc ~/' > .cmds
./risc work.dsk < .cmds
echo 'Defragger.Load' > .cmds
echo 'ORP.Compile Oberon.Mod ~' >> .cmds
echo 'System.DeleteFiles DefragFiles.rsc Defragger.rsc BuildReproducibly.Tool CommandLineSystem.rsc ~' >> .cmds
echo 'Defragger.Defrag' >> .cmds
./risc work.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh work.dsk
mv work.dsk_trimmed oberon-reproducible.dsk

echo '6c4d6e7dec9ee9b096a5d744e3a48757fd4dbb1545f81d31f4f6741c7430d1c6 *oberon-reproducible.dsk' | sha256sum -c

cd ..

echo Done.
