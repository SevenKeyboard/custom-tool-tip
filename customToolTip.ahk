#Requires AutoHotkey v1.1.37+
;==============================================================
; customToolTip — Creates a customizable tooltip window (colors, font, RTL/LTR, balloon, timeout)
;
; GitHub: https://github.com/SevenKeyboard/custom-tool-tip
; Original Author: teadrinker (2020)
; Maintainer: SevenKeyboard Ltd. (2026)
;==============================================================
class VersionManager_customToolTip
{
    static _ := VersionManager_customToolTip._init()
    _init()    {
        global
        CUSTOMTOOLTIP_VERSION := "1.0.1"
    }
}
customToolTip(text, x := "", y := "", title := ""
    ,icon := 0 ;  can be 1 — Info, 2 — Warning, 3 — Error, if greater than 3 — hIcon
    ,transparent := false
    ,closeButton := false, backColor := "", textColor := 0
    ,fontName := "", fontOptions := "" ;  like in GUI
    ,textDirection := "LTR"
    ,isBalloon := false, timeout := "", maxWidth := 600)
{
    static ttStyles := (WS_POPUP := 0x80000000) | (TTS_NOPREFIX := 2) | (TTS_ALWAYSTIP := 1), TTS_BALLOON := 0x40, TTS_CLOSE := 0x80
        ,TTF_TRACK := 0x20, TTF_ABSOLUTE := 0x80
        ,TTM_SETMAXTIPWIDTH:= 0x418, TTM_TRACKACTIVATE := 0x411, TTM_TRACKPOSITION := 0x412
        ,TTM_SETTIPBKCOLOR := 0x413, TTM_SETTIPTEXTCOLOR := 0x414
        ,TTM_ADDTOOL       := A_IsUnicode ? 0x432 : 0x404
        ,TTM_SETTITLE      := A_IsUnicode ? 0x421 : 0x420
        ,TTM_UPDATETIPTEXT := A_IsUnicode ? 0x439 : 0x40C
        ,WS_EX_TOPMOST     := 0x00000008
        ,WS_EX_TRANSPARENT := 0x00000020
        ,WS_EX_RTLREADING  := 0x00020000
        ,WS_EX_LAYOUTRTL   := 0x00400000
        ,WS_EX_LAYERED     := 0x00080000
        ,WS_EX_COMPOSITED  := 0x02000000
        ,WM_SETFONT := 0x30, WM_GETFONT := 0x31
    exStyles := WS_EX_TOPMOST | WS_EX_COMPOSITED | WS_EX_LAYERED
    if (transparent)
        exStyles |= WS_EX_TRANSPARENT
    if (textDirection = "RTL")
        exStyles |= WS_EX_RTLREADING | WS_EX_LAYOUTRTL
    dhwPrev := A_DetectHiddenWindows
    detectHiddenWindows On
    defGuiPrev := A_DefaultGui, lastFoundPrev := winExist()
    hWnd := dllCall("User32.dll\CreateWindowEx","UInt",exStyles, "Str","tooltips_class32", "Str",""
        ,"UInt",ttStyles | TTS_CLOSE * !!CloseButton | TTS_BALLOON * !!isBalloon
        ,"Int",0, "Int",0, "Int",0, "Int",0, "Ptr",0, "Ptr",0, "Ptr",0, "Ptr",0, "Ptr")
    if (!hWnd)    {
        detectHiddenWindows % dhwPrev
        return 0
    }
    winExist("ahk_id " . hWnd)
    if (textColor !== 0 || backColor !== "")    {
        dllCall("UxTheme.dll\SetWindowTheme", "Ptr",hWnd, "WStr","", "WStr","", "Int")
        if (backColor !== "")
            sendMessage TTM_SETTIPBKCOLOR, rgbToColorRef_3FC38BAA(backColor)
        if (textColor !== 0)
            sendMessage TTM_SETTIPTEXTCOLOR, rgbToColorRef_3FC38BAA(textColor)
    }
    if (fontName || fontOptions)    {
        gui New
        gui Font, % fontOptions, % fontName
        gui Add, Text, hwndhText
        sendMessage WM_GETFONT,,,, % "ahk_id " . hText
        sendMessage WM_SETFONT, errorLevel
        gui Destroy
        gui %defGuiPrev%: Default
    }
    if (x == "" || y == "")
        dllCall("User32.dll\GetCursorPos", "Int64P",pt, "Int")
    (x == "" && x := (pt & 0xFFFFFFFF) + 15), (y == "" && y := (pt >> 32) + 15)

    varSetCapacity(TOOLINFO, sz := 24 + A_PtrSize * 6, 0)
    numPut(sz, TOOLINFO)
    numPut(TTF_TRACK | TTF_ABSOLUTE * !isBalloon, TOOLINFO, 4)
    numPut(&text, TOOLINFO, 24 + A_PtrSize * 3)

    sendMessage TTM_SETTITLE        ,icon   ,&title
    sendMessage TTM_TRACKPOSITION   ,       ,(x & 0xFFFF) | ((y & 0xFFFF) << 16)
    sendMessage TTM_SETMAXTIPWIDTH  ,       ,maxWidth
    sendMessage TTM_ADDTOOL         ,       ,&TOOLINFO
    sendMessage TTM_UPDATETIPTEXT   ,       ,&TOOLINFO
    sendMessage TTM_TRACKACTIVATE   ,true   ,&TOOLINFO
    if (timeout)    {
        timer := func("DllCall").bind("User32.dll\DestroyWindow", "Ptr",hWnd, "Int")
        setTimer % timer, % "-" . timeout
    }
    winExist("ahk_id " . lastFoundPrev)
    detectHiddenWindows % dhwPrev
    return hWnd
}
rgbToColorRef_3FC38BAA(rgb)    {
    return ((rgb & 0xFF) << 16) | (rgb & 0xFF00) | ((rgb >>> 16) & 0xFF)
}