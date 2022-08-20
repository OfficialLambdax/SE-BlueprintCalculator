#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_HiDpi=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs

	Created for Autoit Stable Version v3.3.16.0
		https://www.autoitscript.com/site/

	Requires SciTE4Autoit3.exe
		https://www.autoitscript.com/site/autoit-script-editor/downloads/

	Requires _storageS_UDF v0.2.3
		https://github.com/OfficialLambdax/_storageS-UDF

	Requires 7-Zip
		https://www.7-zip.org/


	Compatible with x32/64

	Credits

		Oscar@Autoit.de for his _RecursiveFileListToArray() function
			https://autoit.de/thread/12423-recursivefilelisttoarray-mit-stringregexp/

		Christian Faderl for his ISN Autoit Studio, with which the gui was designed in
			https://www.isnetwork.at/isn-autoit-studio/

		Igor Pavlov for 7-Zip
			https://www.7-zip.org/

#ce

#NoTrayIcon ; do not show a tray icon
#include-once
#include "libs\_storageS_UDF.au3"
#include <Array.au3>
#include <GuiMenu.au3>
#include "Forms\GUI.isf"

If not @Compiled then DllCall("User32.dll", "bool", "SetProcessDPIAware")



#Region Variables
; ===============================================================================================================================

; constants
Global Const $__sfVanillaBlocks = @ScriptDir & "\vanillablocks.txt"
Global Const $__sfModBlocks = @ScriptDir & "\modblocks.txt"
Global Const $__sfAllModBlocks = @ScriptDir & "\allmodblocks.txt"
Global Const $__sfMods = @ScriptDir & "\mods.txt"
Global Const $__sfBinWorkFolder = @ScriptDir & "\binworkfolder"
Global Const $__sf7Zip = @ScriptDir & "\libs\7z.exe"
Global Const $__sfConfig = @ScriptDir & "\config.ini"

; internal uses
Global $__sfBlueprintDir = @AppDataDir & "\SpaceEngineers\Blueprints"
Global $__sfVanillaBlocksDir = "C:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks"
Global $__sfModBlockDir = "C:\SteamLibrary\steamapps\workshop\content\244850"
Global $__sfSavesDir = @AppDataDir & "\SpaceEngineers\Saves"
Global $__sfSaveMods =  @ScriptDir & "\save-mods.txt"
Global $__sfLoadedBP = ""
Global $__sfLoadedSave = ""
Global $__bModListSwitch = False
Global $__bBlockListSwitch = False
#EndRegion

#Region GUI Init
; ===============================================================================================================================
Opt("GUIOnEventMode",  1)

GUIRegisterMsg($WM_NOTIFY, "_WM_NOTIFY")
GUISetOnEvent($GUI_EVENT_CLOSE, "_GUIEvent_Close")
GUICtrlSetOnEvent($bLoadBP, "_GUIEvent_LoadBP")
GUICtrlSetOnEvent($bLoadSave, "_GUIEvent_LoadSave")
GUICtrlSetOnEvent($bVanilla, "_GUIEvent_Vanilla")
GUICtrlSetOnEvent($bReloadMods, "_GUIEvent_ReloadMods")
GUICtrlSetOnEvent($bReloadSave, "_GUIEvent_ReloadSave")
GUICtrlSetOnEvent($bReloadVanilla, "_GUIEvent_ReloadVanilla")
GUICtrlSetOnEvent($bSwitchMods, "_GUIEvent_ModSwitch")
GUICtrlSetOnEvent($bSwitchBlocks, "_GUIEvent_BlockSwitch")
GUICtrlSetOnEvent($bSave, "_GUIEvent_Save")

GUICtrlDelete($eBPBlocks)
GUICtrlDelete($eBPComponents)
GUICtrlDelete($eSaveMods)

Local $iExListViewStyle = BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER)
$eBPBlocks = _GUICtrlListView_Create($GUI, "", 10, 89, 228, 281, -1, $WS_EX_CLIENTEDGE)
_GUICtrlListView_SetExtendedListViewStyle($eBPBlocks, $iExListViewStyle)

_GUICtrlListView_AddColumn($eBPBlocks, "Available Blocks", 140)
_GUICtrlListView_AddColumn($eBPBlocks, "Amount", 50)

;~ Global $eMissingBlocks
Global $eMissingBlocks = _GUICtrlListView_Create($GUI, "", 10, 89, 228, 281, -1, $WS_EX_CLIENTEDGE)
_GUICtrlListView_SetExtendedListViewStyle($eMissingBlocks, $iExListViewStyle)

_GUICtrlListView_AddColumn($eMissingBlocks, "Missing Blocks", 140)
_GUICtrlListView_AddColumn($eMissingBlocks, "Amount", 50)

$eBPComponents = _GUICtrlListView_Create($GUI, "", 458, 89, 210, 281, -1, $WS_EX_CLIENTEDGE)
_GUICtrlListView_SetExtendedListViewStyle($eBPComponents, $iExListViewStyle)

_GUICtrlListView_AddColumn($eBPComponents, "Components", 140)
_GUICtrlListView_AddColumn($eBPComponents, "Amount", 50)

$eSaveMods = _GUICtrlListView_Create($GUI, "", 245, 89, 206, 281, -1, $WS_EX_CLIENTEDGE)
_GUICtrlListView_SetExtendedListViewStyle($eSaveMods, $iExListViewStyle)

_GUICtrlListView_AddColumn($eSaveMods, "Loaded Mods", 190)

;~ Global $eMissingMods
Global $eMissingMods = _GUICtrlListView_Create($GUI, "", 245, 89, 206, 281, -1, $WS_EX_CLIENTEDGE)
_GUICtrlListView_SetExtendedListViewStyle($eMissingMods, $iExListViewStyle)

_GUICtrlListView_AddColumn($eMissingMods, "Missing Mods", 190)

_WinAPI_MoveWindow($eMissingBlocks, -1000, 20, 1, 1)
_WinAPI_MoveWindow($eMissingMods, 1000, 20, 1, 1)

GUISetState(@SW_SHOW)
#EndRegion

#Region Other Init
; ===============================================================================================================================
_Internal_LoadConfig()

_storageGO_CreateGroup("Blocks") ; contains all blocks and their required parts
_storageMLi_CreateGroup("Items") ; contains all existing items
_storageMLi_CreateGroup("Save_Mods") ; for the save function

_Internal_LoadVanillaBlocks()
_Internal_LoadAllModBlocks()
#EndRegion Init


#Region Testings
; ===============================================================================================================================


#EndRegion


#Region Main
; ===============================================================================================================================
While True
	Sleep(10)
Wend
#EndRegion Main



#Region GUIEvents
; ===============================================================================================================================
Func _GUIEvent_BlockSwitch()
	if $__bBlockListSwitch Then ; disable missing blocks
		_WinAPI_MoveWindow($eMissingBlocks, -1000, 20, 1, 1)
		_WinAPI_MoveWindow($eBPBlocks, 10, 89, 228, 281)

		GUICtrlSetData($bSwitchBlocks, "Available Blocks")

		$__bBlockListSwitch = False
	Else ; enable
		_WinAPI_MoveWindow($eMissingBlocks, 10, 89, 228, 281)
		_WinAPI_MoveWindow($eBPBlocks, -1000, 20, 1, 1)

		GUICtrlSetData($bSwitchBlocks, "Missing Blocks")

		$__bBlockListSwitch = True
	EndIf
EndFunc

Func _GUIEvent_ModSwitch()
	If $__bModListSwitch Then ; disable missing mods
		_WinAPI_MoveWindow($eSaveMods, 245, 89, 206, 281)
		_WinAPI_MoveWindow($eMissingMods, 1000, 20, 1, 1)

		GUICtrlSetData($bSwitchMods, "Loaded Mods")

		$__bModListSwitch = False
	Else ; enable
		_WinAPI_MoveWindow($eSaveMods, 1000, 20, 1, 1)
		_WinAPI_MoveWindow($eMissingMods, 245, 89, 206, 281)

		GUICtrlSetData($bSwitchMods, "Missing Mods")

		$__bModListSwitch = True
	EndIf
EndFunc

Func _GUIEvent_LoadBP()
	Local $sfFile = FileSelectFolder("Select Blueprint folder", $__sfBlueprintDir)
	if $sfFile = "" Then Return

	$sfFile &= '\bp.sbc'
	_Internal_LoadBP($sfFile)
EndFunc

Func _GUIEvent_LoadSave()
	Local $sfFile = FileSelectFolder("Select Save folder", $__sfSavesDir)
	if $sfFile = "" Then Return

	_storageGO_DestroyGroup("Blocks")
	_storageMLi_DestroyGroup("Items")
	_storageGO_CreateGroup("Blocks")
	_storageMLi_CreateGroup("Items")

	_Internal_LoadVanillaBlocks()
	_Internal_LoadSavesModBlocks($sfFile)

	if $__sfLoadedBP <> "" Then _Internal_LoadBP($__sfLoadedBP)
EndFunc

Func _GUIEvent_Vanilla()
	GUICtrlSetData($lSavePath, "None")

	_storageGO_DestroyGroup("Blocks")
	_storageMLi_DestroyGroup("Items")
	_storageGO_CreateGroup("Blocks")
	_storageMLi_CreateGroup("Items")
	_storageMLi_DestroyGroup("Save_Mods")
	_storageMLi_CreateGroup("Save_Mods")

	_Internal_LoadVanillaBlocks()

	_GUICtrlListView_BeginUpdate($eSaveMods)
	_GUICtrlListView_DeleteAllItems($eSaveMods)
	_GUICtrlListView_EndUpdate($eSaveMods)

	if $__sfLoadedBP <> "" Then _Internal_LoadBP($__sfLoadedBP)
EndFunc

Func _GUIEvent_ReloadMods()
	FileDelete($__sfAllModBlocks)
	_Internal_LoadAllModBlocks()
EndFunc

Func _GUIEvent_ReloadSave()
	If $__sfLoadedSave <> "" Then
		FileDelete($__sfModBlocks)
		_storageGO_DestroyGroup("Blocks")
		_storageMLi_DestroyGroup("Items")
		_storageGO_CreateGroup("Blocks")
		_storageMLi_CreateGroup("Items")

		_Internal_LoadVanillaBlocks()
		_Internal_LoadSavesModBlocks($__sfLoadedSave)

		if $__sfLoadedBP <> "" Then _Internal_LoadBP($__sfLoadedBP)
	EndIf
EndFunc

Func _GUIEvent_ReloadVanilla()
	FileDelete($__sfVanillaBlocks)

	_storageGO_DestroyGroup("Blocks")
	_storageMLi_DestroyGroup("Items")
	_storageGO_CreateGroup("Blocks")
	_storageMLi_CreateGroup("Items")

	_Internal_LoadVanillaBlocks()
	If $__sfLoadedSave <> "" Then _Internal_LoadSavesModBlocks($__sfLoadedSave)

	if $__sfLoadedBP <> "" Then _Internal_LoadBP($__sfLoadedBP)
EndFunc

Func _GUIEvent_Save()
	Local $arMods = _storageMLi_GetElements("Save_Mods")
	If UBound($arMods) == 0 Then Return MsgBox(16, "Error", "No Mods loaded to save")
	
	Local $hOpen = FileOpen($__sfSaveMods, 2)
	For $i = 0 To UBound($arMods) - 1
		FileWrite($hOpen, StringReplace("https://steamcommunity.com/workshop/filedetails/?id=%", '%', $arMods[$i] & @CRLF & @CRLF))
	Next
	FileClose($hOpen)
	
	MsgBox(32, "Sucess", "All Mods got Saved to Save-Mods.txt")
EndFunc

Func _GUIEvent_Close()
	Exit
EndFunc

#EndRegion GUIEvents


#Region Internal
; ===============================================================================================================================
Func _Internal_LoadConfig()
	if Not FileExists($__sfConfig) Then _Internal_SetupConfig()
	$__sfVanillaBlocksDir = IniRead($__sfConfig, "Setup", "GamePath", "") & "\Content\Data\CubeBlocks"

	$__sfModBlockDir = IniRead($__sfConfig, "Setup", "WorkshopPath", "")
EndFunc

Func _Internal_SetupConfig()
	Local $sGamePath = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 244850", "InstallLocation")
	if @error Then
		MsgBox(48, "", "Could not find installation directory. Please tell me where the game is located in the next window")
		$sGamePath = FileSelectFolder("Select Game Folder", @ScriptDir)
		if $sGamePath == "" Then Exit MsgBox(16, "", "Setup Aborted")
	EndIf

	IniWrite($__sfConfig, "Setup", "GamePath", $sGamePath)

	Local $sWorkShop = StringReplace($sGamePath, "common\SpaceEngineers", "workshop\content\244850")
	If Not FileExists($sWorkShop) Then
		MsgBox(48, "", "Could not find workshop directory. Please tell me where the workshop is located in the next window")
		$sWorkShop = FileSelectFolder("Select Workshop Folder", $sGamePath)
		if $sWorkShop == "" Then Exit MsgBox(16, "", "Setup Aborted")
	EndIf

	IniWrite($__sfConfig, "Setup", "WorkshopPath", $sWorkShop)

	MsgBox(64, "Setup complete", "Found the gamepath and workshop path and saved them to the config.ini")
EndFunc

Func _Internal_LoadBP($sfFile)
	Local $arBPBlocks = _Internal_LoadBlueprintBlocks($sfFile)
	_Internal_CalcBPCosts($arBPBlocks)
	$__sfLoadedBP = $sfFile
EndFunc

Func _Internal_CalcBPCosts(ByRef $arBPBlocks)

	GUICtrlSetData($lTodo, "Calculating Blueprint Block Costs")
	GUICtrlSetData($pTodo, 0)

	; get all items (components)
	Local $mItems = _storageMLi_GetElements("Items", True)

	; overwrite with 0
	Local $arItems = MapKeys($mItems)
	For $i = 0 To UBound($arItems) - 1
		$mItems[$arItems[$i]] = 0
	Next

	; query the required blocks for the bp and add their components to the item list
	Local $arComponents[0]
	For $i = 0 To UBound($arBPBlocks) - 1

		GUICtrlSetData($lTodo, "Calculating Blueprint Block Costs " & $arBPBlocks[$i][0])
		GUICtrlSetData($pTodo, ($i / UBound($arBPBlocks)) * 100)

		; fetch components
		$arComponents = _storageGO_Read("Blocks", $arBPBlocks[$i][0])

		; for each component
		For $iS = 0 To UBound($arComponents) - 1

			; if its unknown then ignore the component
			If Not MapExists($mItems, $arComponents[$iS][0]) Then ContinueLoop

			; otherwise add
			$mItems[$arComponents[$iS][0]] += ($arComponents[$iS][1] * $arBPBlocks[$i][1])
		Next

	Next

	; read the map and form a 2d array from it and also fill the listview
	Local $arItems2D[UBound($arItems)][2], $nIndex = 0, $nPos = 0
	_GUICtrlListView_BeginUpdate($eBPComponents)
	_GUICtrlListView_DeleteAllItems($eBPComponents)

	For $i = 0 To UBound($arItems) - 1
		if $mItems[$arItems[$i]] == 0 Then ContinueLoop

		$arItems2D[$nIndex][0] = $arItems[$i]
		$arItems2D[$nIndex][1] = $mItems[$arItems[$i]]

		$nPos = _GUICtrlListView_AddItem($eBPComponents, $arItems2D[$nIndex][0])
		_GUICtrlListView_AddSubItem($eBPComponents, $nPos, $arItems2D[$nIndex][1], 1)

		$nIndex += 1
	Next

	_GUICtrlListView_EndUpdate($eBPComponents)

	; we only care for required components
	ReDim $arItems2D[$nIndex][2]

	GUICtrlSetData($lTodo, "Calculating Blueprint Block Costs Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub2, 0)

	Return $arItems2D
EndFunc

Func _Internal_LoadBlueprintBlocks(Const $sfFile)

	GUICtrlSetData($lBPPath, StringTrimLeft($sfFile, StringInStr($sfFile, '\', 0,  -2)))
	GUICtrlSetData($lTodo, "Loading Blueprint Blocks")
	GUICtrlSetData($pTodo, 0)

	; read bp
	Local $hOpen = FileOpen($sfFile, 0)
	if $hOpen == -1 Then Return SetError(1, 0, False)

	; split it up by line feed
	Local $arFileContent = StringSplit(FileRead($hOpen), @CRLF, 1)
	FileClose($hOpen)

	_storageALR_Destroy()

	; Missing Mods storage
	If Not _storageMLi_CreateGroup("MissingMods") Then
		Local $arMods = _storageMLi_GetElements("MissingMods")
		For $i = 0 To UBound($arMods) - 1
			_storageMLi_DestroyGroup($arMods[$i])
		Next
		_storageMLi_DestroyGroup("MissingMods")

		_storageMLi_CreateGroup("MissingMods")
	EndIf

	; add each found block to a rapid array
	Local $sBlock = "", $sMod = ""
	For $i = 1 To $arFileContent[0]
		If StringInStr($arFileContent[$i], "<SubtypeName>") Then
			If Not StringInStr($arFileContent[$i - 1], "MyObjectBuilder_CubeBlock") Then ContinueLoop
			$sBlock = StringReplace(StringReplace(StringReplace($arFileContent[$i], "<SubtypeName>", ''), "</SubtypeName>", ''), ' ', '')

			if _storageGO_Read("Blocks", $sBlock) == False Then
				$sMod = _storageGO_Read("AllBlocks", $sBlock)
				If $sMod == False Then $sMod = "Unknown Mod"

				; add mod as missing, can only be written once
				_storageMLi_AddElement("MissingMods", $sMod)

				; create group for the missing mod blocks
				_storageMLi_CreateGroup($sMod)

				; add the block
				_storageMLi_AddElement($sMod, $sBlock)
			EndIf


			_storageALR_AddElement($sBlock)
		EndIf
	Next

	; convert to default array
	_storageALR_ConvertToAL("temp")

	; fetch it
	Local $arElements = _storageAL_GetElements("temp")

	; clean up
	_storageALR_Destroy()
	_storageAL_DestroyGroup("temp")

	; count the amount of blocks
	Local $mElements[]
	For $i = 0 To UBound($arElements) - 1
		GUICtrlSetData($pTodo, ($i / UBound($arElements)) * 100)
		If MapExists($mElements, $arElements[$i]) Then
			$mElements[$arElements[$i]] += 1
		Else
			$mElements[$arElements[$i]] = 1
		EndIf
	Next

	; convert map to a 2d array and also fill listview
	Local $arMap = MapKeys($mElements), $nPos = 0
	ReDim $arElements[UBound($arMap)][2]

	_GUICtrlListView_BeginUpdate($eBPBlocks)
	_GUICtrlListView_BeginUpdate($eMissingBlocks)
	_GUICtrlListView_DeleteAllItems($eBPBlocks)
	_GUICtrlListView_DeleteAllItems($eMissingBlocks)

	For $i = 0 To UBound($arMap) - 1
		$arElements[$i][0] = $arMap[$i]
		$arElements[$i][1] = Int($mElements[$arMap[$i]])


		if _storageGO_Read("Blocks", $arElements[$i][0]) == False Then
			$nPos = _GUICtrlListView_AddItem($eMissingBlocks, $arElements[$i][0])
			_GUICtrlListView_AddSubItem($eMissingBlocks, $nPos, $arElements[$i][1], 1)
		Else
			$nPos = _GUICtrlListView_AddItem($eBPBlocks, $arElements[$i][0])
			_GUICtrlListView_AddSubItem($eBPBlocks, $nPos, $arElements[$i][1], 1)
		EndIf

	Next

	_GUICtrlListView_EndUpdate($eBPBlocks)
	_GUICtrlListView_EndUpdate($eMissingBlocks)


	; add missing mods
	_GUICtrlListView_BeginUpdate($eMissingMods)
	_GUICtrlListView_DeleteAllItems($eMissingMods)
	Local $arMods = _storageMLi_GetElements("MissingMods")
	For $i = 0 To UBound($arMods) - 1
		_GUICtrlListView_AddItem($eMissingMods, $arMods[$i])
	Next

	_GUICtrlListView_EndUpdate($eMissingMods)

	GUICtrlSetData($lTodo, "Loading Blueprint Blocks Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub2, 0)

	Return $arElements
EndFunc

Func _Internal_LoadVanillaBlocks()
	If Not FileExists($__sfVanillaBlocks) Then __Parse_GameFilesForBlocks($__sfVanillaBlocksDir)

	GUICtrlSetData($lTodo, "Loading Vanilla Blocks")
	GUICtrlSetData($pTodo, 0)

	; load from file
	Local $hOpen = FileOpen($__sfVanillaBlocks, 0)
	Local $arContent = StringSplit(FileRead($hOpen), @CRLF, 1)
	FileClose($hOpen)

	; for each block def in the file
	Local $arBlockContent[0][2], $arElements[0], $arComponents[0], $arCompentDef[0]
	For $i = 1 To $arContent[0]
		If $arContent[$i] == "" Then ContinueLoop

		GUICtrlSetData($pTodo, ($i / $arContent[0]) * 100)

		; seperate block from materials
		$arElements = StringSplit($arContent[$i], '=', 1)
		If $arElements[2] = "" Then ContinueLoop

		; seperate materials
		$arComponents = StringSplit($arElements[2], ';', 3)

		; add each material to the 2d array
		ReDim $arBlockContent[UBound($arComponents) - 1][2]
		For $iS = 0 To UBound($arComponents) - 1
			if $arComponents[$iS] == "" Then ContinueLoop
			$arCompentDef = StringSplit($arComponents[$iS], '-', 1)

			If $arCompentDef[2] == "" Or $arCompentDef[1] == "" Then ContinueLoop

			if _Internal_LoadModBlocks_Helper($arCompentDef[1]) Then
				$arBlockContent[$iS][0] = $arCompentDef[2]
				$arBlockContent[$iS][1] = $arCompentDef[1]
				_storageMLi_AddElement("Items", $arCompentDef[2]) ; doesnt matter if its written again
			Else
				$arBlockContent[$iS][0] = $arCompentDef[1]
				$arBlockContent[$iS][1] = $arCompentDef[2]
				_storageMLi_AddElement("Items", $arCompentDef[1]) ; doesnt matter if its written again
			EndIf
		Next

		; save the 2d array to the block
		_storageGO_Overwrite("Blocks", $arElements[1], $arBlockContent)
	Next

	GUICtrlSetData($lTodo, "Loading Vanilla Blocks Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub2, 0)
EndFunc

Func _Internal_LoadModBlocks_Helper($sData)
	If StringLen(Number($sData)) == StringLen($sData) Then Return True
	Return False
EndFunc

Func _Internal_LoadSavesModBlocks(Const $sfPath)
	GUICtrlSetData($lSavePath, StringTrimLeft($sfPath, StringInStr($sfPath, '\', 0, -1)))
	$__sfLoadedSave = $sfPath
	If BinaryToString(IniRead($__sfConfig, 'Saves', "LastLoaded", "")) <> $sfPath Or Not FileExists($__sfModBlocks) Then __Parse_SaveModFilesForBlocks($sfPath & '\Sandbox.sbc')

	GUICtrlSetData($lTodo, "Loading Save Mod Blocks")
	GUICtrlSetData($pTodo, 0)

	; load from file
	Local $hOpen = FileOpen($__sfModBlocks, 0)
	Local $arContent = StringSplit(FileRead($hOpen), @CRLF, 1)
	FileClose($hOpen)

	; for each block def in the file
	Local $arBlockContent[0][2], $arElements[0], $arComponents[0], $arCompentDef[0]
	For $i = 1 To $arContent[0]
		If $arContent[$i] == "" Then ContinueLoop

		GUICtrlSetData($pTodo, ($i / $arContent[0]) * 100)

		; seperate block from materials
		$arElements = StringSplit($arContent[$i], '=', 1)
		If $arElements[2] = "" Then ContinueLoop

		; seperate materials
		$arComponents = StringSplit($arElements[2], ';', 3)

		; add each material to the 2d array
		ReDim $arBlockContent[UBound($arComponents) - 1][2]
		For $iS = 0 To UBound($arComponents) - 1
			if $arComponents[$iS] == "" Then

				; if its the last component then just continue
				If $iS == UBound($arComponents) - 1 Then ContinueLoop

				; otherwise consider this block not to be a block and therefore ignore it
				ContinueLoop 2
			EndIf
			$arCompentDef = StringSplit($arComponents[$iS], '-', 1)

			; if the component has no amount then ignore this block, probably not a block
			If $arCompentDef[2] == "" Or $arCompentDef[1] == "" Then ContinueLoop 2

			if _Internal_LoadModBlocks_Helper($arCompentDef[1]) Then
				$arBlockContent[$iS][0] = $arCompentDef[2]
				$arBlockContent[$iS][1] = $arCompentDef[1]
				_storageMLi_AddElement("Items", $arCompentDef[2]) ; doesnt matter if its written again
			Else
				$arBlockContent[$iS][0] = $arCompentDef[1]
				$arBlockContent[$iS][1] = $arCompentDef[2]
				_storageMLi_AddElement("Items", $arCompentDef[1]) ; doesnt matter if its written again
			EndIf
		Next

		; save the 2d array to the block
		_storageGO_Overwrite("Blocks", $arElements[1], $arBlockContent)
	Next
	
	_storageMLi_DestroyGroup("Save_Mods")
	_storageMLi_CreateGroup("Save_Mods")
	
	If FileExists($__sfMods) Then
		Local $hMods = FileOpen($__sfMods, 0)
		Local $arMods = StringSplit(FileRead($hMods), @CRLF, 1)
		FileClose($hMods)

		if $arMods[0] > 0 Then
			_GUICtrlListView_BeginUpdate($eSaveMods)
			_GUICtrlListView_DeleteAllItems($eSaveMods)

			For $i = 1 To $arMods[0]
				if $arMods[$i] == "" Then ContinueLoop
				_GUICtrlListView_AddItem($eSaveMods, $arMods[$i])
				_storageMLi_AddElement("Save_Mods", $arMods[$i])
			Next

			_GUICtrlListView_EndUpdate($eSaveMods)
		EndIf

	EndIf

	IniWrite($__sfConfig, 'Saves', "LastLoaded", StringToBinary($sfPath))

	GUICtrlSetData($lTodo, "Loading Save Mod Blocks Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub2, 0)
EndFunc

Func _Internal_FindBlock($sBlock)
	Return _storageGO_Read("AllBlocks", $sBlock)
EndFunc

Func _Internal_LoadAllModBlocks()
	If Not FileExists($__sfAllModBlocks) Then __Parse_AllModFilesForBlocks()

	GUICtrlSetData($lTodo, "Loading All Mod Blocks")
	GUICtrlSetData($pTodo, 0)

	_storageGO_DestroyGroup("AllBlocks")
	_storageGO_CreateGroup("AllBlocks")

	Local $hBlocks = FileOpen($__sfAllModBlocks, 0)
	If $hBlocks == -1 Then Return
	Local $arElements = StringSplit(FileRead($hBlocks), @CRLF, 1)
	FileClose($hBlocks)

	Local $arContent[0]
	For $i = 1 To $arElements[0]
		GUICtrlSetData($pTodo, ($i / $arElements[0]) * 100)
		If $arElements[$i] == "" Then ContinueLoop
		$arContent = StringSplit($arElements[$i], '=', 1)

		_storageGO_Overwrite("AllBlocks", $arContent[1], $arContent[2])
	Next

	GUICtrlSetData($lTodo, "Loading All Mod Blocks Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub2, 100)

EndFunc
#EndRegion

#Region Parse Funcs
; ===============================================================================================================================
Func __Parse_AllModFilesForBlocks()

	GUICtrlSetData($lTodo, "Parsing All Mod Blocks")
	GUICtrlSetData($pTodo, 0)

	FileDelete($__sfAllModBlocks)

	_storageALR_Destroy()

	; get all mods
	Local $hFileSearch = FileFindFirstFile($__sfModBlockDir & '\*.*'), $sFile = ""
	While True
		$sFile = FileFindNextFile($hFileSearch)
		if @error Then ExitLoop

		If StringInStr(FileGetAttrib($__sfModBlockDir & '\' & $sFile), 'D') Then _storageALR_AddElement($sFile)
	WEnd

	FileClose($hFileSearch)

	_storageALR_ConvertToAL("temp")
	Local $arMods = _storageAL_GetElements("temp")

	; clean up
	_storageALR_Destroy()
	_storageAL_DestroyGroup("temp")

	Local $hBlocks = FileOpen($__sfAllModBlocks, 2)

	; index each block from the used blocks
	Local $arSBCFiles[0], $hSBC = 0, $sSBC = ""
	For $i = 0 To UBound($arMods) - 1

		GUICtrlSetData($lTodo, "Parsing All Mod Blocks " &  $arMods[$i])
		GUICtrlSetData($pTodo, ($i / UBound($arMods)) * 100)

		; get the .sbc files
		$arSBCFiles = _RecursiveFileListToArray($__sfModBlockDir & '\' & $arMods[$i], '\.sbc\z')
		if Not @error Then

			; query each .sbc file
			For $iS = 1 To $arSBCFiles[0]
				GUICtrlSetData($pTodoSub, ($iS / $arSBCFiles[0]) * 100)
				$hSBC = FileOpen($arSBCFiles[$iS], 0)
				If $hSBC == -1 Then ContinueLoop
				$sSBC = FileRead($hSBC)
				FileClose($hSBC)

				If Not StringInStr($sSBC, "<SubtypeId>") Then ContinueLoop

				__Parse_AllModFilesForBlocks_Helper($hBlocks, $sSBC, $arMods[$i])
			Next
		EndIf

		; then look for .bin files
		$arBinFiles = _RecursiveFileListToArray($__sfModBlockDir & '\' & $arMods[$i], '\.bin\z')
		if @error Then ContinueLoop

		For $iS = 1 To $arBinFiles[0]

			DirCreate($__sfBinWorkFolder)
			RunWait(@ComSpec & ' /C call "' & $__sf7Zip & '" x -o"' & $__sfBinWorkFolder & '" -y "' & $arBinFiles[$iS] & '"', "", @SW_HIDE)

			$arSBCFiles = _RecursiveFileListToArray($__sfBinWorkFolder, '\.sbc\z', 1)
			if @error Then
				DirRemove($__sfBinWorkFolder, 1)
				ContinueLoop
			EndIf

			For $iD = 1 To $arSBCFiles[0]
				GUICtrlSetData($pTodoSub, ($iS / $arSBCFiles[0]) * 100)
				$hSBC = FileOpen($arSBCFiles[$iD], 0)
				If $hSBC == -1 Then ContinueLoop
				$sSBC = FileRead($hSBC)
				FileClose($hSBC)

				If Not StringInStr($sSBC, "<SubtypeId>") Then ContinueLoop

				__Parse_AllModFilesForBlocks_Helper($hBlocks, $sSBC, $arMods[$i])
			Next

			DirRemove($__sfBinWorkFolder, 1)
		Next

	Next

	GUICtrlSetData($lTodo, "Parsing All Mod Blocks Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub, 0)
EndFunc

Func __Parse_SaveModFilesForBlocks(Const $sfFile)

	GUICtrlSetData($lTodo, "Parsing Save Mod Blocks")
	GUICtrlSetData($pTodo, 0)

	; delete the already existing file
	FileDelete($__sfModBlocks)

	; read the save sbc
	Local $hOpen = FileOpen($sfFile, 0)
	if $hOpen == -1 Then Return
	Local $sContent = FileRead($hOpen)
	FileClose($hOpen)

	; encase the mods section
	$sContent = StringTrimLeft($sContent, StringInStr($sContent, "<Mods>"))
	$sContent = StringLeft($sContent, StringInStr($sContent, "</Mods>"))

	; split it up by line feed
	Local $arContent = StringSplit($sContent, @CRLF, 1)

	Local $hMods = FileOpen($__sfMods, 2), $sMods = ""

	; fill a rapid array with each mod
	_storageALR_Destroy()
	For $i = 1 To $arContent[0]
		if StringInStr($arContent[$i], "<PublishedFileId>") Then
			$sMods = StringReplace(StringReplace(StringReplace($arContent[$i], "<PublishedFileId>", ''), "</PublishedFileId>", ''), ' ', '')
			FileWrite($hMods, $sMods & @CRLF)
			_storageALR_AddElement($sMods)
		EndIf
	Next

	FileClose($hMods)

	; convert to default array
	_storageALR_ConvertToAL("temp")

	; fetch it
	Local $arMods = _storageAL_GetElements("temp")

	; clean up
	_storageALR_Destroy()
	_storageAL_DestroyGroup("temp")

	; if there are no mods then return
	if UBound($arMods) == 0 Then Return

	; otherwise open mod blocks file
	Local $hBlocks = FileOpen($__sfModBlocks, 2)

	; index each block from the used blocks
	Local $arSBCFiles[0], $hSBC = 0, $sSBC = ""
	For $i = 0 To UBound($arMods) - 1
;~ 		ConsoleWrite($i & '/' & UBound($arMods) & @TAB & $__sfModBlockDir & '\' & $arMods[$i] & @CRLF)

		GUICtrlSetData($lTodo, "Parsing Save Mod Blocks " &  $arMods[$i])
		GUICtrlSetData($pTodo, ($i / UBound($arMods)) * 100)

		; get the .sbc files
		$arSBCFiles = _RecursiveFileListToArray($__sfModBlockDir & '\' & $arMods[$i], '\.sbc\z')
		if Not @error Then

			; query each .sbc file
			For $iS = 1 To $arSBCFiles[0]
				GUICtrlSetData($pTodoSub, ($iS / $arSBCFiles[0]) * 100)
				$hSBC = FileOpen($arSBCFiles[$iS], 0)
				If $hSBC == -1 Then ContinueLoop
				$sSBC = FileRead($hSBC)
				FileClose($hSBC)

				If Not StringInStr($sSBC, "<SubtypeId>") Then ContinueLoop

;~ 				ConsoleWrite(@TAB & $iS & '/' & $arSBCFiles[0] & @TAB & $arSBCFiles[$iS] & @CRLF)
				__Parse_ModFilesForBlocks_Helper($hBlocks, $sSBC)
			Next
		EndIf

		; then look for .bin files
		$arBinFiles = _RecursiveFileListToArray($__sfModBlockDir & '\' & $arMods[$i], '\.bin\z')
		if @error Then ContinueLoop

		For $iS = 1 To $arBinFiles[0]

			DirCreate($__sfBinWorkFolder)
;~ 			ConsoleWrite($iS & '/' & $arBinFiles[0] & @TAB & $arBinFiles[$iS] & @CRLF)
			RunWait(@ComSpec & ' /C call "' & $__sf7Zip & '" x -o"' & $__sfBinWorkFolder & '" -y "' & $arBinFiles[$iS] & '"', "", @SW_HIDE)

			$arSBCFiles = _RecursiveFileListToArray($__sfBinWorkFolder, '\.sbc\z', 1)
			if @error Then
				DirRemove($__sfBinWorkFolder, 1)
				ContinueLoop
			EndIf

			For $iD = 1 To $arSBCFiles[0]
				GUICtrlSetData($pTodoSub, ($iS / $arSBCFiles[0]) * 100)
				$hSBC = FileOpen($arSBCFiles[$iD], 0)
				If $hSBC == -1 Then ContinueLoop
				$sSBC = FileRead($hSBC)
				FileClose($hSBC)

				If Not StringInStr($sSBC, "<SubtypeId>") Then ContinueLoop

;~ 				ConsoleWrite(@TAB & $iD & '/' & $arSBCFiles[0] & @TAB & $arSBCFiles[$iD] & @CRLF)
				__Parse_ModFilesForBlocks_Helper($hBlocks, $sSBC)
			Next

			DirRemove($__sfBinWorkFolder, 1)
		Next

	Next

	FileClose($hBlocks)

	GUICtrlSetData($lTodo, "Parsing Save Mod Blocks Done")
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub, 0)
EndFunc

Func __Parse_ModFilesForBlocks_Helper(Const $hBlocks, $sSBC)

	GUICtrlSetData($pTodoSub2, 0)

	Local $arSBC = StringSplit($sSBC, @CRLF, 1)
	If $arSBC[0] == 1 Then $arSBC = StringSplit($sSBC, @LF, 1)

	; find block
	Local $sBlockInfo = "", $bBlock = False
	For $i = 1 To $arSBC[0]
		GUICtrlSetData($pTodoSub2, ($i / $arSBC[0]) * 100)

		If Not StringInStr($arSBC[$i], "<SubtypeId>") Then ContinueLoop
		$sBlockInfo = StringReplace(StringReplace(StringReplace(StringReplace($arSBC[$i], "<SubtypeId>", ''), "</SubtypeId>", ''), ' ', ''), @TAB, '') & '='

		; find component section
		For $iS = $i + 1 To $arSBC[0]
			If StringInStr($arSBC[$iS], "</Definition>") Then ExitLoop
			If Not StringInStr($arSBC[$iS], "<Components>") Then ContinueLoop

			$bBlock = True

			; find all components
			For $iD = $iS + 1 To $arSBC[0]
				if StringInStr($arSBC[$iD], "</Components>") Then ExitLoop
				$sBlockInfo &= __Parse_GameFilesForBlocks_Helper($arSBC[$iD]) & ';'
			Next
		Next

		If Not $bBlock Then ContinueLoop
		$bBlock = False

		FileWrite($hBlocks, $sBlockInfo & @CRLF)
	Next

	GUICtrlSetData($pTodoSub2, 100)
EndFunc

Func __Parse_AllModFilesForBlocks_Helper(Const $hBlocks, $sSBC, $sMod)

	GUICtrlSetData($pTodoSub2, 0)

	Local $arSBC = StringSplit($sSBC, @CRLF, 1)
	If $arSBC[0] == 1 Then $arSBC = StringSplit($sSBC, @LF, 1)

	; find block
	Local $sBlockInfo = "", $bBlock = False
	For $i = 1 To $arSBC[0]
		GUICtrlSetData($pTodoSub2, ($i / $arSBC[0]) * 100)
		If Not StringInStr($arSBC[$i], "<SubtypeId>") Then ContinueLoop
		$sBlockInfo = StringReplace(StringReplace(StringReplace(StringReplace($arSBC[$i], "<SubtypeId>", ''), "</SubtypeId>", ''), ' ', ''), @TAB, '') & '=' & $sMod & '='

		; find component section
		For $iS = $i + 1 To $arSBC[0]
			If StringInStr($arSBC[$iS], "</Definition>") Then ExitLoop
			If Not StringInStr($arSBC[$iS], "<Components>") Then ContinueLoop

			$bBlock = True

			; find all components
			For $iD = $iS + 1 To $arSBC[0]
				if StringInStr($arSBC[$iD], "</Components>") Then ExitLoop
				$sBlockInfo &= __Parse_GameFilesForBlocks_Helper($arSBC[$iD]) & ';'
			Next
		Next

		If Not $bBlock Then ContinueLoop
		$bBlock = False

		FileWrite($hBlocks, $sBlockInfo & @CRLF)
	Next

	GUICtrlSetData($pTodoSub2, 100)
EndFunc

Func __Parse_GameFilesForBlocks(Const $sfPath)

	GUICtrlSetData($lTodo, "Parsing Vanilla Blocks")
	GUICtrlSetData($pTodo, 0)

	Local $hBlocks = FileOpen($__sfVanillaBlocks, 2)

	Local $hFileSearch = FileFindFirstFile($sfPath & '\*.sbc'), $sCurrentFile = "", $hOpen, $arContent[0], $sBlockInfo = "" ; BlockName=Component1-Amount;Component2-Amount;
	While True
		$sCurrentFile = FileFindNextFile($hFileSearch)
		if @error Then ExitLoop
		if $sCurrentFile == "CubeBlocks.sbc" Then ContinueLoop

		GUICtrlSetData($lTodo, "Parsing Vanilla Blocks " & $sCurrentFile)
		GUICtrlSetData($pTodo, 0)

		$hOpen = FileOpen($sfPath & "\" & $sCurrentFile, 0)
		$arContent = StringSplit(FileRead($hOpen), @CRLF, 1)
		FileClose($hOpen)

		; for the content of the file
		For $i = 1 To $arContent[0]

			GUICtrlSetData($pTodoSub, ($i / $arContent[0]) * 100)

			; no block found
			If Not StringInStr($arContent[$i], "<SubtypeId>") Then ContinueLoop

			; block found
			$sBlockInfo = StringReplace(StringReplace(StringReplace(StringReplace($arContent[$i], "<SubtypeId>", ''), "</SubtypeId>", ''), ' ', ''), @TAB, '') & '='

			; find the components section of the block
			For $iS = $i To $arContent[0]

				; if once the end of the definition is reached exitloop
				If StringInStr($arContent[$iS], "</Definition>") Then ExitLoop

				if Not StringInStr($arContent[$iS], "<Components>") Then ContinueLoop

				; for the components
				For $iD = $iS + 1 To $arContent[0]
					GUICtrlSetData($pTodo, ($iD / $arContent[0]) * 100)

					; until end
					if StringInStr($arContent[$iD], "</Components>") Then ExitLoop
					$sBlockInfo &= __Parse_GameFilesForBlocks_Helper($arContent[$iD]) & ';'
				Next
			Next

			; write the found block and its contents to file
			FileWrite($hBlocks, $sBlockInfo & @CRLF)
		Next

	WEnd

	FileClose($hFileSearch)
	FileClose($hBlocks)
	GUICtrlSetData($pTodo, 100)
	GUICtrlSetData($pTodoSub, 0)

EndFunc

Func __Parse_GameFilesForBlocks_Helper($sLine)
	Local $sItem = "", $sAmount = ""

	$sLine = StringTrimLeft($sLine, StringInStr($sLine, '"'))
	$sItem = StringLeft($sLine, StringInStr($sLine, '"') - 1)

	$sLine = StringTrimLeft($sLine, StringLen($sItem) + 1)
	$sLine = StringTrimLeft($sLine, StringInStr($sLine, '"'))
	$sAmount = StringLeft($sLine, StringInStr($sLine, '"') - 1)

	Return $sItem & '-' & $sAmount
EndFunc
#EndRegion


#Region External Funcs
;Author: Oscar (Autoit.de)
Func _RecursiveFileListToArray($sPath, $sPattern, $iFlag = 0, $iFormat = 1, $sDelim = @CRLF)
	Local $hSearch, $sFile, $sReturn = ''
	If StringRight($sPath, 1) <> '\' Then $sPath &= '\'
	$hSearch = FileFindFirstFile($sPath & '*.*')
	If @error Or $hSearch = -1 Then Return SetError(1, 0, $sReturn)
	While True
		$sFile = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		If StringInStr(FileGetAttrib($sPath & $sFile), 'D') Then
			If StringRegExp($sPath & $sFile, $sPattern) And ($iFlag = 0 Or $iFlag = 2) Then $sReturn &= $sPath & $sFile & '\' & $sDelim
			$sReturn &= _RecursiveFileListToArray($sPath & $sFile & '\', $sPattern, $iFlag, 0)
			ContinueLoop
		EndIf
		If StringRegExp($sFile, $sPattern) And ($iFlag = 0 Or $iFlag = 1) Then $sReturn &= $sPath & $sFile & $sDelim
	WEnd
	FileClose($hSearch)
	If $iFormat Then Return StringSplit(StringTrimRight($sReturn, StringLen($sDelim)), $sDelim, $iFormat)
	Return $sReturn
EndFunc   ;==>_RecursiveFileListToArray
#EndRegion

#Region WM_Notify
Func _WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	Local $tStruct = DllStructCreate($tagNMHDR, $lParam)
	Local $hWndFrom = DllStructGetData($tStruct, 1)
	Local $iCode = BitAND(DllStructGetData($tStruct, 3), 0xFFFFFFFF)

	If Not $hWndFrom == $GUI Then Return

	Switch $iCode

		Case $NM_RCLICK

			Local $nIndex = -1
			Switch _WM_NOTIFY_Helper()

				Case -1
					Return

				Case 1 ; bpblocks
					$nIndex = @extended
					Local $hMenu = _GUICtrlMenu_CreatePopup()
					_GUICtrlMenu_InsertMenuItem($hMenu, 0, "Find Mod", 1000)

					Switch _GUICtrlMenu_TrackPopupMenu($hMenu, $eBPBlocks, -1, -1, 1, 1, 2)

						Case 1000
							Local $sBlock = _Internal_FindBlock(_GUICtrlListView_GetItem($eBPBlocks, $nIndex)[3])
							If $sBlock Then
								If MsgBox(64 + 4, "Success", "ModID: " & $sBlock & @CRLF & @CRLF & "Open Steam workshop?") == 6 Then
									ShellExecute(StringReplace("https://steamcommunity.com/workshop/filedetails/?id=%", '%', $sBlock))
								EndIf
							Else
								MsgBox(64, "Error", "Did not find mod")
							EndIf

					EndSwitch

					_GUICtrlMenu_DestroyMenu($hMenu)

				Case 2 ; missing mods
					$nIndex = @extended
					Local $hMenu = _GUICtrlMenu_CreatePopup()
					_GUICtrlMenu_InsertMenuItem($hMenu, 0, "Show Affected Blocks", 1000)

					Switch _GUICtrlMenu_TrackPopupMenu($hMenu, $eMissingMods, -1, -1, 1, 1, 2)

						Case 1000
							Local $sMod = _GUICtrlListView_GetItem($eMissingMods, $nIndex)[3]
							Local $arMods = _storageMLi_GetElements($sMod)
							Local $sText = ""
							For $i = 0 To UBound($arMods) - 1
								$sText &= $arMods[$i] & @CRLF
							Next

							Switch $sMod

								Case "Unknown Mod"
									MsgBox(64, "Unknown Mod blocks", "Blocks are Unknown when no mod on your computer could be found defining them." & @CRLF & @CRLF & $sText)

								Case Else
									If MsgBox(64 + 4, "Missing Blocks for ID " & $sMod, "Open Steam workshop?" & @CRLF & @CRLF & $sText) == 6 Then
										ShellExecute(StringReplace("https://steamcommunity.com/workshop/filedetails/?id=%", '%', $sMod))
									EndIf

							EndSwitch


					EndSwitch

					_GUICtrlMenu_DestroyMenu($hMenu)

				Case 3 ; save mods
					$nIndex = @extended
					Local $hMenu = _GUICtrlMenu_CreatePopup()
					_GUICtrlMenu_InsertMenuItem($hMenu, 0, "Open Steam workshop", 1000)

					Switch _GUICtrlMenu_TrackPopupMenu($hMenu, $eSaveMods, -1, -1, 1, 1, 2)

						Case 1000
							Local $sMod = _GUICtrlListView_GetItem($eSaveMods, $nIndex)[3]
							ShellExecute(StringReplace("https://steamcommunity.com/workshop/filedetails/?id=%", '%', $sMod))


					EndSwitch

					_GUICtrlMenu_DestroyMenu($hMenu)

				Case 4 ; missing blocks
					$nIndex = @extended
					Local $hMenu = _GUICtrlMenu_CreatePopup()
					_GUICtrlMenu_InsertMenuItem($hMenu, 0, "Find Mod", 1000)

					Switch _GUICtrlMenu_TrackPopupMenu($hMenu, $eMissingBlocks, -1, -1, 1, 1, 2)

						Case 1000
							Local $sBlock = _Internal_FindBlock(_GUICtrlListView_GetItem($eMissingBlocks, $nIndex)[3])
							If $sBlock Then
								If MsgBox(64 + 4, "Success", "ModID: " & $sBlock & @CRLF & @CRLF & "Open Steam workshop?") == 6 Then
									ShellExecute(StringReplace("https://steamcommunity.com/workshop/filedetails/?id=%", '%', $sBlock))
								EndIf
							Else
								MsgBox(64, "Error", "Did not find mod")
							EndIf

					EndSwitch

					_GUICtrlMenu_DestroyMenu($hMenu)

			EndSwitch

	EndSwitch
EndFunc   ;==>_WM_NOTIFY

Func _WM_NOTIFY_Helper()
	Local $aHit = _GUICtrlListView_HitTest($eBPBlocks)
	If $aHit[0] <> -1 Then Return SetExtended($aHit[0], 1)
	$aHit = _GUICtrlListView_HitTest($eMissingMods)
	if $aHit[0] <> -1 Then Return SetExtended($aHit[0], 2)
	$aHit = _GUICtrlListView_HitTest($eSaveMods)
	if $aHit[0] <> -1 Then Return SetExtended($aHit[0], 3)
	$aHit = _GUICtrlListView_HitTest($eMissingBlocks)
	if $aHit[0] <> -1 Then Return SetExtended($aHit[0], 4)

	Return -1
EndFunc
#EndRegion