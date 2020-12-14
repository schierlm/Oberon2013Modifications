ImageTool.ExtractBootROM BootLoad.rsc

ImageTool.Init MinimalDiskImage.Bin

ImageTool.FreezeClock

ImageTool.AddFiles System.Tool Oberon10.Scn.Fnt
        Input.rsc Display.rsc Viewers.rsc Fonts.rsc
        Texts.rsc Oberon.rsc MenuViewers.rsc TextFrames.rsc
        System.rsc Edit.rsc ~

ImageTool.CopyLinkArea

ORL.Link Modules ~
ImageTool.CreateLinkArea Modules.bin

ImageTool.Close
