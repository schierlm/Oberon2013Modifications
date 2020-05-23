#!/bin/sh
set -e

rm -rf work
mkdir work
for i in Kernel FileDir Files Modules Fonts Input Texts Oberon TextFrames System Edit Graphics GraphicFrames ORB ORG ORP BootLoad; do
	cp ../wirth-personal/people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work
	dos2unix work/$i.Mod.txt
done

patch -d work <BugFixes/CheckGlobalsSize.patch
patch -d work <BugFixes/InitializeGraphicFramesTbuf.patch
patch -d work <BugFixes/NoMemoryCorruptionAfterMemoryAllocationFailure.patch
patch -d work <BugFixes/IllegalAccessInGC.patch
patch -d work <ConvertEOL/ConvertEOL.patch
patch -d work <DrawAddons/MoreClasses.patch
patch -d work <DefragmentFreeSpace/DefragSupport.patch
patch -d work <RemoveFilesizeLimit/LinkedExtensionTable.patch
patch -d work <RealTimeClock/RealTimeClock.patch
patch -d work <DoubleTrap/DoubleTrap.patch
patch -d work <OnScreenKeyboard/InjectInput.patch
patch -d work <WeakReferences/WeakReferences.patch
patch -d work <TrapBacktrace/PREPATCH_after_DoubleTrap.patch
patch -d work <TrapBacktrace/TrapBacktrace.patch
patch -d work <TrapBacktrace/POSTPATCH_after_DoubleTrap.patch
patch -d work <ZeroLocalVariables/ZeroLocalVariables.patch
patch -d work <ORInspect/InspectSymbols.patch
patch -d work <StackOverflowProtector/StackOverflowProtector.patch

mkdir work/utf8lite
cp work/Fonts.Mod.txt work/TextFrames.Mod.txt work/utf8lite
patch -d work/utf8lite < UTF8Charset/UTF8Charset.patch -t >/dev/null || true
mv work/utf8lite/Fonts.Mod.txt work/FontsU.Mod.txt
mv work/utf8lite/TextFrames.Mod.txt work/TextFramesU.Mod.txt
patch -d work <UTF8CharsetLite/UTF8CharsetLite.patch
mv work/TextFramesU.Mod.txt work/utf8lite/TextFrames.Mod.txt
sed 's/FontsU\.GetMappedUniPat/Fonts.GetUniPat/g;s/TextsU\.UnicodeWidth/Texts.UnicodeWidth/g;s/TextsU\.ReadUnicode/Texts.ReadUnicode/g' -i work/utf8lite/TextFrames.Mod.txt
patch -d work/utf8lite <VariableLinespace/VariableLineSpaceUTF8.patch
sed 's/Fonts\.GetUniPat/FontsU.GetMappedUniPat/g;s/Texts\.UnicodeWidth/TextsU.UnicodeWidth/g;s/Texts\.ReadUnicode/TextsU.ReadUnicode/g' -i work/utf8lite/TextFrames.Mod.txt
mv work/utf8lite/TextFrames.Mod.txt work/TextFramesU.Mod.txt
rmdir work/utf8lite

patch -d work <VariableLinespace/VariableLineSpace.patch

sed -i 's/maxCode = 8000; /maxCode = 8500; /' work/ORG.Mod.txt

cp BuildModifications.Tool.txt ORL.Mod.txt Calculator/*.txt DrawAddons/*.txt ResourceMonitor/*.txt work
cp DefragmentFreeSpace/DefragFiles.Mod.txt DefragmentFreeSpace/Defragger.Mod.txt OnScreenKeyboard/*.txt work
cp RebuildToolBuilder/*.txt KeyboardTester/*.txt RobustTrapViewer/*.txt ORInspect/*.txt work
cp UTF8CharsetLite/*.txt work

echo Done.
