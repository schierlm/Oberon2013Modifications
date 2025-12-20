#!/bin/sh
set -e
cd ..

./make_release.sh

for i in Blink Checkers Draw EBNF GraphTool Hilbert MacroTool Math Net ORC ORTool PCLink1 PIO Rectangles RISC Sierpinski SmallPrograms Stars Tools; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work
	dos2unix work/$i.Mod.txt
done
for i in Draw.Tool OberonSyntax.Text; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.txt work
	dos2unix work/$i.txt
done

cp DuskberonBuilder/SplashLogo.Pict DuskberonBuilder/System.Tool  DuskberonBuilder/BootLoad.Mod.txt work
cp CommandLineCompiler/CommandLineDefragger.Mod.txt CommandLineCompiler/CommandLineSystem.Mod.txt work
cp Clipboard.Mod.txt work

patch -d work <RemoveFloatingPoint/RealityLost.patch
patch -d work <RemoveFloatingPoint/SimpleSoftFloat.patch
patch -d work <RemoveFloatingPoint/UnrealisticPrecision.patch
patch -d work <DuskberonBuilder/Dusk.patch

cd work
rm -rf debug rescue debugrescue
for i in *.txt; do mv $i ${i%.txt}; done
mkdir -p fs/oberon/extra/draw fs/oberon/extra/unicode fs/oberon/extra/calc fs/data/osrc emul/src emul/extra
rm SeamlessResize.Mod Trappy.Mod RS232.Mod SCC.Mod Clock.Mod KeyTester.Mod
mv *Template.Text Emulator*.Mod LSPh*.Mod Image*.Mod ORFormatter.Mod ORHighlighter.Mod ResourceMonitor.Mod emul/extra
mv Emulator.Tool ImageBuilder.Tool LSPUtil.* emul/extra

rm *.orig
cp *.Mod *.Text *.Tool *.Pict emul/src
sed '1,5d' <BuildModifications.Tool >emul/build2.cmds.txt
echo 'ORP.Compile CommandLineSystem.Mod/s CommandLineDefragger.Mod PCLink1.Mod Clipboard.Mod ~' >>emul/build2.cmds.txt
echo 'System.RenameFiles System.Tool => System1.Tool System0.Tool => System.Tool ~' >>emul/build2.cmds.txt

cp emul/extra/ImageTool.Mod fs/oberon/imagetoo.mod
cp emul/extra/ImageFileDir.Mod fs/oberon/imfiledi.Mod
cp emul/extra/ImageFiles.Mod fs/oberon/imfiles.mod
cp emul/extra/ImageKernel.Mod fs/oberon/imkernel.mod
cp ORS.Mod fs/oberon/ors.mod
cp ORB.Mod fs/oberon/orb.mod
cp ORG.Mod fs/oberon/org.mod
cp ORP.Mod fs/oberon/orp.mod
cp ORL.Mod fs/oberon/orl.mod
cp ../DuskberonBuilder/compile.ort fs/oberon/compile.ort

patch -p0 -d fs <../DuskberonBuilder/Duskberon.patch

mv Kernel.Mod          fs/data/osrc/kernel.mod
mv FileDir.Mod         fs/data/osrc/filedir.mod
mv Files.Mod           fs/data/osrc/files.mod
mv Modules.Mod         fs/data/osrc/modules.mod
mv Input.Mod           fs/data/osrc/input.mod
mv DisplayC.Mod        fs/data/osrc/displayc.mod
mv DisplayM.Mod        fs/data/osrc/displaym.mod
mv Display.Mod         fs/data/osrc/display.mod
mv Viewers.Mod         fs/data/osrc/viewers.mod
mv Fonts.Mod           fs/data/osrc/fonts.mod
mv Texts.Mod           fs/data/osrc/texts.mod
mv Oberon.Mod          fs/data/osrc/oberon.mod
mv MenuViewers.Mod     fs/data/osrc/menuview.mod
mv TextFrames.Mod      fs/data/osrc/textfram.mod
mv System.Mod          fs/data/osrc/system.mod
mv ORS.Mod             fs/data/osrc/ors.mod
mv ORB.Mod             fs/data/osrc/orb.mod
mv ORG.Mod             fs/data/osrc/org.mod
mv ORP.Mod             fs/data/osrc/orp.mod
mv System.Tool         fs/data/osrc/system1.too
mv SplashLogo.Pict     fs/data/osrc/splashlo.pic
cp ../DuskberonBuilder/Unpack.Mod.txt fs/data/osrc/unpack.mod
cp ../DuskberonBuilder/System0.Tool fs/data/osrc/system.too

rm -f fs/data/osrc/pack
for i in *.Mod *.Text *.Tool; do
  printf '\001' >>fs/data/osrc/pack
  echo $i >>fs/data/osrc/pack
  cat $i >>fs/data/osrc/pack
done

rm Bezier.Mod Blink.Mod BootLoad.Mod Clipboard.Mod CommandLineDefragger.Mod CommandLineSystem.Mod ConvertPCFFont.Mod \
    Curves.Mod Draw.Mod Edit.Mod FontSubsetBuilder.Mod GraphicFrames.Mod Graphics.Mod GrowFont.Mod HardwareDetect.Mod \
    HostTransfer.Mod MemorySplit.Mod Net.Mod OptimizeFont.Mod ORC.Mod PCLink1.Mod PIO.Mod Rectangles.Mod Draw.Tool \
	DefragFiles.Mod Defragger.Mod ORL.Mod

touch fs/oberon/extra/draw/draw.ort
mv ColorPictureGrab.Mod fs/oberon/extra/draw/cpgrab.mod
mv ColorPictureTiles.Mod fs/oberon/extra/draw/cptiles.mod
mv DisplayGrab.Mod fs/oberon/extra/draw/displayg.mod
mv Fills.Mod fs/oberon/extra/draw/fills.mod
mv GraphTool.Mod fs/oberon/extra/draw/graphtoo.mod
mv PictureGrab.Mod fs/oberon/extra/draw/pictureg.mod
mv PictureTiles.Mod fs/oberon/extra/draw/picturet.mod
mv Pixelizr.Mod fs/oberon/extra/draw/pixelizr.mod
mv PixelizrObjects.Mod fs/oberon/extra/draw/pixlobje.mod
mv Splines.Mod fs/oberon/extra/draw/splines.mod

mv EditU.Mod fs/oberon/extra/unicode/uedit.mod
mv EditU.Tool fs/oberon/extra/unicode/uedit.ort
mv UnicodeFontIndex.Mod fs/oberon/extra/unicode/ufontind.mod
mv FontsU.Mod fs/oberon/extra/unicode/ufonts.mod
mv TextFramesU.Mod fs/oberon/extra/unicode/utextfra.mod
mv TextsU.Mod fs/oberon/extra/unicode/utexts.mod

mv Calc.Mod fs/oberon/extra/calc/calc.mod
mv Calc.Tool fs/oberon/extra/calc/calc.ort
mv RealCalc.Mod fs/oberon/extra/calc/realcalc.mod
mv RealCalc.Tool fs/oberon/extra/calc/realcalc.ort
mv Unreal.Mod fs/oberon/extra/calc/unreal.mod

patch -p0 -d fs/oberon/extra <../DuskberonBuilder/DuskberonExtras.patch

echo Done.
