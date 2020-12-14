#!/bin/sh
set -e

rm -rf work
mkdir work
for i in Kernel FileDir Files Modules Fonts Input Display Texts Oberon TextFrames System Edit Graphics GraphicFrames ORB ORG ORP BootLoad RS232; do
	cp ${WIRTH_PERSONAL:-../wirth-personal/}people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work
	dos2unix work/$i.Mod.txt
done

cp DefragmentFreeSpace/DefragFiles.Mod.txt work

patch -d work <BugFixes/CheckGlobalsSize.patch
patch -d work <BugFixes/InitializeGraphicFramesTbuf.patch
patch -d work <BugFixes/NoMemoryCorruptionAfterMemoryAllocationFailure.patch
patch -d work <BugFixes/IllegalAccessInGC.patch
patch -d work <BugFixes/CompileSetLiterals.patch
patch -d work <BugFixes/FixScrollCursorCorruption.patch
patch -d work <ConvertEOL/ConvertEOL.patch
patch -d work <DrawAddons/MoreClasses.patch
patch -d work <RemoveFilesizeLimit/LinkedExtensionTable.patch
patch -d work <RemoveFilesizeLimit/SlidingSectorBitmap.patch
patch -d work <DefragmentFreeSpace/DefragSupport.patch
patch -d work <DefragmentFreeSpace/POSTPATCH_after_SlidingSectorBitmap.patch
patch -d work <RealTimeClock/RealTimeClock.patch
patch -d work <DynamicMemorySplit/DynamicMemorySplit.patch
patch -d work <DoubleTrap/DoubleTrap.patch
patch -d work <OnScreenKeyboard/InjectInput.patch
patch -d work <WeakReferences/WeakReferences.patch
patch -d work <TrapBacktrace/PREPATCH_after_DoubleTrap.patch
patch -d work <TrapBacktrace/TrapBacktrace.patch
patch -d work <TrapBacktrace/POSTPATCH_after_DoubleTrap.patch
patch -d work <ZeroLocalVariables/ZeroLocalVariables.patch
patch -d work <ORInspect/InspectSymbols.patch
patch -d work <CrossCompiler/CrossCompiler.patch
patch -d work <StackOverflowProtector/PREPATCH_after_DynamicMemorySplit.patch
patch -d work <StackOverflowProtector/StackOverflowProtector.patch
patch -d work <StackOverflowProtector/POSTPATCH_after_DynamicMemorySplit.patch
patch -d work <CommandExitCodes/CommandExitCodes.patch
patch -d work <FontConversion/RemoveGlyphWidthLimit.patch

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
sed -i '1,2d' work/BootLoad.Mod.txt

cp BuildModifications.Tool.txt ORL.Mod.txt Calculator/*.txt DrawAddons/*.txt ResourceMonitor/*.txt work
cp DefragmentFreeSpace/Defragger.Mod.txt OnScreenKeyboard/*.txt work
cp RebuildToolBuilder/*.txt KeyboardTester/*.txt RobustTrapViewer/*.txt ORInspect/*.txt Clock/*.txt work
cp UTF8CharsetLite/*.txt InnerEmulator/*.txt FontConversion/*.txt DynamicMemorySplit/*.txt work

mkdir work/debug work/rescue work/debugrescue
cp work/ORB.Mod.txt work/ORG.Mod.txt work/ORP.Mod.txt work/Oberon.Mod.txt work/System.Mod.txt work/debug
cp work/TextFrames.Mod.txt work/OnScreenKeyboard.Mod.txt work/Trappy.Mod.txt work/TextFramesU.Mod.txt work/debug
mv work/RS232.Mod.txt work/debug

sed -i 's/maxCode = 8500; /maxCode = 8800; /' work/debug/ORG.Mod.txt
patch -d work/debug <ORInspect/MoreSymbols.patch
patch -d work/debug <ORStackInspect/StackSymbols.patch -F 3
patch -d work/debug <CrossCompiler/POSTPATCH_after_StackSymbols.patch
patch -d work/debug <KernelDebugger/RS232.patch
patch -d work/debug <KernelDebugger/PREPATCH_after_StackOverflowProtector.patch
patch -d work/debug <KernelDebugger/ReserveRegisters.patch
patch -d work/debug -R <KernelDebugger/PREPATCH_after_StackOverflowProtector.patch
patch -d work/debug <KernelDebugger/ReserveRegistersExtra.patch
cp ORStackInspect/*.txt KernelDebugger/*.txt work/debug

for i in Kernel System.RS Modules.RS Oberon; do
	cp work/${i%%.RS}.Mod.txt work/rescue/$i.Mod.txt
	cp work/debug/${i%%.RS}.Mod.txt work/debugrescue/$i.Mod.txt 2>/dev/null || cp work/${i%%.RS}.Mod.txt work/debugrescue/$i.Mod.txt
done
cp RescueSystem/*.txt MinimalFonts/Fonts.Embedded.Mod.txt work/rescue

patch -d work/rescue <RescueSystem/RescueSystem.patch -F 3
patch -d work/rescue <RescueSystem/POSTPATCH_after_DefragSupport.patch
patch -d work/debugrescue <RescueSystem/RescueSystem.patch -F 3

rm work/*.orig work/debug/*.orig work/rescue/*.orig work/debugrescue/*.orig

echo Done.
