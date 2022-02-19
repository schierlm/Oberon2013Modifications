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

echo 'ea1de3ba621b0cf65b93d6f5a698324d4419a6af0d3e54226e59256de0b93413 *oberon-reproducible.tar' | sha256sum -c

cd ..

wget -nc https://github.com/schierlm/Oberon2013Modifications/releases/download/2020.05/CommandLineCompiler.zip

cd work
sed 's/Oberon.RetVal/0/' <../CommandLineCompiler/CommandLineSystem.Mod.txt >CommandLineSystem.Mod
cp ../CommandLineCompiler/CommandLineDefragger.Mod.txt CommandLineDefragger.Mod
cp System.Mod System.Mod.txt
mac2unix System.Mod.txt
patch <../StartupCommand/StartupCommand.patch
mv System.Mod.txt SystemX.Mod
echo '@Startup: CommandLineSystem.Run' >System0.Tool
unix2mac SystemX.Mod CommandLineSystem.Mod CommandLineDefragger.Mod System0.Tool

unzip ../CommandLineCompiler.zip
gcc main.c disk.c risc.c risc-fp.c -o risc

cp base.dsk work.dsk
: > .cmds
for i in *.Mod *.Tool; do echo +$i >> .cmds; done
./risc work.dsk < .cmds

head -n 4 ../ReproducibleBuild/BuildReproducibly.Tool.txt > .cmds
./risc work.dsk < .cmds

tail -n +6 ../ReproducibleBuild/BuildReproducibly.Tool.txt | head -n 16 > .cmds
echo 'ORP.Compile CommandLineSystem.Mod/s CommandLineDefragger.Mod SystemX.Mod ~' >> .cmds
echo 'System.RenameFiles System.Tool => System1.Tool System0.Tool => System.Tool ~' >> .cmds
./risc work.dsk < .cmds

tail -n +25 ../ReproducibleBuild/BuildReproducibly.Tool.txt | head -n 22 | tr -d '\n' | \
  sed 's/~/ CommandLineSystem.rsc CommandLineDefragger.rsc System1.Tool ~/' > .cmds
./risc work.dsk < .cmds
echo 'CommandLineDefragger.Load' > .cmds
echo 'ORP.Compile System.Mod ~' >> .cmds
echo 'System.RenameFiles System1.Tool => System.Tool ~' >> .cmds
echo 'System.DeleteFiles DefragFiles.rsc Defragger.rsc CommandLineDefragger.rsc BuildReproducibly.Tool CommandLineSystem.rsc ~' >> .cmds
echo 'CommandLineDefragger.Defrag' >> .cmds
./risc work.dsk < .cmds
../DefragmentFreeSpace/trim_defragmented_image.sh work.dsk
mv work.dsk_trimmed oberon-reproducible.dsk

echo '6c4d6e7dec9ee9b096a5d744e3a48757fd4dbb1545f81d31f4f6741c7430d1c6 *oberon-reproducible.dsk' | sha256sum -c

cd ..

echo Done.
