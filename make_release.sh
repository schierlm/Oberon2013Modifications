#!/bin/sh
set -e

./get_unpatched_source.sh

cp DefragmentFreeSpace/DefragFiles.Mod.txt work

patch -d work <BugFixes/CheckGlobalsSize.patch
patch -d work <BugFixes/InitializeGraphicFramesTbuf.patch
patch -d work <BugFixes/NoMemoryCorruptionAfterMemoryAllocationFailure.patch
patch -d work <BugFixes/IllegalAccessInGC.patch
patch -d work <BugFixes/CompileSetLiterals.patch
patch -d work <BugFixes/FixScrollCursorCorruption.patch
for i in FileDir Files; do
	cp work/$i.Mod.txt work/Image$i.Mod.txt
done
patch -d work <ImageBuilder/DeriveImageFiles.patch
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
patch -d work <ChangeResolution/ChangeResolution.patch
patch -d work <LanguageServerProtocolHelper/LSPHelper.patch
patch -d work <KernelDebugger/RS232.patch
patch -d work <EditImprovements/Edit.1r.patch
patch -d work <EditImprovements/Edit.3r.patch

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
patch -d work <HardwareEnumerator/HardwareEnumerator.patch
patch -d work <DebugConsole/DebugConsole.patch
patch -d work <CacheCoherence/CacheCoherence.patch -F 3
patch -d work <CacheCoherence/DynamicMemorySplit.patch

sed -i 's/maxCode = 8000; /maxCode = 8500; /' work/ORG.Mod.txt
sed -i '1,2d' work/BootLoad.Mod.txt

cp BuildModifications.Tool.txt ORL.Mod.txt Calculator/*.txt DrawAddons/*.txt ResourceMonitor/*.txt work
cp DefragmentFreeSpace/Defragger.Mod.txt OnScreenKeyboard/*.txt ImageBuilder/*.txt Scripting/*.txt work
cp RebuildToolBuilder/*.txt KeyboardTester/*.txt RobustTrapViewer/*.txt ORInspect/*.txt Clock/*.txt work
cp UTF8CharsetLite/*.txt InnerEmulator/*.txt FontConversion/*.txt DynamicMemorySplit/*.txt work
cp LanguageServerProtocolHelper/*.txt HardwareEnumerator/*.txt SeamlessResize/*.txt DebugConsole/*.txt work
cp ColorSupport/*.txt DrawAddons/16Color/Color*.Mod.txt DrawAddons/16Color/*.Tool.txt ColorPalette/*.txt work
cp ColorTheme/*.txt LSPUtil/*.txt LSPUtil/VGATemplate.Text HostTransfer/*.txt work

patch -d work <HardwareEnumerator/KeyTester.patch
patch -d work <HardwareEnumerator/DrawAddons.patch
patch -d work <HardwareEnumerator/InnerEmulator.patch
patch -d work <EditImprovements/EditU.0.patch
cp EditImprovements/Edit.3r.patch work/EditU.3r.patch
patch -d work <EditImprovements/EditU.3r.patch.patch
patch -d work <work/EditU.3r.patch
patch -d work <StartupCommand/StartupCommand.patch

mv work/Display.Mod.txt work/DisplayM.Mod.txt
mv work/Display.Switch.Mod.txt work/Display.Mod.txt
patch -d work <ColorSupport/ColorSupport.patch
patch -d work <ColorSupport/DrawAddons.patch
patch -d work <ColorTheme/PREPATCH_after_VariableLinespace.patch
patch -d work <ColorTheme/ColorTheme.patch
patch -d work <ColorTheme/POSTPATCH_after_VariableLinespace.patch
patch -d work <ColorTheme/UTF8CharsetLite.patch

mkdir work/debug work/rescue work/debugrescue
cp work/ORB.Mod.txt work/ORG.Mod.txt work/ORP.Mod.txt work/Oberon.Mod.txt work/System.Mod.txt work/debug
cp work/TextFrames.Mod.txt work/OnScreenKeyboard.Mod.txt work/Trappy.Mod.txt work/TextFramesU.Mod.txt work/debug

sed -i 's/maxCode = 8500; /maxCode = 8800; /' work/debug/ORG.Mod.txt
patch -d work/debug <ORInspect/MoreSymbols.patch
patch -d work/debug <ORStackInspect/StackSymbols.patch -F 3
patch -d work/debug <CrossCompiler/POSTPATCH_after_StackSymbols.patch
patch -d work/debug <KernelDebugger/PREPATCH_after_StackOverflowProtector.patch
patch -d work/debug <KernelDebugger/PREPATCH_after_ColorTheme.patch
patch -d work/debug <KernelDebugger/ReserveRegisters.patch
patch -d work/debug -R <KernelDebugger/PREPATCH_after_StackOverflowProtector.patch
patch -d work/debug <KernelDebugger/POSTPATCH_after_ColorTheme.patch
patch -d work/debug <KernelDebugger/POSTPATCH2_after_ColorTheme.patch
sed 's/TextFrames.Mod/TextFramesU.Mod/g' KernelDebugger/PREPATCH_after_ColorTheme.patch | patch -d work/debug
patch -d work/debug <KernelDebugger/ReserveRegistersExtra.patch
sed 's/TextFrames.Mod/TextFramesU.Mod/g' KernelDebugger/POSTPATCH_after_ColorTheme.patch | patch -d work/debug
cp ORStackInspect/*.txt KernelDebugger/*.txt work/debug
patch -d work/debug <CacheCoherence/KernelDebugger.patch

for i in Kernel System.RS Modules.RS Oberon; do
	cp work/${i%%.RS}.Mod.txt work/rescue/$i.Mod.txt
	cp work/debug/${i%%.RS}.Mod.txt work/debugrescue/$i.Mod.txt 2>/dev/null || cp work/${i%%.RS}.Mod.txt work/debugrescue/$i.Mod.txt
done
cp RescueSystem/*.txt MinimalFonts/Fonts.Embedded.Mod.txt work/rescue

patch -d work/rescue <RescueSystem/RescueSystem.patch -F 3
patch -d work/rescue <RescueSystem/POSTPATCH_after_DefragSupport.patch
patch -d work/rescue <HardwareEnumerator/RescueSystem.patch
patch -d work/rescue <ColorSupport/RescueSystem.patch
patch -d work/rescue <CacheCoherence/RescueSystem.patch
patch -d work/debugrescue <RescueSystem/RescueSystem.patch -F 3

rm work/*.orig work/*.patch work/debug/*.orig work/rescue/*.orig work/debugrescue/*.orig

echo Done.
