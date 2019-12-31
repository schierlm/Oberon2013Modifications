#!/bin/sh
set -e

rm -rf work
mkdir work
for i in Kernel Files Modules Input Texts Oberon TextFrames System Edit Graphics GraphicFrames ORB ORG ORP BootLoad; do
	cp ../wirth-personal/people.inf.ethz.ch/wirth/ProjectOberon/Sources/$i.Mod.txt work
	dos2unix work/$i.Mod.txt
done

patch -d work <BugFixes/FixAliasedModules.patch
patch -d work <BugFixes/InitializeGraphicFramesTbuf.patch
patch -d work <BugFixes/NoMemoryCorruptionAfterMemoryAllocationFailure.patch
patch -d work <ConvertEOL/ConvertEOL.patch
patch -d work <DrawAddons/MoreClasses.patch
patch -d work <DefragmentFreeSpace/DefragSupport.patch
patch -d work <RealTimeClock/RealTimeClock.patch
patch -d work <DoubleTrap/DoubleTrap.patch
patch -d work <OnScreenKeyboard/InjectInput.patch
patch -d work <WeakReferences/WeakReferences.patch
patch -d work <TrapBacktrace/PREPATCH_after_DoubleTrap.patch
patch -d work <TrapBacktrace/TrapBacktrace.patch
patch -d work <TrapBacktrace/POSTPATCH_after_DoubleTrap.patch
patch -d work <ZeroLocalVariables/ZeroLocalVariables.patch
patch -d work <VariableLinespace/VariableLineSpace.patch
patch -d work <ORInspect/InspectSymbols.patch
patch -d work <StackOverflowProtector/StackOverflowProtector.patch

sed -i 's/maxCode = 8000; /maxCode = 8500; /' work/ORG.Mod.txt

cp BuildModifications.Tool.txt ORL.Mod.txt Calculator/*.txt DrawAddons/*.txt ResourceMonitor/*.txt work
cp DefragmentFreeSpace/DefragFiles.Mod.txt DefragmentFreeSpace/Defragger.Mod.txt OnScreenKeyboard/*.txt work
cp RebuildToolBuilder/*.txt KeyboardTester/*.txt RobustTrapViewer/*.txt ORInspect/*.txt work

echo Done.
