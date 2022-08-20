#include-once
#include <Array.au3> ; for development of this UDF

; Repo: https://github.com/OfficialLambdax/_storageS-UDF

#Region Init
Global Const $__storageS_sVersion = "0.2.4"
Global $__storageS_O_Dictionaries = ObjCreate("Scripting.Dictionary") ; holds all storages
Global $__storageS_OL_Dictionaries = ObjCreate("Scripting.Dictionary") ; holds all lists
Global $__storageS_ALR_Array[1e6] ; ALRapid works on a single array
Global $__storageS_ALR_Index = 0 ; latest element
Global $__storageS_GO_PosObject = ObjCreate("Scripting.Dictionary") ; holds the positions for each go storage
Global $__storageS_GO_IndexObject = ObjCreate("Scripting.Dictionary") ; holds all free storages
Global $__storageS_GO_GroupObject = ObjCreate("Scripting.Dictionary") ; holds all groups
Global $__storageS_GO_Size = 0 ; the current size of the GO storage. Can never decrease
Global $__storageS_GM_PosMap[]
Global $__storageS_GM_IndexMap[]
Global $__storageS_GM_Size = 0
Global $__storageS_RBx_Array = False ; RBx works on a single array
Global $__storageS_RBx_WritePos = False ; holds the write pos
Global $__storageS_RBx_ReadPos = False ; holds the read pos
Global $__storageS_AO_StorageArray = False ; AO works on a single array
Global $__storageS_AO_PosObject = ObjCreate("Scripting.Dictionary") ; holds the positions for each ao storage
Global $__storageS_AO_IndexObject = ObjCreate("Scripting.Dictionary") ; holds all free storages
Global $__storageS_AO_GroupObject = ObjCreate("Scripting.Dictionary") ; holds all groups
Global $__storageS_AO_Size = 0 ; the current size of the AO storage. Can decrease
Global $__storageS_ML_Maps = False ; Holds all maps


__storageGO_Startup() ; needs to be called first, since other methods are based on GO
__storageAL_Startup()
__storageAO_Startup()
__storageML_Startup()
__storageS_AntiCE_Startup()
__storageS_StripFix()
#EndRegion


#cs
	You can use CTRL + J to go quickly to a method within SciTE

	Standard Data Storage
		_storageGO_CreateGroup()			- Allrounder using managed Dynamic Globals - Quick, Memory and Cpu friendly

		Specialized
			_storageG_Overwrite()			- Quickest Write/Read method that comes with downsides
			_storageAO_CreateGroup()		- Uses a managed Dynamic Global Array. For when you dont like GO
			_storageO_CreateGroup()			- To be overhauled

		Experimental
			_storageGM_CreateGroup()		- Experimental Allrounder using Dynamic Globals - Quicker, Memory and Cpu friendly
			_storageGi_CreateGroup()		- Experimental G improvement that comes with less downsides
			_storageGx_Overwrite()			- Experimental Non Indexed Global storage


	Standard List Storage
		_storageOL_CreateGroup()			- To be removed and replaced by OLi

		Specialized
			_storageML_CreateGroup()		- Quickest Exists check method. Bad in everything else. Size limited < 1e5
			_storageAL_CreateGroup()		- To be overhauled
			_storageALR_AddElement()		- AL addon - to be removed
			_storageGLx_AddElement()		- Creates Lists with no Index. Lists can be as big as your ram has space.

		Experimental
			_storageOLi_CreateGroup()		- Experimental Allrounder for small to large lists
			_storageOLx_CreateGroup()		- To be removed (List item can have extra data)
			_storageMLi_CreateGroup()		- Experimental Faster Allrounder for small lists (< 1e5)
			_storageMLx_CreateGroup()		- To be removed (List item can have extra data)


	Standard Ring Buffer
		_storageRBr_CreateGroup()			- Ring Buffer that is not stored in Memory
		_storageRBx_Init()					- Single Ring Buffer that is stored in memory

		Experimental
			_storageRBs_CreateGroup()		- To be overhauled


	Miscellaneous Functions
		_storageS_GetVarSize()				- Returns a likely not correct size of the given Variable
		_storageS_AntiCECheck()				- For Execute() functions to prevent misuses
		_storageS_AntiCEAdd()				- To add custom entries to the CECheck


	Note _

	Some storage methods have derivations of them or are combis of multiple. These are usually indicated with a lower char at the end.
	Like OLi, OLx, MLi, MLx. Their code is usually much different and exists to either generally improve a method or to extended
	just a specific strength for the cost of another - or in some cases to add additional functionality.
#ce

; ===============================================================================================================================
#Region Data Storages
#cs
	Standard Data storages are storages that are fast with any kind of data. From any type
	to any size. And these storages do not suffer from the amount of storages that might exist
	at a time. Another criteria is that they provide support for a long runtime.

	Specialized Data storages are storages that are either good in just one or in multiple
	fields, and suffer in the rest. You could choose a specialized method to optimise your entire or a part
	of your script.
#ce

; ==================================================================
#Region Standard Methods

#Region _storageGO		Reuse Assign / Eval Method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageGO describtion

	You can use GO if you are constantly creating new storages and remove old. Each new storage reuses a old. Entirely new
	storages are only created when no old are available.

	Works on top of Dynamic Global variables. Variables seem to profit from Copy on Write in Autoit. Meaning that
	storages with the exact same data are often only put once into memory. Resulting in not just less memory being used
	but the writes being also faster.

	(Combi of Global Variables and the Dictionary Object)
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_CreateGroup
; Description ...: Creates the Group. Needs to be called.
; Syntax ........: _storageGO_CreateGroup($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: True					= If Success
;                : False				= If the group is already present
; Modified ......:
; Remarks .......: If the Group is not present then no storage for it can be created.
; Example .......: No
; ===============================================================================================================================
Func _storageGO_CreateGroup($vElementGroup)
	If $__storageS_GO_GroupObject.Exists('g' & $vElementGroup) Then Return False

	$oGroupVars = ObjCreate("Scripting.Dictionary")
	$__storageS_GO_GroupObject('g' & $vElementGroup) = $oGroupVars

	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_Overwrite
; Description ...: Writes data to the Elementname of the Element group
; Syntax ........: _storageGO_Overwrite($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Errors ........: 1						- $vElementGroup is not created or got destroyed.
;                : 2						- $vElementData is False. Not an issue because _storageGO_Read() will return False anyway.
;                :							  This is a feature to reduce globals use.
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGO_Overwrite($vElementGroup, $sElementName, $vElementData)

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	; if the var is not known then claim one
	If Not $__storageS_GO_PosObject.Exists($sVarName) Then

		; if the element data is False then we wont claim a storage
		If $vElementData == False Then Return SetError(2, 0, False)

		; if the group addition fails then return False
		If Not __storageGO_AddGroupVar($vElementGroup, $sElementName) Then Return SetError(1, 0, False)

		; if no free storage is available then create a new storage
		If $__storageS_GO_IndexObject.Count == 0 Then

			; increase size
			$__storageS_GO_Size += 1

			; claim it
			$__storageS_GO_PosObject($sVarName) = $__storageS_GO_Size

			; assign and return
			Return Assign('__storageGO_' & $__storageS_GO_Size, $vElementData, 2)

		Else ; pick a free storage

			; eh, how do i pick the first element in a dictobj
			For $i In $__storageS_GO_IndexObject
				Local $nPos = $i
				ExitLoop
			Next

			; claim it
			$__storageS_GO_IndexObject.Remove($nPos)
			$__storageS_GO_PosObject($sVarName) = $nPos

			; assign data and return
			Return Assign('__storageGO_' & $nPos, $vElementData, 2)

		EndIf

	Else ; if its known then assign the data

		Return Assign('__storageGO_' & $__storageS_GO_PosObject($sVarName), $vElementData, 2)

	EndIf

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_ByRef
; Description ...: (Experimental) Allows for direct edits of a data storage
; Syntax ........: _storageGO_ByRef($vElementGroup, $sElementName, $sFuncName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $sFuncName         	    - (String) Function Name
;                  $vAdditionalData			- (Optional) Extra data given to the Func in $sFuncName
; Return values .: None
; Modified ......:
; Remarks .......: Func _Example(Byref $vStorageData, $vElementGroup, $vAdditionalData)
; Example .......: No
; ===============================================================================================================================
Func _storageGO_ByRef($vElementGroup, $sElementName, $sFuncName, $vAdditionalData = Null)
	Local $sVarName = 'g' & $vElementGroup & $sElementName

	If Not $__storageS_GO_PosObject.Exists($sVarName) Then Return False

;~ 	Return Execute($sFuncName & '($vElementGroup, $sElementName, $__storageGO_' & $__storageS_GO_PosObject($sVarName) & ')')
	Return Execute($sFuncName & '($__storageGO_' & $__storageS_GO_PosObject($sVarName) & ',$vElementGroup,$vAdditionalData)')
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_Append
; Description ...: Appends data to the Elementname of the Element group
; Syntax ........: _storageGO_Append($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Append as in "Hello " & "World" = "Hello World"
; Example .......: _storageGO_Overwrite(123, 'testdata', "Hello ")
;                : _storageGO_Append(123, 'testdata', "World")
; ===============================================================================================================================
Func _storageGO_Append($vElementGroup, $sElementName, $vElementData)

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	If Not $__storageS_GO_PosObject.Exists($sVarName) Then Return _storageGO_Overwrite($vElementGroup, $sElementName, $vElementData)

	Local $nPos = $__storageS_GO_PosObject($sVarName)
	Return Assign('__storageGO_' & $nPos, Eval('__storageGO_' & $nPos) & $vElementData, 2)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_Calc
; Description ...: X operator Y. Where X is what is already stored and Y the $vElementData
; Syntax ........: _storageGO_Calc($vElementGroup, $sElementName, $vElementData, $Operator)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $vElementData        - (Variable) Element Data aka Y
;                  $Operator            - (String) + - * / ^ etc.
;                  $bSwitch             - True / False. Switches X with Y if True.
;                  $bSave				- True / False. If True will store the result.
; Return values .: The Result of the Operation
;                : ""					= If the operation failed
;                : False				= If the Element is unknown
; Modified ......:
; Remarks .......:
; Example .......: _storageGO_Overwrite(123, 'testinteger', 1)
;                : _storageGO_Calc(123, 'testinteger', 2, '+')
; ===============================================================================================================================
Func _storageGO_Calc($vElementGroup, $sElementName, $vElementData, $Operator, $bSwitch = False, $bSave = True)
	Local $sVarName = 'g' & $vElementGroup & $sElementName

	If Not IsDeclared($sVarName) Then Return False
	Local $nPos = $__storageS_GO_PosObject($sVarName)

	if $bSwitch Then
		Local $vCalc = Execute("$vElementData" & $Operator & Eval('__storageGO_' & $nPos))
	Else
		Local $vCalc = Execute(Eval('__storageGO_' & $nPos) & $Operator & "$vElementData")
	EndIf

	If $bSave Then Assign('__storageGO_' & $nPos, $vCalc, 2)
	Return $vCalc
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_Read
; Description ...: Returns the data for the element name of the element group
; Syntax ........: _storageGO_Read($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
; Return values .: The data					= If success
; Errors ........: 1						- If the variable isnt present.
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGO_Read($vElementGroup, $sElementName)

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	; check if the storage exists
	If Not $__storageS_GO_PosObject.Exists($sVarName) Then Return SetError(1, 0, False)

	Return Eval('__storageGO_' & $__storageS_GO_PosObject($sVarName))

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_GetGroupVars
; Description ...: Returns a 2D array of size [n][3] containing the elements stored for the Element group
; Syntax ........: _storageGO_GetGroupVars($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: 2D array					= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Array looks like this
;                : [n][0]					= Element name
;                : [n][1]					= Element Variable Type
;                : [n][2]					= Element Variable Data
; Example .......: _storageGO_GetGroupVars(123)
; ===============================================================================================================================
Func _storageGO_GetGroupVars($vElementGroup)

	$vElementGroup = 'g' & $vElementGroup

	If Not $__storageS_GO_GroupObject.Exists($vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_GO_GroupObject($vElementGroup)

	Local $arGroupVars2D[$oElementGroup.Count][3], $nCount = 0, $nPos = 0
	For $i In $oElementGroup
		$arGroupVars2D[$nCount][0] = $i

		$nPos = $__storageS_GO_PosObject($vElementGroup & $i)

		$arGroupVars2D[$nCount][1] = VarGetType(Eval('__storageGO_' & $nPos))
		$arGroupVars2D[$nCount][2] = Eval('__storageGO_' & $nPos)

		$nCount += 1
	Next

	Return $arGroupVars2D

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_TidyGroupVars
; Description ...: Tidies all storages of the given group
; Syntax ........: _storageGO_TidyGroupVars($vElementGroup)
; Parameters ....: $vElementGroup       - Element Group
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGO_TidyGroupVars($vElementGroup)

	If Not $__storageS_GO_GroupObject.Exists('g' & $vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_GO_GroupObject('g' & $vElementGroup)

	$vElementGroup = 'g' & $vElementGroup

	For $i In $oElementGroup
		Assign('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & $i), Null, 2)
	Next

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_DestroyGroup
; Description ...: Tidies and Frees all storages of the given group
; Syntax ........: _storageGO_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - Element Group
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGO_DestroyGroup($vElementGroup)

	If Not $__storageS_GO_GroupObject.Exists('g' & $vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_GO_GroupObject('g' & $vElementGroup)

	Local $nPos = 0
	For $i In $oElementGroup

		; get pos
		$nPos = $__storageS_GO_PosObject('g' & $vElementGroup & $i)

		; tidy storage
		Assign('__storageGO_' & $nPos, Null, 2)

		; add as free storage to the index object
		$__storageS_GO_IndexObject($nPos)

		; remove element from group
		$oElementGroup.Remove($i)

		; remove element from pos object
		$__storageS_GO_PosObject.Remove('g' & $vElementGroup & $i)
	Next

	; remove group
	$__storageS_GO_GroupObject.Remove('g' & $vElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_DestroyVar
; Description ...: Tidies and frees the given var from the given group
; Syntax ........: _storageGO_DestroyVar($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGO_DestroyVar($vElementGroup, $sElementName)

	If Not $__storageS_GO_GroupObject.Exists('g' & $vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_GO_GroupObject('g' & $vElementGroup)

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	If Not $__storageS_GO_PosObject.Exists($sVarName) Then Return False
	Local $nPos = $__storageS_GO_PosObject($sVarName)

	Assign('__storageGO_' & $nPos, Null, 2)

	$__storageS_GO_PosObject.Remove($sVarName)
	$__storageS_GO_IndexObject($nPos)

	$oElementGroup.Remove(String($sElementName))
	$__storageS_GO_GroupObject('g' & $vElementGroup) = $oElementGroup

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_GetClaimedVars
; Description ...: Returns all claimed variables in a 2D array
; Syntax ........: _storageGO_GetClaimedVars()
; Parameters ....: None
; Return values .: 2D array					= If success
;                : False					= If none
; Modified ......:
; Remarks .......: Array looks like this
;                : [n][0]					= Element name
;                : [n][1]					= Element Variable Type
;                : [n][2]					= Element Variable Data
;                :
;                : This is a debug feature to find memory leaks
; Example .......: No
; ===============================================================================================================================
Func _storageGO_GetClaimedVars()

	Local $arGroupVars2D[$__storageS_GO_PosObject.Count][3], $nCount = 0, $nPos = 0
	If UBound($arGroupVars2D) == 0 Then Return False

	For $i In $__storageS_GO_PosObject
		$arGroupVars2D[$nCount][0] = StringTrimLeft($i, 1)

		$nPos = $__storageS_GO_PosObject($i)

		$arGroupVars2D[$nCount][1] = VarGetType(Eval('__storageGO_' & $nPos))
		$arGroupVars2D[$nCount][2] = Eval('__storageGO_' & $nPos)

		$nCount += 1
	Next

	Return $arGroupVars2D

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGO_GetInfo
; Description ...: Returns various informations of the GO method.
; Syntax ........: _storageGO_GetInfo($nMode)
; Parameters ....: $nMode               - (Int) the Mode
;                : 1					- Returns the amount of existing storages
;                : 2					- Returns the amount of free storages
;                : 3					- Returns the amount of claimed storages
;                : 4					- Returns the Size in Bytes of all claimed storages (CPU intensive)
; Return values .: The Result			= as Int
;                : False				= If an invalid option got used
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
; note: i should take into consideration that repeated data isnt put into memory again
Func _storageGO_GetInfo($nMode)

	Switch $nMode

		Case 1 ; amount of existing storage vars
			Return $__storageS_GO_Size

		Case 2 ; free storage vars
			Return $__storageS_GO_IndexObject.Count

		Case 3 ; claimed storage vars
			Return $__storageS_GO_PosObject.Count

		Case 4 ; size of claimes storage vars
			Local $nSize = 0
			For $i In $__storageS_GO_PosObject
				$nSize += _storageS_GetVarSize(Eval('__storageGO_' & $__storageS_GO_PosObject($i)))
			Next

			Return $nSize

	EndSwitch

EndFunc
#EndRegion
#EndRegion

; ==================================================================
#Region Specialized Methods

#Region _storageG 		Assign / Eval Method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageG Description

	- Fastest Data storage but not recommended for non specific usages
	- Profits from, what seems like, Copy on Write
	- Gets faster once the storage exists
	- Not good for a long runtime if you constantly create new storages, no matter if you remove old.
	  If you do choose to use this method for a long runtime script then reuse the same storages.
	- Each Removed Storage is a memory leak until it is reclaimed again !

#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Overwrite
; Description ...: Writes data to the Elementname of the Element group
; Syntax ........: _storageS_Overwrite($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......: If $vElementData is == False then the Variable is not declared because _storageS_Read() would
;                : return False then anyway. This is done to prevent the declaration of unnecessary global variables.
; Example .......: _storageG_Overwrite(123, 'testdata', "hello world")
; ===============================================================================================================================
Func _storageG_Overwrite($vElementGroup, $sElementName, $vElementData)
    Local $sVarName = "__storageS_" & $vElementGroup & $sElementName

    ; we wont declare vars if $vElementData is False because _storageS_Read() always returns False and @error 1 on undeclared vars
;~     If $vElementData == False And Not IsDeclared($sVarName) Then Return True
    If Not IsDeclared($sVarName) Then __storageG_AddGroupVar($vElementGroup, $sElementName)

    Return Assign($sVarName, $vElementData, 2)
EndFunc   ;==>_storageS_Overwrite


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Append
; Description ...: Appends data to the Elementname of the Element group
; Syntax ........: _storageS_Append($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Append as in "Hello " & "World" = "Hello World"
; Example .......: _storageG_Append(123, 'testdata', "hello world again")
; ===============================================================================================================================
Func _storageG_Append($vElementGroup, $sElementName, $vElementData)
    Local $sVarName = "__storageS_" & $vElementGroup & $sElementName

    If Not IsDeclared($sVarName) Then Return _storageG_Overwrite($vElementGroup, $sElementName, $vElementData)

    Return Assign($sVarName, Eval($sVarName) & $vElementData, 2)
EndFunc   ;==>_storageS_Append


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Calc
; Description ...: X operator Y. Where X is what is already stored and Y the $vElementData
; Syntax ........: _storageG_Calc($vElementGroup, $sElementName, $vElementData, $Operator)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $vElementData        - (Variable) Element Data aka Y
;                  $Operator            - (String) + - * / ^ etc.
;                  $bSwitch             - True / False. Switches X with Y if True.
;                  $bSave				- True / False. If True will store the result.
; Return values .: The Result of the Operation
;                : ""					= if the operation failed
;                : False				= If the Element is unknown
; Modified ......:
; Remarks .......:
; Example .......: _storageG_Overwrite(123, 'testinteger', 1)
;                : _storageG_Calc(123, 'testinteger', 2, '+')
; ===============================================================================================================================
Func _storageG_Calc($vElementGroup, $sElementName, $vElementData, $Operator, $bSwitch = False, $bSave = True)
	Local $sVarName = "__storageS_" & $vElementGroup & $sElementName

;~ 	If Not IsDeclared($sVarName) Then Return _storageG_Overwrite($vElementGroup, $sElementName, $vElementData)
	If Not IsDeclared($sVarName) Then Return False

	if $bSwitch Then
		Local $vCalc = Execute("$vElementData" & $Operator & Eval($sVarName))
	Else
		Local $vCalc = Execute(Eval($sVarName) & $Operator & "$vElementData")
	EndIf

	If $bSave Then Assign($sVarName, $vCalc, 2)
	Return $vCalc
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Execute
; Description ...: Like Cosinos the stored element. Also works with other Functions.
; Syntax ........: _storageG_Execute($vElementGroup, $sElementName, $Math)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $Operation           - (String) Cos Sin Mod Log Exp etc.
;                  $bSave				- True / False. If True will store the result.
; Return values .: The Result of the Operation
;                : ""					= if the operation failed
;                : False				= If the Element is unknown or when error
; Errors ........: 1					= $Operation String is blacklisted
; Modified ......:
; Remarks .......: CODE EXECUTION VULNERABLE (CE). Please ensure the input and storage data is no code.
;                :
;                : Functions like Ceiling() or Floor() also work just like your own Functions.
; Example .......: _storageG_Overwrite(123, 'testinteger', 3)
;                : _storageG_Execute(123, 'testinteger, "Cos")
;                : Or _storageG_Execute(123, 'testinteger, "_MyMathFunc")
; ===============================================================================================================================
Func _storageG_Execute($vElementGroup, $sElementName, $Operation, $bSave = True)
	Local $sVarName = "__storageS_" & $vElementGroup & $sElementName

	If Not IsDeclared($sVarName) Then Return False

	If _storageS_AntiCECheck($Operation) Then Return SetError(1, 0, False)

	Local $vCalc = Execute($Operation & "(" & Eval($sVarName) & ")")

	If $bSave Then Assign($sVarName, $vCalc)
	Return $vCalc
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Read
; Description ...: Returns the data for the element name of the element group
; Syntax ........: _storageS_Read($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
; Return values .: The data					= If success
; Errors ........: 1						- If the variable isnt present.
; Modified ......:
; Remarks .......: If _storageG_Overwrite() was called with data that was Bool False then the variable wasnt declared.
; Example .......: _storageG_Read(123, 'testdata')
; ===============================================================================================================================
Func _storageG_Read($vElementGroup, $sElementName)
    Local $sVarName = "__storageS_" & $vElementGroup & $sElementName

    If Not IsDeclared($sVarName) Then Return SetError(1, 0, False)
    Return Eval($sVarName)
EndFunc   ;==>_storageS_Read


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_TidyGroupVars
; Description ...: Tidies all Variables of the given element group
; Syntax ........: _storageS_TidyGroupVars($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: None
; Modified ......:
; Remarks .......: The global variables keep existent, but they are overwritten with Null.
;                : Because there is no way to delete Global variables.
; Example .......: _storageG_TidyGroupVars(123)
; ===============================================================================================================================
Func _storageG_TidyGroupVars($vElementGroup)
    Local $oGroupVars = Eval("StorageS" & $vElementGroup)
    If Not IsObj($oGroupVars) Then Return

	Local $sVarName = "__storageS_" & $vElementGroup

	For $i In $oGroupVars
		Assign($sVarName & $i, Null, 2)
	Next
EndFunc   ;==>_storageS_TidyGroupVars


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_DestroyGroup
; Description ...: Tidies the Group variables and then Destroys the Group Object
; Syntax ........: _storageG_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......: The Variables stay declared, but if they are to be never used again then you can also
;                : destroy the Object that they are stored in to free the ram.
;                : If you do however use them again then they will not be readded because only undeclared variables are added.
;                : Using IsDeclared() is simply much faster then using Eval().
; Example .......: No
; ===============================================================================================================================
Func _storageG_DestroyGroup($vElementGroup)

	_storageG_TidyGroupVars($vElementGroup)
	Assign("StorageS" & $vElementGroup, Null, 2)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_GetGroupVars
; Description ...: Returns a 2D array of size [n][3] containing the elements stored for the Element group
; Syntax ........: _storageG_GetGroupVars($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: 2D array					= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Array looks like this
;                : [n][0]					= Element name
;                : [n][1]					= Element Variable Type
;                : [n][2]					= Element Variable Data
; Example .......: _storageG_GetGroupVars(123)
; ===============================================================================================================================
Func _storageG_GetGroupVars($vElementGroup)

	Local $oElementGroup = Eval("StorageS" & $vElementGroup)
	If Not IsObj($oElementGroup) Then Return False

	$vElementGroup = '__storageS_' & $vElementGroup

	Local $arGroupVars2D[$oElementGroup.Count][3], $nCount = 0
	For $i In $oElementGroup
		$arGroupVars2D[$nCount][0] = $i
		$arGroupVars2D[$nCount][1] = VarGetType(Eval($vElementGroup & $i))
		$arGroupVars2D[$nCount][2] = Eval($vElementGroup & $i)
		$nCount += 1
	Next

	Return $arGroupVars2D

EndFunc
#EndRegion


#Region _storageAO		Reuse Array method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageAO describtion

	- Fast Large Data storage
	- Slower on everything below 3 MB
	- Uses a single global Array as a storage
	- Gets faster once the storage exists
	- Storage creation is slow when _storageAO_ReDim() is not used.
	- _storageAO_Shorten() can shorten the entire storage size

	(Works like GO and GM)
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_CreateGroup
; Description ...: Creates a group
; Syntax ........: _storageAO_CreateGroup($vElementGroup)
; Parameters ....: $vElementGroup       - Group name
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_CreateGroup($vElementGroup)
	If $__storageS_AO_GroupObject.Exists('g' & $vElementGroup) Then Return False

	$oGroupVars = ObjCreate("Scripting.Dictionary")
	$__storageS_AO_GroupObject('g' & $vElementGroup) = $oGroupVars

	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_Overwrite
; Description ...: Adds or Overwrites the named Data storage of the given group
; Syntax ........: _storageAO_Overwrite($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
;                  $vElementData        - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_Overwrite($vElementGroup, $sElementName, $vElementData)

	If Not $__storageS_AO_GroupObject.Exists('g' & $vElementGroup) Then Return False

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	; if the pos is known then
	If $__storageS_AO_PosObject.Exists($sVarName) Then

		; store the data
		$__storageS_AO_StorageArray[$__storageS_AO_PosObject($sVarName)] = $vElementData
		Return True

	Else ; if it is not known

		; we wont save Bool False, to save time.
		if $vElementData == False Then Return SetError(1, 0, False)

		; if the group addition fails then return False
		If Not __storageAO_AddGroupVar($vElementGroup, $sElementName) Then Return SetError(1, 0, False)

		; if no free place is available then
		If $__storageS_AO_IndexObject.Count == 0 Then

			$__storageS_AO_Size += 1
			ReDim $__storageS_AO_StorageArray[$__storageS_AO_Size + 1]

			; claim pos
			$__storageS_AO_PosObject($sVarName) = $__storageS_AO_Size

			; save data
			$__storageS_AO_StorageArray[$__storageS_AO_Size] = $vElementData

			Return True

		Else ; if available

			For $i In $__storageS_AO_IndexObject
				Local $nPos = $i
				ExitLoop
			Next

			; remove free index
			$__storageS_AO_IndexObject.Remove($nPos)

			; claim pos
			$__storageS_AO_PosObject($sVarName) = $nPos

			; save data
			$__storageS_AO_StorageArray[$nPos] = $vElementData

			Return True

		EndIf

	EndIf

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_Append
; Description ...: Appends data the given storage of the given group
; Syntax ........: _storageAO_Append($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
;                  $vElementData        - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_Append($vElementGroup, $sElementName, $vElementData)

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	If Not $__storageS_AO_PosObject.Exists($sVarName) Then Return _storageAO_Overwrite($vElementGroup, $sElementName, $vElementData)

	$__storageS_AO_StorageArray[$__storageS_AO_PosObject($sVarName)] &= $vElementData
	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_Read
; Description ...: Reads the data of the given storage from the given group
; Syntax ........: _storageAO_Read($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_Read($vElementGroup, $sElementName)

	If Not $__storageS_AO_GroupObject.Exists('g' & $vElementGroup) Then Return False

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	; if the pos is known then
	If $__storageS_AO_PosObject.Exists($sVarName) Then
		Return $__storageS_AO_StorageArray[$__storageS_AO_PosObject($sVarName)]
	Else
		Return SetError(1, 0, False)
	EndIf

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_GetGroupVars
; Description ...: Returns all Storages of the given Group in a 2D array
; Syntax ........: _storageAO_GetGroupVars($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_GetGroupVars($vElementGroup)

	$vElementGroup = 'g' & $vElementGroup

	If Not $__storageS_AO_GroupObject.Exists($vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_AO_GroupObject($vElementGroup)

	Local $arGroupVars2D[$oElementGroup.Count][3], $nCount = 0, $nPos = 0
	For $i In $oElementGroup
		$arGroupVars2D[$nCount][0] = $i

		$nPos = $__storageS_AO_PosObject($vElementGroup & $i)

		$arGroupVars2D[$nCount][1] = VarGetType($__storageS_AO_StorageArray[$nPos])
		$arGroupVars2D[$nCount][2] = $__storageS_AO_StorageArray[$nPos]

		$nCount += 1
	Next

	Return $arGroupVars2D

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_TidyGroupVars
; Description ...: Tidies all storages of the given group
; Syntax ........: _storageAO_TidyGroupVars($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......: Only good for when you want to clean the memory, but not destroy the group.
; Example .......: No
; ===============================================================================================================================
Func _storageAO_TidyGroupVars($vElementGroup)

	$vElementGroup = 'g' & $vElementGroup

	If Not $__storageS_AO_GroupObject.Exists($vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_AO_GroupObject($vElementGroup)

	For $i In $oElementGroup
		$__storageS_AO_StorageArray[$__storageS_AO_PosObject($vElementGroup & $i)] = Null
	Next

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_DestroyVar
; Description ...: Tidies and Free's the given storage of the given group
; Syntax ........: _storageAO_DestroyVar($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_DestroyVar($vElementGroup, $sElementName)

	Local $sVarName = 'g' & $vElementGroup & $sElementName

	; if the pos is known then
	If $__storageS_AO_PosObject.Exists($sVarName) Then

		; remove from group
		Local $oElementGroup = $__storageS_AO_GroupObject('g' & $vElementGroup)
		$oElementGroup.Remove(String($sElementName))
		$__storageS_AO_GroupObject('g' & $vElementGroup) = $oElementGroup

		; free pos
		Local $nPos = $__storageS_AO_PosObject($sVarName)
		$__storageS_AO_StorageArray[$nPos] = Null
		$__storageS_AO_PosObject.Remove($sVarName)

		; add it as free to the index obj
		$__storageS_AO_IndexObject($nPos)

		Return True

	EndIf

	Return False
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_DestroyGroup
; Description ...: Tidies and Free's all Storages of the, including the, given group.
; Syntax ........: _storageAO_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_DestroyGroup($vElementGroup)

	If Not $__storageS_AO_GroupObject.Exists('g' & $vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_AO_GroupObject('g' & $vElementGroup)

	Local $nPos = 0
	For $i In $oElementGroup

		; get pos
		$nPos = $__storageS_AO_PosObject('g' & $vElementGroup & $i)

		; tidy storage
		$__storageS_AO_StorageArray[$nPos] = Null

		; add as free storage to the index object
		$__storageS_AO_IndexObject($nPos)

		; remove element from group
		$oElementGroup.Remove($i)

		; remove element from pos object
		$__storageS_AO_PosObject.Remove('g' & $vElementGroup & $i)
	Next

	; remove group
	$__storageS_AO_GroupObject.Remove('g' & $vElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_ReDim
; Description ...: Largens the Array to the specified size to greatly decrease the storage creation time
; Syntax ........: _storageAO_ReDim($nSize)
; Parameters ....: $nSize               - (Int) Must be greater then the current size
; Return values .: None
; Modified ......:
; Remarks .......: The current array size can be read with _storageAO_GetInfo(1). Can be used anytime.
; Example .......: No
; ===============================================================================================================================
Func _storageAO_ReDim($nSize)

	If $nSize <= $__storageS_AO_Size Then Return False

	ReDim $__storageS_AO_StorageArray[$nSize]
	For $i = $__storageS_AO_Size + 1 To $nSize
		$__storageS_AO_IndexObject($i)
	Next
	$__storageS_AO_Size = $nSize

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_Shorten
; Description ...: Shortens the Storage Array to the smallest size possible without destroying used storages
; Syntax ........: _storageAO_Shorten()
; Parameters ....: $bMax					- (Bool) True / False (More CPU Intensive, but shortens the array better)
; Return values .: None
; Modified ......:
; Remarks .......: Should only be called when required, duo to it being a iteration function which takes some time
; Example .......: No
; ===============================================================================================================================
Func _storageAO_Shorten($bMax = False)

	If $bMax Then

		Local $nLastIndex = $__storageS_AO_Size, $nIndex = -1, $nPos = -1

		; for each element in the array
		For $i = 0 To $__storageS_AO_Size

			; if the index is claimed then check the next
			If Not $__storageS_AO_IndexObject.Exists($i) Then ContinueLoop

			; otherwise locate a taken pos backwards
			$nIndex = -1
			For $iS = $nLastIndex To 0 Step - 1
				ConsoleWrite($iS & @CRLF)
				If Not $__storageS_AO_IndexObject.Exists($iS) Then
					$nIndex = $iS
					ExitLoop
				EndIf
			Next

			; if we found none then exitloop
			If $nIndex == -1 Then ExitLoop

			; update last found index, so that we wont search through already searched indexes
			$nLastIndex = $nIndex

			; make sure we are moving a higher index
			If $i >= $nIndex Then ExitLoop

			; find the storage in the pos object
			$nPos = -1
			For $iS In $__storageS_AO_PosObject
				If $__storageS_AO_PosObject($iS) == $nIndex Then
					$nPos = $iS
					ExitLoop
				EndIf
			Next

			; that shouldnt happen
			If $nPos == -1 Then ExitLoop

			; move data
			$__storageS_AO_StorageArray[$i] = $__storageS_AO_StorageArray[$nIndex]

			; change index in pos object
			$__storageS_AO_PosObject($nPos) = $i

			; and tidy var
			$__storageS_AO_StorageArray[$nIndex] = Null

		Next

		If $nLastIndex + 1 == $__storageS_AO_Size Then Return
		ReDim $__storageS_AO_StorageArray[$nLastIndex]

	Else

		Local $nLastIndex = -1

		For $i In $__storageS_AO_PosObject
			If $__storageS_AO_PosObject($i) > $nLastIndex Then $nLastIndex = $__storageS_AO_PosObject($i)
		Next

		if $nLastIndex == $__storageS_AO_Size Then Return

		ReDim $__storageS_AO_StorageArray[$nLastIndex + 1]

		For $i = $nLastIndex + 1 To $__storageS_AO_Size
			If $__storageS_AO_IndexObject.Exists($i) Then $__storageS_AO_IndexObject.Remove($i)
		Next

		$__storageS_AO_Size = $nLastIndex

	EndIf

EndFunc


Func _storageAO_GetClaimedVars()

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAO_GetInfo
; Description ...: Returns various informations of the AO method.
; Syntax ........: _storageAO_GetInfo($nMode)
; Parameters ....: $nMode               - (Int) the Mode
;                : 1					- Returns the amount of existing storages
;                : 2					- Returns the amount of free storages
;                : 3					- Returns the amount of claimed storages
;                : 4					- Returns the Size in Bytes of all claimed storages (CPU intensive)
; Return values .: The Result			= as Int
;                : False				= If an invalid option got used
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAO_GetInfo($nMode)

	Switch $nMode

		Case 1 ; amount of existing storage vars
			Return $__storageS_AO_Size

		Case 2 ; free storage vars
			Return $__storageS_AO_IndexObject.Count

		Case 3 ; claimed storage vars
			Return $__storageS_AO_PosObject.Count

		Case 4 ; size of claimes storage vars
			Local $nSize = 0
			For $i In $__storageS_GO_PosObject
				$nSize += _storageS_GetVarSize(Eval('__storageGO_' & $__storageS_AO_PosObject($i)))
			Next

			Return $nSize

	EndSwitch

EndFunc
#EndRegion


#Region _storageO		DictObj method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageO describtion

	~ todo

	Dev note:
	Requires a whole overhaul
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_CreateGroup
; Description ...: Initializes a Storage for the Object variant. Needs to be called for each Element Group
; Syntax ........: _storageO_CreateGroup($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......:
; Example .......: _storageO_CreateGroup(123)
; ===============================================================================================================================
Func _storageO_CreateGroup($vElementGroup)
	$vElementGroup = '_storageS_' & $vElementGroup

	Local $oElementGroup = ObjCreate("Scripting.Dictionary")
	If @error Then Return False
	$__storageS_O_Dictionaries($vElementGroup) = $oElementGroup

	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_Overwrite
; Description ...: Writes data to the Elementname of the Element group
; Syntax ........: _storageO_Overwrite($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Errors ........: 1						- The Element group Object doesnt exist.
;                : 2						- The Element group Object is not a Object (Storage is not known).
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageO_Overwrite($vElementGroup, $sElementName, $vElementData)
	$vElementGroup = '_storageS_' & $vElementGroup

	If Not $__storageS_O_Dictionaries.Exists($vElementGroup) Then Return SetError(1, 0, False)
;~ 	If Not $__storageS_O_Dictionaries.Exists($vElementGroup) Then _storageO_CreateGroup($vElementGroup) ; doesnt work ? Object keeps inaccessible

	Local $oElementGroup = $__storageS_O_Dictionaries($vElementGroup)
	if Not IsObj($oElementGroup) Then Return SetError(2, 0, False)

	$oElementGroup($sElementName) = $vElementData
	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_Append
; Description ...: Appends data
; Syntax ........: _storageO_Append($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......:
; Example .......: _storageO_Append(123, 'testdata', "hello world again")
; ===============================================================================================================================
Func _storageO_Append($vElementGroup, $sElementName, $vElementData)
	$vElementGroup = '_storageS_' & $vElementGroup

	Local $oElementGroup = $__storageS_O_Dictionaries($vElementGroup)
	if Not IsObj($oElementGroup) Then Return _storageO_Overwrite($vElementGroup, $sElementName, $vElementData)

	$oElementGroup($sElementName) &= $vElementData
	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_Calc
; Description ...: X operator Y. Where X is what is already stored and Y the $vElementData
; Syntax ........: _storageO_Calc($vElementGroup, $sElementName, $vElementData, $Operator)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $vElementData        - (Variable) Element Data aka Y
;                  $Operator            - (String) + - * / ^ etc.
; Return values .: The Result of the Operation
;                : Or "" if the operation failed
; Modified ......:
; Remarks .......: Beaware that the result of the operation is also stored.
; Example .......: _storageO_Overwrite(123, 'testinteger', 1)
;                : _storageO_Calc(123, 'testinteger', 2, '+')
; ===============================================================================================================================
Func _storageO_Calc($vElementGroup, $sElementName, $vElementData, $Operator)
	; ~ todo
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_Math
; Description ...: Like Cosinos the stored element. Also works with other Functions.
; Syntax ........: _storageO_Math($vElementGroup, $sElementName, $Math)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $Math                - (String) Cos Sin Mod Log Exp etc.
; Return values .: The Result of the Operation
;                : ""					= if the operation failed
;                : False				= If the Element is unknown
; Modified ......:
; Remarks .......: Functions like Ceiling() or Floor() also work. Beaware that the result of the operation is also stored.
; Example .......: _storageO_Overwrite(123, 'testinteger', 3)
;                : _storageO_Math(123, 'testinteger, "Cos")
; ===============================================================================================================================
Func _storageO_Math($vElementGroup, $sElementName, $Math)
	; ~ todo
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_Read
; Description ...: Returns the data for the element name of the element group
; Syntax ........: _storageO_Read($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
; Return values .: The data					= If success
; Errors ........: 1						- The Element group Object is not a Object (Storage is known).
;                : 2						- If the Element name isnt present.
; Modified ......:
; Remarks .......:
; Example .......: _storageO_Read(123, 'testdata')
; ===============================================================================================================================
Func _storageO_Read($vElementGroup, $sElementName)
	$vElementGroup = '_storageS_' & $vElementGroup

	Local $oElementGroup = $__storageS_O_Dictionaries($vElementGroup)
	if Not IsObj($oElementGroup) Then Return SetError(1, 0, False)

	If Not $oElementGroup.Exists($sElementName) Then Return SetError(2, 0, False)

	Return $oElementGroup($sElementName)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_DestroyGroup
; Description ...: Tidies and destroys all Variables of the given element group, including the element group.
; Syntax ........: _storageO_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: _storageO_DestroyGroup(123)
; ===============================================================================================================================
Func _storageO_DestroyGroup($vElementGroup)
	$vElementGroup = '_storageS_' & $vElementGroup

	Local $oElementGroup = $__storageS_O_Dictionaries($vElementGroup)

	For $i In $oElementGroup
		$oElementGroup.Remove($i)
	Next

	$__storageS_O_Dictionaries.Remove($vElementGroup)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageO_GetGroupVars
; Description ...: Returns a 2D array of size [n][3] containing the elements stored for the Element group
; Syntax ........: _storageO_GetGroupVars($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: 2D array					= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Array looks like this
;                : [n][0]					= Element name
;                : [n][1]					= Element Variable Type
;                : [n][2]					= Element Variable Data
; Example .......: _storageO_GetGroupVars(123)
; ===============================================================================================================================
Func _storageO_GetGroupVars($vElementGroup)
	$vElementGroup = '_storageS_' & $vElementGroup

	Local $oElementGroup = $__storageS_O_Dictionaries($vElementGroup)
	If Not IsObj($oElementGroup) Then Return False

	Local $arGroupVars2D[$oElementGroup.Count][3], $nCount = 0
	For $i In $oElementGroup
		$arGroupVars2D[$nCount][0] = $i
		$arGroupVars2D[$nCount][1] = VarGetType($oElementGroup($i))
		$arGroupVars2D[$nCount][2] = $oElementGroup($i)
		$nCount += 1
	Next

	Return $arGroupVars2D
EndFunc
#EndRegion
#EndRegion

; ==================================================================
#Region Experimental Methods

#Region _storageGM		WIP Reuse Assign/Eval based on Maps
#cs
	Incomplete. Do not use.

	Dev notes _
	Has issues with map limitations. The entire method should not provide more then 1e5 storages.
	Has issues with large data sets. Even so that it works nearly identical to GO, which would mean that GM should be faster,
	it isnt on large data sets. It makes no sense that this has anything todo with the map, but what then. Why should
	assign be faster in GO then in GM, that makes no sense too. What is it then?

	Maybe remove the GM data storage but keep its Dynamic Global management. That would reduce the appearance of map limitations.
#ce
Func _storageGM_CreateGroup($vElementGroup)

	If MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $mGroupVars[]
	__storageGM_Claim($vElementGroup & 'GM', $mGroupVars)

	Return True
EndFunc

Func _storageGM_Overwrite($vElementGroup, $sElementName, $vElementData)

	Local $sVarName = $vElementGroup & $sElementName
	Local $nPos = $__storageS_GM_PosMap[$sVarName]

	If Not $nPos Then

		if $vElementData == False Then Return SetError(1, 0, True)

		Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'GM'] & ', $sElementName)')

		__storageGM_Claim($sVarName, $vElementData)
		Return True

	Else

		Return Assign('__storageGM_' & $nPos, $vElementData, 2)

	EndIf

EndFunc

Func _storageGM_Read($vElementGroup, $sElementName)

	Local $sVarName = $vElementGroup & $sElementName
	Local $nPos = $__storageS_GM_PosMap[$sVarName]

	If Not $nPos Then Return SetError(1, 0, False)

	Return Eval('__storageGM_' & $nPos)

EndFunc

Func _storageGM_DestroyVar($vElementGroup, $sElementName)

	If Not MapExists(Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'GM']), $sElementName) Then Return False

	Local $sVarName = $vElementGroup & $sElementName
	Local $nPos = $__storageS_GM_PosMap[$sVarName]

	MapRemove($__storageS_GM_PosMap, $sVarName)
	$__storageS_GM_IndexMap[$nPos] = Null

	Return Assign('__storageGM_' & $nPos, Null)

EndFunc

Func _storageGM_TidyGroupVars($vElementGroup)

	Local $arGroupVars = MapKeys(Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'GM']))

	For $i = 0 To UBound($arGroupVars) - 1

		Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & $arGroupVars[$i]], Null)

	Next

EndFunc

Func _storageGM_DestroyGroup($vElementGroup)

EndFunc

Func _storageGM_GetClaimedVars()

	Local $arElementGroup = MapKeys($__storageS_GM_PosMap)
	If UBound($arElementGroup) == 0 Then Return False

	Local $arGroupVars2D[UBound($arElementGroup)][3], $nPos = 0
	For $i = 0 To UBound($arElementGroup) - 1
		$arGroupVars2D[$i][0] = $arElementGroup[$i]
		$arGroupVars2D[$i][2] = Eval('__storageGM_' & $__storageS_GM_PosMap[$arElementGroup[$i]])
		$arGroupVars2D[$i][1] = VarGetType($arGroupVars2D[$i][2])
	Next

	Return $arGroupVars2D

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGM_GetInfo
; Description ...: Returns various informations of the GM method.
; Syntax ........: _storageGM_GetInfo($nMode)
; Parameters ....: $nMode               - (Int) the Mode
;                : 1					- Returns the amount of existing storages
;                : 2					- Returns the amount of free storages
;                : 3					- Returns the amount of claimed storages
;                : 4					- Returns the Size in Bytes of all claimed storages (CPU intensive)
; Return values .: The Result			= as Int
;                : False				= If an invalid option got used
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
; note: i should take into consideration that repeated data isnt put into memory again
Func _storageGM_GetInfo($nMode)

	Switch $nMode

		Case 1 ; amount of existing storage vars
			Return $__storageS_GM_Size

		Case 2 ; free storage vars
;~ 			Return $__storageS_GO_IndexObject.Count
			Return UBound(MapKeys($__storageS_GM_IndexMap))

		Case 3 ; claimed storage vars
;~ 			Return $__storageS_GO_PosObject.Count
			Return UBound(MapKeys($__storageS_GM_PosMap))

		Case 4 ; size of claimes storage vars
			Local $nSize = 0
			Local $arElementGroup = MapKeys($__storageS_GM_PosMap)
			For $i = 0 To UBound($arElementGroup) - 1
				$nSize += _storageS_GetVarSize(Eval('__storageGM_' & $__storageS_GM_PosMap[$arElementGroup[$i]]))
			Next

	EndSwitch

EndFunc
#EndRegion


#Region _storageGi		WIP Assign / Eval Improved
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageGi Description

	Do not use. Unfinished.
#ce

Func _storageGi_CreateGroup($vElementGroup)
	If IsMap(Eval("StorageGi" & $vElementGroup)) Then Return False

	Local $mGroupVars[]
	Return Assign("StorageGi" & $vElementGroup, $mGroupVars, 2)
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Overwrite
; Description ...: Writes data to the Elementname of the Element group
; Syntax ........: _storageS_Overwrite($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......: If $vElementData is == False then the Variable is not declared because _storageS_Read() would
;                : return False then anyway. This is done to prevent the declaration of unnecessary global variables.
; Example .......: _storageG_Overwrite(123, 'testdata', "hello world")
; ===============================================================================================================================
Func _storageGi_Overwrite($vElementGroup, $sElementName, $vElementData)
	If Not MapExists(Eval("StorageGi" & $vElementGroup), String($sElementName)) Then
		If Not __storageGi_AddGroupVar($vElementGroup, String($sElementName)) Then Return SetError(1, 0, False)
	EndIf

	Return Assign("__storageGi_" & $vElementGroup & $sElementName, $vElementData, 2)
EndFunc   ;==>_storageS_Overwrite


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGi_ByRef
; Description ...: (Experimental) Allows for direct edits of a data storage
; Syntax ........: _storageGi_ByRef($vElementGroup, $sElementName, $sFuncName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $sFuncName         	    - (String) Function Name
;                  $vAdditionalData			- (Optional) Extra data given to the Func in $sFuncName
; Return values .: None
; Modified ......:
; Remarks .......: Func _Example(Byref $vStorageData, $vElementGroup, $vAdditionalData)
; Example .......: No
; ===============================================================================================================================
Func _storageGi_ByRef($vElementGroup, $sElementName, $sFuncName, $vAdditionalData = Null)
	Return Execute($sFuncName & '($__storageGi_' & $vElementGroup & $sElementName & ',$vElementGroup,$vAdditionalData)')
EndFunc

; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Append
; Description ...: Appends data to the Elementname of the Element group
; Syntax ........: _storageS_Append($vElementGroup, $sElementName, $vElementData)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
;                  $vElementData            - (Variable) Element Data
; Return values .: True						= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Append as in "Hello " & "World" = "Hello World"
; Example .......: _storageG_Append(123, 'testdata', "hello world again")
; ===============================================================================================================================
Func _storageGi_Append($vElementGroup, $sElementName, $vElementData)
    Local $sVarName = "__storageGi_" & $vElementGroup & $sElementName

    If Not IsDeclared($sVarName) Then Return _storageGi_Overwrite($vElementGroup, $sElementName, $vElementData)

    Return Assign($sVarName, Eval($sVarName) & $vElementData, 2)
EndFunc   ;==>_storageS_Append


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Calc
; Description ...: X operator Y. Where X is what is already stored and Y the $vElementData
; Syntax ........: _storageG_Calc($vElementGroup, $sElementName, $vElementData, $Operator)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $vElementData        - (Variable) Element Data aka Y
;                  $Operator            - (String) + - * / ^ etc.
;                  $bSwitch             - True / False. Switches X with Y if True.
;                  $bSave				- True / False. If True will store the result.
; Return values .: The Result of the Operation
;                : ""					= if the operation failed
;                : False				= If the Element is unknown
; Modified ......:
; Remarks .......:
; Example .......: _storageG_Overwrite(123, 'testinteger', 1)
;                : _storageG_Calc(123, 'testinteger', 2, '+')
; ===============================================================================================================================
Func _storageGi_Calc($vElementGroup, $sElementName, $vElementData, $Operator, $bSwitch = False, $bSave = True)
	Local $sVarName = "__storageGi_" & $vElementGroup & $sElementName

;~ 	If Not IsDeclared($sVarName) Then Return _storageG_Overwrite($vElementGroup, $sElementName, $vElementData)
	If Not IsDeclared($sVarName) Then Return False

	if $bSwitch Then
		Local $vCalc = Execute("$vElementData" & $Operator & Eval($sVarName))
	Else
		Local $vCalc = Execute(Eval($sVarName) & $Operator & "$vElementData")
	EndIf

	If $bSave Then Assign($sVarName, $vCalc, 2)
	Return $vCalc
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Execute
; Description ...: Like Cosinos the stored element. Also works with other Functions.
; Syntax ........: _storageG_Execute($vElementGroup, $sElementName, $Math)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - (String) Element Name
;                  $Operation           - (String) Cos Sin Mod Log Exp etc.
;                  $bSave				- True / False. If True will store the result.
; Return values .: The Result of the Operation
;                : ""					= if the operation failed
;                : False				= If the Element is unknown or when error
; Errors ........: 1					= $Operation String is blacklisted
; Modified ......:
; Remarks .......: CODE EXECUTION VULNERABLE (CE). Please ensure the input and storage data is no code.
;                :
;                : Functions like Ceiling() or Floor() also work just like your own Functions.
; Example .......: _storageG_Overwrite(123, 'testinteger', 3)
;                : _storageG_Execute(123, 'testinteger, "Cos")
;                : Or _storageG_Execute(123, 'testinteger, "_MyMathFunc")
; ===============================================================================================================================
Func _storageGi_Execute($vElementGroup, $sElementName, $Operation, $bSave = True)
	Local $sVarName = "__storageGi_" & $vElementGroup & $sElementName

	If Not IsDeclared($sVarName) Then Return False

	If _storageS_AntiCECheck($Operation) Then Return SetError(1, 0, False)

	Local $vCalc = Execute($Operation & "(" & Eval($sVarName) & ")")

	If $bSave Then Assign($sVarName, $vCalc)
	Return $vCalc
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_Read
; Description ...: Returns the data for the element name of the element group
; Syntax ........: _storageS_Read($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup           - Element Group
;                  $sElementName            - (String) Element Name
; Return values .: The data					= If success
; Errors ........: 1						- If the variable isnt present.
; Modified ......:
; Remarks .......: If _storageG_Overwrite() was called with data that was Bool False then the variable wasnt declared.
; Example .......: _storageG_Read(123, 'testdata')
; ===============================================================================================================================
Func _storageGi_Read($vElementGroup, $sElementName)
	Local $vData = Eval("__storageGi_" & $vElementGroup & $sElementName)
	Return (@error) ? False : $vData
EndFunc   ;==>_storageS_Read


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_TidyGroupVars
; Description ...: Tidies all Variables of the given element group
; Syntax ........: _storageS_TidyGroupVars($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: None
; Modified ......:
; Remarks .......: The global variables keep existent, but they are overwritten with Null.
;                : Because there is no way to delete Global variables.
; Example .......: _storageG_TidyGroupVars(123)
; ===============================================================================================================================
Func _storageGi_TidyGroupVars($vElementGroup)
    Local $mGroupVars = Eval("StorageGi" & $vElementGroup)
    If Not IsMap($mGroupVars) Then Return

	Local $sVarName = "__storageGi_" & $vElementGroup

	Local $arElementGroup = MapKeys($mGroupVars)

	For $i = 0 To UBound($arElementGroup) - 1
		Assign($sVarName & $arElementGroup[$i], False)
	Next
EndFunc   ;==>_storageS_TidyGroupVars


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_DestroyGroup
; Description ...: Tidies the Group variables and then Destroys the Group Object
; Syntax ........: _storageG_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: None
; Modified ......:
; Remarks .......: The Variables stay declared, but if they are to be never used again then you can also
;                : destroy the Object that they are stored in to free the ram.
;                : If you do however use them again then they will not be readded because only undeclared variables are added.
;                : Using IsDeclared() is simply much faster then using Eval().
; Example .......: No
; ===============================================================================================================================
Func _storageGi_DestroyGroup($vElementGroup)

	_storageGi_TidyGroupVars($vElementGroup)
	Assign("StorageGi" & $vElementGroup, Null, 2)

EndFunc

Func _storageGi_DestroyVar($vElementGroup, $sElementName)
	Local $mElementGroup = Eval("StorageGi" & $vElementGroup)
	If Not IsMap($mElementGroup) Then Return False
	If Not MapExists($mElementGroup, $sElementName) Then Return False

	MapRemove($mElementGroup, $sElementName)
	Assign("StorageGi" & $vElementGroup, $mElementGroup, 2)

	Return Assign("__storageGi_" & $vElementGroup & $sElementName, False, 2)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageG_GetGroupVars
; Description ...: Returns a 2D array of size [n][3] containing the elements stored for the Element group
; Syntax ........: _storageG_GetGroupVars($vElementGroup)
; Parameters ....: $vElementGroup           - Element Group
; Return values .: 2D array					= If success
;                : False					= If not
; Modified ......:
; Remarks .......: Array looks like this
;                : [n][0]					= Element name
;                : [n][1]					= Element Variable Type
;                : [n][2]					= Element Variable Data
; Example .......: _storageG_GetGroupVars(123)
; ===============================================================================================================================
Func _storageGi_GetGroupVars($vElementGroup)

	Local $mElementGroup = Eval("StorageGi" & $vElementGroup)
	If Not IsMap($mElementGroup) Then Return False

	$vElementGroup = '__storageGi_' & $vElementGroup

	Local $arElementGroup = MapKeys($mElementGroup)
	Local $arGroupVars2D[UBound($arElementGroup)][3]
	For $i = 0 To UBound($arElementGroup) - 1
		$arGroupVars2D[$i][0] = $arElementGroup[$i]
		$arGroupVars2D[$i][2] = Eval($vElementGroup & $arElementGroup[$i])
		$arGroupVars2D[$i][1] = VarGetType($arGroupVars2D[$i][2])
	Next

	Return $arGroupVars2D

EndFunc
#EndRegion


#Region _storageGx		WIP Assign / Eval Groupless
#cs
	_storageGx Description

	Do not use. Unfinished.
#ce
Func _storageGx_Overwrite($vElementGroup, $sElementName, $sElementData = True)
	Return Assign(StringToBinary($vElementGroup & $sElementName), $sElementData, 2)
EndFunc

Func _storageGx_Read($vElementGroup, $sElementName)
	Return Eval(StringToBinary($vElementGroup & $sElementName))
EndFunc

Func _storageGx_Exists($vElementGroup, $sElementName)
	Eval(StringToBinary($vElementGroup & $sElementName))
	Return (@error == 0) ? True : False
EndFunc

#EndRegion
#EndRegion
#EndRegion


; ===============================================================================================================================
#Region Listing Storages
#cs
	Standard Listing storages are storages that are fast with any kind of data. Those lists
	are good allrounders. They are not the best in a single field but work at decent speeds for
	any usecase.

	Specialized Listing storages are storages that are either good in just one or in multiple fields,
	and that suffer in the rest. You could choose a specialized method to optimise your entire or a part
	of your script.
#ce

; ==================================================================
#Region Standard Methods

#Region _storageOL		DictObj List method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageOL describtion

	Fast Add, Remove and Exists Element method
	Very good allrounder and usually the goto for all sorts of element lists.

	(Will be removed and Superseded by the Experimental OLi and OLx methods)
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageOL_CreateGroup
; Description ...: Creates a dictobj list under the given groupname
; Syntax ........: _storageOL_CreateGroup($vElementGroup)
; Parameters ....: $vElementGroup       - Element Group
; Return values .: True					= If success
;                : False				= If the group already exists
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageOL_CreateGroup($vElementGroup)

	; numbers dont work and converting the numer to String() often doesnt too.
	; so we add a char in front to make sure that the dict wont have any issues with the name
	$vElementGroup = 'g' & $vElementGroup

	; if the group already exists then return False
	if $__storageS_OL_Dictionaries.Exists($vElementGroup) Then Return False

	Local $oElementGroup = ObjCreate("Scripting.Dictionary")
	$__storageS_OL_Dictionaries($vElementGroup) = $oElementGroup

	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageOL_AddElement
; Description ...: Adds a element to the dictobj
; Syntax ........: _storageOL_AddElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - Element Name
; Return values .: True					= If success
;                : False				= If not
; Errors ........: 1					- The elementgroup is unknown
;                : 2					- The elementname is already added to the list
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageOL_AddElement($vElementGroup, $sElementName)
	$vElementGroup = 'g' & $vElementGroup

	; if the elementgroup is unknown then return false
	If Not $__storageS_OL_Dictionaries.Exists($vElementGroup) Then Return SetError(1, 0, False)
	Local $oElementGroup = $__storageS_OL_Dictionaries($vElementGroup)

	$sElementName = 'g' & $sElementName

	; if the element is already present then return false
	if $oElementGroup.Exists($sElementName) Then Return SetError(2, 0, False)

	; add the element
	$oElementGroup($sElementName)
	$__storageS_OL_Dictionaries($vElementGroup) = $oElementGroup

	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageOL_GetElements
; Description ...: Returns all existing elements in the given groupname in a 1D Array
; Syntax ........: _storageOL_GetElements($vElementGroup)
; Parameters ....: $vElementGroup       - Element Group
;                : $bDict				- If True returns the raw dictionary (read remarks)
; Return values .: False				= If the elementgroup is unknown
;                : 1D Array				= Containing all elements, starting at [0]
; Modified ......:
; Remarks .......: If the raw dictionary is returned then beaware that each item has an extra character saved to it.
;                : if you added element "test" then it will be "gtest". This first char is added to make the dictionary
;                : compatible with numbers.
; Example .......: No
; ===============================================================================================================================
Func _storageOL_GetElements($vElementGroup, $bDict = False)
	$vElementGroup = 'g' & $vElementGroup

	; if the elementgroup is unknown then return false
	If Not $__storageS_OL_Dictionaries.Exists($vElementGroup) Then Return False
	Local $oElementGroup = $__storageS_OL_Dictionaries($vElementGroup)

	If $bDict Then Return $oElementGroup

	Local $arGroupVars[$oElementGroup.Count], $nCount = 0
	For $i In $oElementGroup
		$arGroupVars[$nCount] = StringTrimLeft($i, 1)
		$nCount += 1
	Next

	Return $arGroupVars
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageOL_Exists
; Description ...: Checks if the given element exists in the given element group
; Syntax ........: _storageOL_Exists($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - Element Name
; Return values .: True					= Element exists
;                : False				= Element does not exists
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageOL_Exists($vElementGroup, $sElementName)
	$vElementGroup = 'g' & $vElementGroup

	; if the elementgroup is unknown then return false
	If Not $__storageS_OL_Dictionaries.Exists($vElementGroup) Then Return SetError(1, 0, False)
	Local $oElementGroup = $__storageS_OL_Dictionaries($vElementGroup)

	$sElementName = 'g' & $sElementName

	Return $oElementGroup.Exists($sElementName)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageOL_RemoveElement
; Description ...: Removes the given element from the given element group
; Syntax ........: _storageOL_RemoveElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - Element Group
;                  $sElementName        - Element Name
; Return values .: True					= If success
;                : False				= If not
; Errors ........: 1					- elementgroup is unknown
;                : 2					- element not part of the group
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageOL_RemoveElement($vElementGroup, $sElementName)
	$vElementGroup = 'g' & $vElementGroup

	; if the elementgroup is unknown then return false
	If Not $__storageS_OL_Dictionaries.Exists($vElementGroup) Then Return SetError(1, 0, False)
	Local $oElementGroup = $__storageS_OL_Dictionaries($vElementGroup)

	$sElementName = 'g' & $sElementName

	If Not $oElementGroup.Exists($sElementName) Then Return SetError(2, 0, False)

	$oElementGroup.Remove($sElementName)
	$__storageS_OL_Dictionaries($vElementGroup) = $oElementGroup

	Return True
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageOL_DestroyGroup
; Description ...: Destroys the whole group and its contents
; Syntax ........: _storageOL_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - Element Group
; Return values .: True					= If success
;                : False				= If the elementgroup is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageOL_DestroyGroup($vElementGroup)
	$vElementGroup = 'g' & $vElementGroup

	If Not $__storageS_OL_Dictionaries.Exists($vElementGroup) Then Return False

	$__storageS_OL_Dictionaries.Remove($vElementGroup)
	Return True
EndFunc
#EndRegion
#EndRegion

; ==================================================================
#Region Specialized Methods

#Region _storageML 		Map List Method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageML describtion

	Fastest Element Exists method (not counting GLx). Slow when adding, removing or getting all elements of a group.
	Gets exceptionally slow on large lists. Adding 10.000 Elements takes 90 seconds.

	If your lists are never of that size and you need to check very often if a element in that, somewhat static, list exists
	then this is your goto.

	(Will be removed and Superseded by the Experimental MLi and MLx methods)
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageML_CreateGroup
; Description ...: Creates a group with the given group name
; Syntax ........: _storageML_CreateGroup($vElementGroup)
; Parameters ....: $vElementGroup       - Group name
; Return values .: True					= If success
;                : False				= If the group already exists
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageML_CreateGroup($vElementGroup)

	If MapExists($__storageS_ML_Maps, $vElementGroup) Then Return False

	Local $mElementGroup[]
	$__storageS_ML_Maps[$vElementGroup] = $mElementGroup

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageML_AddElement
; Description ...: Adds a Element to the given Group
; Syntax ........: _storageML_AddElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - Group name
;                  $sElementName        - Element name
; Return values .: True					= If success
;                : False				= If the Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageML_AddElement($vElementGroup, $sElementName)

	If Not MapExists($__storageS_ML_Maps, $vElementGroup) Then Return False
	Local $mElementGroup = $__storageS_ML_Maps[$vElementGroup]

	; do not use MapAppend() it produces bugs.
	$mElementGroup[$sElementName] = Null
	$__storageS_ML_Maps[$vElementGroup] = $mElementGroup

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageML_GetElements
; Description ...: Returns all Elements of the given Group in a 1D Array
; Syntax ........: _storageML_GetElements($vElementGroup)
; Parameters ....: $vElementGroup       - Group name
; Return values .: Array				= Containing all Elements of the Group, starting at [0]
;                : False				= The Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageML_GetElements($vElementGroup, $bMap = False)

	If Not MapExists($__storageS_ML_Maps, $vElementGroup) Then Return False
	Local $mElementGroup = $__storageS_ML_Maps[$vElementGroup]

	If $bMap Then Return $mElementGroup
	Return MapKeys($mElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageML_Exists
; Description ...: Checks if the Element exists in the given group
; Syntax ........: _storageML_Exists($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - Group name
;                  $sElementName        - Element name
; Return values .: True					= Element exists
;                : False				= Element does not exists
; Errors ........: 1					- Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageML_Exists($vElementGroup, $sElementName)

	If Not MapExists($__storageS_ML_Maps, $vElementGroup) Then Return SetError(1, 0, False)
	Local $mElementGroup = $__storageS_ML_Maps[$vElementGroup]

	Return MapExists($mElementGroup, $sElementName)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageML_RemoveElement
; Description ...: Removes a element from the given group
; Syntax ........: _storageML_RemoveElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - Group name
;                  $sElementName        - Element name
; Return values .: True					= If success
;                : False				= Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageML_RemoveElement($vElementGroup, $sElementName)

	If Not MapExists($__storageS_ML_Maps, $vElementGroup) Then Return False
	Local $mElementGroup = $__storageS_ML_Maps[$vElementGroup]

	MapRemove($mElementGroup, $sElementName)
	$__storageS_ML_Maps[$vElementGroup] = $mElementGroup

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageML_DestroyGroup
; Description ...: Destroys the entire group
; Syntax ........: _storageML_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - Group name
; Return values .: True					= If success
;                : False				= If the group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageML_DestroyGroup($vElementGroup)

	If Not MapExists($__storageS_ML_Maps, $vElementGroup) Then Return False
	Return MapRemove($__storageS_ML_Maps, $vElementGroup)

EndFunc
#EndRegion


#Region _storageAL		Array List method
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageAL describtion

	Fast GetElements method. Slow when adding or removing a element or when checking if a element in the list exists.
	This is an Array list, stored in GO. Good for when you often need to iterate through lists.

	When used in combination with ALRapid then this method is the fastest to add new elements to a list.
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAL_CreateGroup
; Description ...: Creates a Element Group
; Syntax ........: _storageAL_CreateGroup($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: True					= If success
;                : False				= If the group already exists
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAL_CreateGroup($vElementGroup)

	If IsArray(_storageGO_Read('_storageAL', $vElementGroup)) Then Return False

	Local $arElementGroup[0]
	Return _storageGO_Overwrite('_storageAL', $vElementGroup, $arElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAL_AddElement
; Description ...: Adds a Element to the given Group
; Syntax ........: _storageAL_AddElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: True					= If success
;                : False				= If the Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAL_AddElement($vElementGroup, $sElementName)

	Local $arElementGroup = _storageGO_Read('_storageAL', $vElementGroup)
	If Not IsArray($arElementGroup) Then Return False

	Local $nArSize = UBound($arElementGroup)

	ReDim $arElementGroup[$nArSize + 1]
	$arElementGroup[$nArSize] = $sElementName

	Return _storageGO_Overwrite('_storageAL', $vElementGroup, $arElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAL_GetElements
; Description ...: Returns all Elements of the given group in a 1D Array
; Syntax ........: _storageAL_GetElements($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: Array				= Containing all Elements of the group, starting at [0]
;                : False				= If the Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAL_GetElements($vElementGroup)

	Return _storageGO_Read('_storageAL', $vElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAL_Exists
; Description ...: Checks if the given Element exists for the given group
; Syntax ........: _storageAL_Exists($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: True					= Element exists
;                : False				= Element does not exists
; Errors ........: 1					= Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAL_Exists($vElementGroup, $sElementName)

	Local $arElementGroup = _storageGO_Read('_storageAL', $vElementGroup)
	If Not IsArray($arElementGroup) Then Return SetError(1, 0, False)

	For $i = 0 To UBound($arElementGroup) - 1
		if $arElementGroup[$i] == $sElementName Then Return True
	Next

	Return False

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAL_RemoveElement
; Description ...: Removes the given Element from the given Group
; Syntax ........: _storageAL_RemoveElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: True					= If success
;                : False				= If not
; Errors ........: 1					= Group is unknown
;                : 2					= Element is unknown
; Modified ......:
; Remarks .......:
; ===============================================================================================================================
Func _storageAL_RemoveElement($vElementGroup, $sElementName)

	Local $arElementGroup = _storageGO_Read('_storageAL', $vElementGroup)
	If Not IsArray($arElementGroup) Then Return SetError(1, 0, False)

	Local $nArSize = UBound($arElementGroup) - 1, $nIndex = -1
	For $i = 0 To $nArSize
		If $arElementGroup[$i] == $sElementName Then
			$nIndex = $i
			ExitLoop
		EndIf
	Next

	If $nIndex == -1 Then Return SetError(2, 9, False)

	$arElementGroup[$nIndex] = $arElementGroup[$nArSize]
	ReDim $arElementGroup[$nArSize]

	Return _storageGO_Overwrite('_storageAL', $vElementGroup, $arElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageAL_DestroyGroup
; Description ...: Destroys the entire Group and its elements.
; Syntax ........: _storageAL_DestroyGroup($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: True					= If success
;                : False				= Group is unknown
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageAL_DestroyGroup($vElementGroup)

	Local $arElementGroup = _storageGO_Read('_storageAL', $vElementGroup)
	If Not IsArray($arElementGroup) Then Return False

	Return _storageGO_DestroyVar('_storageAL', $vElementGroup)

EndFunc
#EndRegion


#Region _storageALR		Array List Rapid Add
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageALR (ALRapid) describtion

	This is an extention for _storageAL, which is made to fasten the element additions.
	Fastest Add Elements method.

	The ALRapid array needs to be destroyed after it got converted to an AL array.
	This isnt happening byitself, duo to you maybe wanting to create multiple AL storages with the same elements.
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageALR_AddElement
; Description ...: Adds a Element
; Syntax ........: _storageALR_AddElement($sElementName)
; Parameters ....: $sElementName        - a string value.
; Return values .: None
; Modified ......:
; Remarks .......: Works with a Single Global Array. So its not possible to write elements to a group. Thats what ALRapidX is for.
; Example .......: No
; ===============================================================================================================================
Func _storageALR_AddElement($sElementName)

	Local $nArSize = UBound($__storageS_ALR_Array)
	If $__storageS_ALR_Index = $nArSize Then ReDim $__storageS_ALR_Array[$nArSize + 1e6]

	$__storageS_ALR_Array[$__storageS_ALR_Index] = $sElementName
	$__storageS_ALR_Index += 1

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageALR_ConvertToAL
; Description ...: Converts the ALR Array to a AL array
; Syntax ........: _storageALR_ConvertToAL($vElementGroup)
; Parameters ....: $vElementGroup       - a variant value.
; Return values .: True					= If success
;                : False				= The group already exists
; Modified ......:
; Remarks .......: Once you finished adding all the elements, you call this function to create the AL Group.
; Example .......: No
; ===============================================================================================================================
Func _storageALR_ConvertToAL($vElementGroup)

	If IsArray(_storageGO_Read('_storageAL', $vElementGroup)) Then Return False

	Local $arElementGroup = $__storageS_ALR_Array
	ReDim $arElementGroup[$__storageS_ALR_Index]

	Return _storageGO_Overwrite('_storageAL', $vElementGroup, $arElementGroup)

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageALR_Destroy
; Description ...: Resets the global array
; Syntax ........: _storageALR_Destroy()
; Parameters ....: None
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageALR_Destroy()

	Local $arElementGroup[1e6]
	$__storageS_ALR_Array = $arElementGroup
	$__storageS_ALR_Index = 0

EndFunc
#EndRegion


#Region _storageGLx		Assign/Eval List X
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageGLx describtion

	A very specialised method for a very specific use. For huge or static lists where its only necessary to check if a element exists.
	You cannot get all the elements of a group !

	Works on top of Globals. Therefore each removed element leaks to memory.

	Because there is no storage that memorizes all elements in the defined group (no index) there is no time reduction interacting
	with the list. Each element simply gets put into its own global and thats it. Thats the reason why only the hardware memory is
	the limit. This makes it also impossible to get all elements that are stored in a GLx storage.

	Think of a huge blacklist of ips or of a list of signatures, if you never need to query that list / if its static / and if you
	only check if a element in it exists then GLx might fit best.

	This UDF byitself makes use of this method in the AntiCE functions.
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGLx_AddElement
; Description ...: Adds an Element to the List
; Syntax ........: _storageGLx_AddElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: True
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGLx_AddElement($vElementGroup, $sElementName)
	Return Assign(StringToBinary($vElementGroup & $sElementName), True, 2)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGLx_Exists
; Description ...: Checks if an element exists in the list
; Syntax ........: _storageGLx_Exists($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: True					= If Exists
;                : False				= If not
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGLx_Exists($vElementGroup, $sElementName)
	Return (Eval(StringToBinary($vElementGroup & $sElementName))) ? True : False
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageGLx_RemoveElement
; Description ...: Removes an element from the list
; Syntax ........: _storageGLx_RemoveElement($vElementGroup, $sElementName)
; Parameters ....: $vElementGroup       - a variant value.
;                  $sElementName        - a string value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageGLx_RemoveElement($vElementGroup, $sElementName)
	Return Assign(StringToBinary($vElementGroup & $sElementName), False, 6)
EndFunc
#EndRegion
#EndRegion

; ==================================================================
#Region Experimental Methods

#Region _storageOLi		WIP Experimental Dictionary List Improved
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageOLi describtion

	Experimental listing method. Which took 7 iterations to make.

	Its a _storageOL derivation sharing storages with _storageGM.
	Element Lists created within _storageOLi_GetElements() are saved until a next edit of the list is performed.

	If there arent 10.000 groups required but each group needs to contain 1e6 or more items, while being highly dynamic then this
	is what you are looking for.

	Uses Execute() to perform direct GM storage edits which also lead to a single scrap storage if a element is added to a
	non existing group. The Scrap storage has no effect on you.

	Overall this listing method tries to combine the pros of the two methods and additionally uses experimental technics, to
	create a OL derivate that is better in all its fields.

	_storageGM suffers from too large maps. If the entire storage group count reaches too high numbers then all method based on GM will
	get slower. _storageGM_GetInfo() can help investigate such issues. 10.000 storages should be the top most limit for GM.
	Each OLi group takes 2 GM storages.

	Dev notes _
	Similiar to GM this method will suffer from map limitations (1e5).
	Reduce the GM storage use to 1, by storing the get elements array in another method like AO instead.
#ce
Func _storageOLi_CreateGroup($vElementGroup)

	If MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	__storageGM_Claim($vElementGroup, ObjCreate("Scripting.Dictionary"))
	__storageGM_Claim($vElementGroup & 'A', False)

EndFunc

Func _storageOLi_AddElement($vElementGroup, $sElementName)

	; Execute() can only process expressions. But this here works well and also saves time because
	; we edit the global var directly instead of copying it to a local first.
	Execute('$__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & '("g" & $sElementName)')
	Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)

	; sometimes faster, sometimes not. The results vary alot while the above stays steady
;~ 	Return Execute('($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & '("g" & $sElementName)) ? $__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'] & 'A = False : False')

EndFunc

; the last element need to have the $bLast set to True otherwise _storageOLi_GetElements() might return a wrong array.
Func _storageOLiRapid_AddElement($vElementGroup, $sElementName, $bLast = False)
	Execute('$__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & '("g" & $sElementName)')
	If $bLast Then Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)
EndFunc

Func _storageOLi_Exists($vElementGroup, $sElementName)
	Return (Execute('$__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & '.Exists("g" & $sElementName)')) ? True : False
EndFunc

Func _storageOLi_GetElements($vElementGroup)

	If Not MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $arElementGroup = Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'])
	If IsArray($arElementGroup) Then Return $arElementGroup

	Local $oElementGroup = Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup])
	If Not IsObj($oElementGroup) Then Return False

	Local $arElementGroup[$oElementGroup.Count], $nCount = 0
	For $i In $oElementGroup
		$arElementGroup[$nCount] = StringTrimLeft($i, 1)
		$nCount += 1
	Next

	Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], $arElementGroup)
	Return $arElementGroup

EndFunc

Func _storageOLi_RemoveElement($vElementGroup, $sElementName)
	Execute('$__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & '.Remove("g" & $sElementName)')
	Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)
EndFunc

Func _storageOLi_DestroyGroup($vElementGroup)

	If Not MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $nPos = $__storageS_GM_PosMap[$vElementGroup]
	If $nPos == "" Then ; scrap storage

		Assign('__storageGM_' & $nPos, Null)
		Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], Null)

	Else

		; tidy
		Assign('__storageGM_' & $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup)

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		$nPos = $__storageS_GM_PosMap[$vElementGroup & 'A']

		; tidy
		Assign('__storageGM_', $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup & 'A')

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		Return True

	EndIf

EndFunc
#EndRegion


#Region _storageOLx		WIP Experimental Dictionary List Extended
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageOLx describtion

	Experimental listing method.

	Very similiar to OLi, but with the difference that its a combination of _storageGO and OL.
	Therefore this method is slower then GLi, but it supports much larger storage amounts (groups).

	So you can have lots of groups where each can have lots of items. OLi and OLx are generally there
	to manage larger lists then MLi or MLx can do.

	Each OLx storage takes 2 GO storages.
#ce
Func _storageOLx_CreateGroup($vElementGroup)

	$vElementGroup = 'g' & $vElementGroup
	If $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False

	__storageGO_Claim($vElementGroup, ObjCreate("Scripting.Dictionary"))
	__storageGO_Claim($vElementGroup & 'A', False)

EndFunc

Func _storageOLx_AddElement($vElementGroup, $sElementName)

	$vElementGroup = 'g' & $vElementGroup

	; Execute() can only process expressions. But this here works well and also saves time because
	; we edit the global var directly instead of copying it to a local first.
	Execute('$__storageGO_' & $__storageS_GO_PosObject($vElementGroup) & '("g" & $sElementName)')
	Return Assign('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & 'A'), False)

EndFunc


Func _storageOLxRapid_AddElement($vElementGroup, $sElementName, $bLast = False)

	$vElementGroup = 'g' & $vElementGroup

	; Execute() can only process expressions. But this here works well and also saves time because
	; we edit the global var directly instead of copying it to a local first.
	Execute('$__storageGO_' & $__storageS_GO_PosObject($vElementGroup) & '("g" & $sElementName)')
	If $bLast Then Return Assign('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & 'A'), False)

EndFunc

Func _storageOLx_Exists($vElementGroup, $sElementName)

	Return (Execute('$__storageGO_' & $__storageS_GO_PosObject('g' & $vElementGroup) & '.Exists("g" & $sElementName)')) ? True : False

EndFunc

Func _storageOLx_GetElements($vElementGroup)

	$vElementGroup = 'g' & $vElementGroup
	if Not $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False

	Local $arElementGroup = Eval('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & 'A'))
	If IsArray($arElementGroup) Then Return $arElementGroup

	Local $oElementGroup = Eval('__storageGO_' & $__storageS_GO_PosObject($vElementGroup))
	If Not IsObj($oElementGroup) Then Return False

	Local $arElementGroup[$oElementGroup.Count], $nCount = 0
	For $i In $oElementGroup
		$arElementGroup[$nCount] = StringTrimLeft($i, 1)
		$nCount += 1
	Next

	Assign('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & 'A'), $arElementGroup)
	Return $arElementGroup
EndFunc

Func _storageOLx_RemoveElement($vElementGroup, $sElementName)

	$vElementGroup = 'g' & $vElementGroup
	Execute('$__storageGO_' & $__storageS_GO_PosObject($vElementGroup) & '.Remove("g" & $sElementName)')
	Return Assign('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & 'A'), False)

EndFunc

Func _storageOLx_DestroyGroup($vElementGroup)

	$vElementGroup = 'g' & $vElementGroup
	if Not $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False

	Local $nPos = $__storageS_GO_PosObject($vElementGroup)
	If $nPos == "" Then ; scrap storage

		Assign('__storageGO_' & $nPos, Null)
		Return Assign('__storageGO_' & $__storageS_GO_PosObject($vElementGroup & 'A'), Null)

	Else

		; tidy
		Assign('__storageGO_' & $nPos, Null)

		; free
		$__storageS_GO_PosObject.Remove($vElementGroup)

		; add to index
		$__storageS_GO_IndexObject($nPos)

		$nPos = $__storageS_GO_PosObject($vElementGroup & 'A')

		; tidy
		Assign('__storageGO_' & $nPos, Null)

		; free
		$__storageS_GO_PosObject.Remove($vElementGroup & 'A')

		; add to index
		$__storageS_GO_IndexObject($nPos)


		Return True

	EndIf

EndFunc
#EndRegion


#Region _storageMLi		WIP Experimental Map List Improved
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageMLi describtion

	Its a _storageML derivation sharing storages with _storageGM.
	Element Lists created within _storageMLi_GetElements() are saved until a next edit of the list is performed.

	If you are looking for a listing storage that is exceptionally dynamic, here you go.
	Does not support lists larger then 10.000 Items. That is a map limitation.

	Uses Execute() to perform direct GM storage edits which improve the map interactions by alot.

	Overall this listing method tries to combine the pros of the two methods and additionally uses experimental technics, to
	create a ML derivate that is better in all its fields.

	Dev notes _
	Similiar to GM this method will suffer from map limitations (1e5)
#ce
Func _storageMLi_CreateGroup($vElementGroup)
	If MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $mElementGroup[]
	__storageGM_Claim($vElementGroup, $mElementGroup)
	__storageGM_Claim($vElementGroup & 'A', False)

	Return True
EndFunc

Func _storageMLi_AddElement($vElementGroup, $sElementName)

	; execute trick. Lets us edit the map storage directly instead of copying it into a local first.
	Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')
	Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)

EndFunc

; the last element need to have the $bLast set to True otherwise _storageMLi_GetElements() might return a wrong array.
Func _storageMLiRapid_AddElement($vElementGroup, $sElementName, $bLast = False)
	Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')
	If $bLast Then Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)
EndFunc

Func _storageMLi_Exists($vElementGroup, $sElementName)
	Return (MapExists(Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup]), $sElementName)) ? True : False
EndFunc

Func _storageMLi_GetElements($vElementGroup, $bMap = False)
	Local $nPos = $__storageS_GM_PosMap[$vElementGroup]
	If Not $nPos Then Return False

	Local $arElementGroup = Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'])
	If IsArray($arElementGroup) Then Return $arElementGroup

	If $bMap Then Return Eval('__storageGM_' & $nPos)
	$arElementGroup = MapKeys(Eval('__storageGM_' & $nPos))

	Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], $arElementGroup)
	Return $arElementGroup
EndFunc

Func _storageMLi_RemoveElement($vElementGroup, $sElementName)
	Execute('MapRemove($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')
	Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)
EndFunc

Func _storageMLi_DestroyGroup($vElementGroup)

	If Not MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $nPos = $__storageS_GM_PosMap[$vElementGroup]
	If $nPos == "" Then ; scrap storage

		Assign('__storageGM_' & $nPos, Null)
		Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], Null)

	Else

		; tidy
		Assign('__storageGM_' & $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup)

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		$nPos = $__storageS_GM_PosMap[$vElementGroup & 'A']

		; tidy
		Assign('__storageGM_', $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup & 'A')

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		Return True

	EndIf

EndFunc
#EndRegion


#Region _storageMLx		WIP Experimental Map List Extended
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageMLx describtion

	Its a _storageMLi derivation sharing storages with _storageGM.
	Element Lists created within _storageMLx_GetElements() are saved until a next edit of the list is performed.

	Uses Execute() to perform direct GM storage edits which improve the map interactions by alot.

	Overall this listing method tries to combine the pros of the two methods and additionally uses experimental technics, to
	create a ML derivate that is better in all its fields.

	Additionally this method allows for extra data storage. So each element in a list can have extra data stored to it.

	Dev notes _
	Similiar to GM this method will suffer from map limitations (1e5)
	Maybe remove this method, as the Settings storages are suited better for the extra data storage.
#ce

Func _storageMLx_CreateGroup($vElementGroup)
	If MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $mElementGroup[]
	__storageGM_Claim($vElementGroup, $mElementGroup)
	__storageGM_Claim($vElementGroup & 'A', False)

	Return True
EndFunc

Func _storageMLx_AddElement($vElementGroup, $sElementName, $sData = Null)

	; execute trick. Lets us edit the map storage directly instead of copying it into a local first.
;~ 	Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName, $sData)')

	if $sData Then
		Execute('__storageS_AssignMapData($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName, $sData)')
	Else
		Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')
	EndIf

	Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)

EndFunc

; the last element need to have the $bLast set to True otherwise _storageMLx_GetElements() might return a wrong array.
Func _storageMLxRapid_AddElement($vElementGroup, $sElementName, $sData = Null, $bLast = False)

	; backup
;~ 	Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName, $sData)')

	if $sData Then
		Execute('__storageS_AssignMapData($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName, $sData)')
	Else
		Execute('__storageS_AssignMap($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')
	EndIf

	If $bLast Then Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)
EndFunc

Func _storageMLx_Exists($vElementGroup, $sElementName)
	; mapexists should return True/False, thats stated in the helpfile. but it returns 1/0.
	; so it has to be done this way, otherwise a method change could cause issues.
	Return (MapExists(Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup]), $sElementName)) ? True : False

	; direct variable access would usually be faster, but the string here needs to be interpreted first, which takes more time then the Eval().
;~ 	Return (Execute('MapExists($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')) ? True : False

	; this would be faster but it would not work when the data is Null, False, 0 or ""
;~ 	Return (Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup])[$sElementName]) ? True : False
EndFunc

Func _storageMLx_GetElements($vElementGroup, $bMap = False, $b2D = False)
	Local $nPos = $__storageS_GM_PosMap[$vElementGroup]
	If Not $nPos Then Return False

	Local $arElementGroup = Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'])
	If IsArray($arElementGroup) Then
		if $b2D Then
			If UBound($arElementGroup, 2) == 2 Then Return $arElementGroup
		Else ; if not $b2D
			; a 1D would return 0. Checking this way is faster then with == 0
			If Not UBound($arElementGroup, 2) Then Return $arElementGroup
		EndIf
	EndIf

	If $bMap Then Return Eval('__storageGM_' & $nPos)

	Local $mElementGroup = Eval('__storageGM_' & $nPos)
	$arElementGroup = MapKeys($mElementGroup)

	If $b2D Then
		Local $nArSize = UBound($arElementGroup)
		Local $arElementGroup2D[$nArSize][2]
		For $i = 0 To $nArSize - 1
			$arElementGroup2D[$i][0] = $arElementGroup[$i]
			$arElementGroup2D[$i][1] = $mElementGroup[$arElementGroup[$i]]
		Next

		$arElementGroup = $arElementGroup2D
	EndIf

	Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], $arElementGroup)
	Return $arElementGroup
EndFunc

Func _storageMLx_GetElementData($vElementGroup, $sElementName)
	Return Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup])[$sElementName]
EndFunc

Func _storageMLx_RemoveElement($vElementGroup, $sElementName)
	Execute('MapRemove($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName)')
	Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], False)
EndFunc

Func _storageMLx_DestroyGroup($vElementGroup)

	If Not MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $nPos = $__storageS_GM_PosMap[$vElementGroup]
	If $nPos == "" Then ; scrap storage

		Assign('__storageGM_' & $nPos, Null)
		Return Assign('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup & 'A'], Null)

	Else

		; tidy
		Assign('__storageGM_' & $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup)

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		$nPos = $__storageS_GM_PosMap[$vElementGroup & 'A']

		; tidy
		Assign('__storageGM_', $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup & 'A')

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		Return True

	EndIf

EndFunc
#EndRegion
#EndRegion
#EndRegion


; ===============================================================================================================================
#Region Ring Buffer Storages
#cs
	https://en.wikipedia.org/wiki/Circular_buffer
#ce

; ==================================================================
#Region Standard Methods

#Region _storageRBr		Multi Return Ring Buffer (lossy)
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageRBr describtion

	https://en.wikipedia.org/wiki/Circular_buffer

	Does not store the buffer, but instead returns it.

	(Will be Superseded by the Experimental RBs method)
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBr_CreateGroup
; Description ...: Creates a Ring buffer and returns it
; Syntax ........: _storageRBr_CreateGroup($nRingElementCount)
; Parameters ....: $nRingElementCount   - Element count
; Return values .: Array
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBr_CreateGroup($nRingElementCount)

	Local $arRingBuffer[$nRingElementCount + 2]
	$arRingBuffer[0] = 2 ; WritePos
	$arRingBuffer[1] = 2 ; ReadPos

	Return $arRingBuffer

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBr_Add
; Description ...: Adds an Element to the given Ring Buffer
; Syntax ........: _storageRBr_Add(Byref $arRingBuffer, $vElementData)
; Parameters ....: $arRingBuffer        - [in/out] The Ring Buffer
;                  $vElementData        - Data of any kind
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBr_Add(ByRef $arRingBuffer, $vElementData)

	If UBound($arRingBuffer) == $arRingBuffer[0] Then $arRingBuffer[0] = 2

	$arRingBuffer[$arRingBuffer[0]] = $vElementData
	$arRingBuffer[0] += 1

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBr_Get
; Description ...: Returns the oldest data of the given Ring Buffer
; Syntax ........: _storageRBr_Get(Byref $arRingBuffer)
; Parameters ....: $arRingBuffer        - [in/out] The Ring Buffer
; Return values .: The oldest data
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBr_Get(ByRef $arRingBuffer)

	If UBound($arRingBuffer) == $arRingBuffer[1] Then $arRingBuffer[1] = 2

	Local $vElementData = $arRingBuffer[$arRingBuffer[1]]
	if $vElementData == "" Then Return SetError(1, 0, False)

	$arRingBuffer[$arRingBuffer[1]] = ""
	$arRingBuffer[1] += 1

	Return $vElementData

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBr_DestroyGroup
; Description ...: Destroys the given Ring Buffer
; Syntax ........: _storageRBr_DestroyGroup(Byref $arRingBuffer)
; Parameters ....: $arRingBuffer        - [in/out] The Ring Buffer
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBr_DestroyGroup(ByRef $arRingBuffer)
	$arRingBuffer = Null
EndFunc
#EndRegion


#Region _storageRBx		Single Storage Ring Buffer (lossy)
; ===============================================================================================================================
; ===============================================================================================================================
#cs
	_storageRBx describtion

	https://en.wikipedia.org/wiki/Circular_buffer

	Single Ring buffer. The ring buffer is stored in a single global.
#ce
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBx_Init
; Description ...: Initializes the Single Ring Buffer
; Syntax ........: _storageRBx_Init($nRingElementCount)
; Parameters ....: $nRingElementCount   - Element count
; Return values .: True					= If success
;                : False				= If the ring buffer is already initialized
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBx_Init($nRingElementCount)

	If IsArray($__storageS_RBx_Array) Then Return False

	Local $arRingBuffer[$nRingElementCount]
	$__storageS_RBx_Array = $arRingBuffer
	$__storageS_RBx_ReadPos = 0
	$__storageS_RBx_WritePos = 0

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBx_Add
; Description ...: Adds a Element to the Single Ring buffer
; Syntax ........: _storageRBx_Add($vElementData)
; Parameters ....: $vElementData        - Data of any kind
; Return values .: True					= If success
;                : False				= If the Single Buffer isnt initialized
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBx_Add($vElementData)

	If Not IsArray($__storageS_RBx_Array) Then Return False

	If UBound($__storageS_RBx_Array) == $__storageS_RBx_WritePos Then $__storageS_RBx_WritePos = 0

	$__storageS_RBx_Array[$__storageS_RBx_WritePos] = $vElementData
	$__storageS_RBx_WritePos += 1

	Return True

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBx_Get
; Description ...: Returns the oldest data of the Single Ring buffer
; Syntax ........: _storageRBx_Get()
; Parameters ....: None
; Return values .: The oldest Data
;                : False				= if not possible
; Errors ........: 1					- If the Single Buffer isnt initialized
;                : 2					- If there is no Element in the Ring Buffer
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageRBx_Get()

	If Not IsArray($__storageS_RBx_Array) Then Return SetError(1, 0, False)

	If UBound($__storageS_RBx_Array) == $__storageS_RBx_ReadPos Then $__storageS_RBx_ReadPos = 0

	Local $vElementData = $__storageS_RBx_Array[$__storageS_RBx_ReadPos]
	If $vElementData == "" Then Return SetError(2, 0, False)

	$__storageS_RBx_Array[$__storageS_RBx_ReadPos] = ""
	$__storageS_RBx_ReadPos += 1

	Return $vElementData

EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageRBx_Destroy
; Description ...: Destroys the Single Ring buffer
; Syntax ........: _storageRBx_Destroy()
; Parameters ....: None
; Return values .: None
; Modified ......:
; Remarks .......: Ring buffer can be reinitialized
; Example .......: No
; ===============================================================================================================================
Func _storageRBx_Destroy()

	$__storageS_RBx_Array = False
	$__storageS_RBx_ReadPos = False
	$__storageS_RBx_WritePos = False

EndFunc
#EndRegion
#EndRegion

; ==================================================================
#Region Specialized Methods

#EndRegion

; ==================================================================
#Region Experimental Methods

#Region _storageRBs		WIP Multi Storage Ring Buffer (lossy) (needs optimization)
#cs
	_storageRBs describtion

	Do not use.

	Dev notes:
	Needs to work similiar like OLi and MLi, as this method is only slow duo to it doing to much
	copy operations cause of the GO storage alterations. Or switch to a ByRef sub function of GO.
#ce
Func _storageRBs_CreateGroup($sRingName, $nRingElementCount)

	$sRingName = '_storageRBs' & $sRingName
	If Not _storageGO_CreateGroup($sRingName) Then Return False

	Local $arRingBuffer = _storageRBr_CreateGroup($nRingElementCount)

	Return _storageGO_Overwrite($sRingName, 'RingBuffer', $arRingBuffer)

EndFunc


Func _storageRBs_Add($sRingName, $vElementData)

	$sRingName = '_storageRBs' & $sRingName
	Local $arRingBuffer = _storageGO_Read($sRingName, 'RingBuffer')
	If Not IsArray($arRingBuffer) Then Return False

	_storageRBr_Add($arRingBuffer, $vElementData)

	Return _storageGO_Overwrite($sRingName, 'RingBuffer', $arRingBuffer)

EndFunc


Func _storageRBs_Get($sRingName)

	$sRingName = '_storageRBs' & $sRingName
	Local $arRingBuffer = _storageGO_Read($sRingName, 'RingBuffer')
	If Not IsArray($arRingBuffer) Then Return False

	Local $vElementData = _storageRBr_Get($arRingBuffer)
	if @error Then Return SetError(1, 0, False)
	_storageGO_Overwrite($sRingName, 'RingBuffer', $arRingBuffer)

	Return $vElementData

EndFunc


Func _storageRBs_DestroyGroup($sRingName)
	Return _storageGO_DestroyGroup('_storageRBs' & $sRingName)
EndFunc
#EndRegion
#EndRegion
#EndRegion


; ===============================================================================================================================
#Region Settings Storages
#cs

#ce

; ==================================================================
#Region Standard Methods

#EndRegion

; ==================================================================
#Region Specialized Methods

#EndRegion

; ==================================================================
#Region Experimental Methods

#Region _storageOS		WIP GO based Setting storage
Func _storageOS_CreateGroup($vElementGroup, $mDefaultMap = Default)
	$vElementGroup = 'g' & $vElementGroup
	If $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False

	If Not IsMap($mDefaultMap) Then
		Local $mElementGroup[]

		__storageGO_Claim($vElementGroup, $mElementGroup)
		Return True
	EndIf

	__storageGO_Claim($vElementGroup, $mDefaultMap)

	Return True
EndFunc

Func _storageOS_Set($vElementGroup, $sElementName, $vElementData)
	$vElementGroup = 'g' & $vElementGroup
	If Not $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False
	Execute('__storageS_AssignMapData($__storageGO_' & $__storageS_GO_PosObject($vElementGroup) & ', $sElementName, $vElementData)')
EndFunc

Func _storageOS_ByRef($vElementGroup, $sElementName, $sFuncName, $vAdditionalData = Null)
	If Not $__storageS_GO_PosObject.Exists('g' & $vElementGroup) Then Return False
	Return Execute($sFuncName & '($__storageGO_' & $__storageS_GO_PosObject('g' & $vElementGroup) & '[$sElementName]' & ',$vElementGroup,$vAdditionalData)')
EndFunc

Func _storageOS_Get($vElementGroup, $sElementName)
	$vElementGroup = 'g' & $vElementGroup
	If Not $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False
	Return Eval('__storageGO_' & $__storageS_GO_PosObject($vElementGroup))[$sElementName]
EndFunc

Func _storageOS_DestroyGroup($vElementGroup)
	$vElementGroup = 'g' & $vElementGroup
	if Not $__storageS_GO_PosObject.Exists($vElementGroup) Then Return False

	Local $nPos = $__storageS_GO_PosObject($vElementGroup)
	If $nPos == "" Then ; scrap storage

		Return Assign('__storageGO_' & $nPos, Null)

	Else

		; tidy
		Assign('__storageGO_' & $nPos, Null)

		; free
		$__storageS_GO_PosObject.Remove($vElementGroup)

		; add to index
		$__storageS_GO_IndexObject($nPos)

		Return True

	EndIf
EndFunc
#EndRegion

#Region _storageMS		WIP GM based Setting storage
Func _storageMS_CreateGroup($vElementGroup, $mDefaultMap = Default)
	If MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	If Not IsMap($mDefaultMap) Then
		Local $mElementGroup[]

		__storageGM_Claim($vElementGroup, $mElementGroup)
		Return True
	EndIf
	__storageGM_Claim($vElementGroup, $mDefaultMap)

	Return True
EndFunc

Func _storageMS_Set($vElementGroup, $sElementName, $vElementData)
	Execute('__storageS_AssignMapData($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & ', $sElementName, $vElementData)')
EndFunc

Func _storageMS_ByRef($vElementGroup, $sElementName, $sFuncName, $vAdditionalData = Null)
	Return Execute($sFuncName & '($__storageGM_' & $__storageS_GM_PosMap[$vElementGroup] & '[$sElementName]' & ',$vElementGroup,$vAdditionalData)')
EndFunc

Func _storageMS_Get($vElementGroup, $sElementName)
	if Not MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False
	Return Eval('__storageGM_' & $__storageS_GM_PosMap[$vElementGroup])[$sElementName]
EndFunc

Func _storageMS_DestroyGroup($vElementGroup)
	If Not MapExists($__storageS_GM_PosMap, $vElementGroup) Then Return False

	Local $nPos = $__storageS_GM_PosMap[$vElementGroup]
	If $nPos == "" Then ; scrap storage

		Return Assign('__storageGM_' & $nPos, Null)

	Else

		; tidy
		Assign('__storageGM_' & $nPos, Null)

		; free
		MapRemove($__storageS_GM_PosMap, $vElementGroup)

		; add to index
		$__storageS_GM_IndexMap[$nPos] = Null

		Return True

	EndIf
EndFunc
#EndRegion
#EndRegion
#EndRegion




; ===============================================================================================================================
#Region Miscellaneous Functions
; #FUNCTION# ====================================================================================================================
; Name ..........: _storageS_GetVarSize
; Description ...: Returns the Size of the given Variable
; Syntax ........: _storageS_GetVarSize($vData)
; Parameters ....: $vData               - Variable
; Return values .: None
; Modified ......:
; Remarks .......: Objects, Maps and functions are not supported. Array's 1D or 2D of any size.
;                : Function is recursive. Arrays in Arrays in Arrays ... a dozen times will crash Autoit.
;                : Slow and very likely not accurate.
; Example .......: No
; ===============================================================================================================================
Func _storageS_GetVarSize($vData)
	Switch VarGetType($vData)

		Case 'String', 'Binary'
			Return StringLen($vData)

		Case 'Int32', 'Int64', 'Double', 'Float'
			Return StringLen($vData)

		Case 'Ptr'
			Return StringLen($vData)

		Case 'Keyword'
			Return 1

		Case 'Bool'
			Return 1

		Case 'DLLStruct'
			Return DllStructGetSize($vData)

		Case 'Array'
			Local $nY = UBound($vData), $nX = UBound($vData, 2)

			If $nY == 0 Then Return 0
			Local $nLen = 0

			if $nX == 0 Then

				For $iY = 0 To $nY - 1
					$nLen += _storageS_GetVarSize($vData[$iY])
				Next

			ElseIf $nX > 0 Then

				For $iY = 0 To $nY - 1
					For $iX = 0 To $nX - 1
						$nLen += _storageS_GetVarSize($vData[$iY][$iX])
					Next
				Next

			EndIf

			Return $nLen

	EndSwitch
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageS_AntiCECheck
; Description ...: Checks for if the given string is blacklisted for the Execute() functions
; Syntax ........: _storageS_AntiCECheck($sCheck)
; Parameters ....: $sCheck              - a string value.
; Return values .: True / False			= Is blacklisted / Is not
; Modified ......:
; Remarks .......: Is automatically used by the _storageX_Execute functions.
;                : Does not Parse the given string but rather checks if the given string as is, is blacklisted.
; Example .......: No
; ===============================================================================================================================
Func _storageS_AntiCECheck($sCheck)
	Return _storageGLx_Exists("ANTICE", StringUpper($sCheck))
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageS_AntiCEAdd
; Description ...: Adds your own Blacklist items to the default
; Syntax ........: _storageS_AntiCEAdd($sCheck)
; Parameters ....: $sCheck              - a string value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageS_AntiCEAdd($sCheck)
	_storageGLx_AddElement("ANTICE", StringUpper($sCheck))
EndFunc


; #FUNCTION# ====================================================================================================================
; Name ..........: _storageS_AntiCERemove
; Description ...: Removes the given string from the Blacklist
; Syntax ........: _storageS_AntiCERemove($sCheck)
; Parameters ....: $sCheck              - a string value.
; Return values .: None
; Modified ......:
; Remarks .......:
; Example .......: No
; ===============================================================================================================================
Func _storageS_AntiCERemove($sCheck)
	_storageGLx_RemoveElement("ANTICE", StringUpper($sCheck))
EndFunc
#EndRegion





; Internal Barrier
; ===============================================================================================================================
; ===============================================================================================================================
; ===============================================================================================================================
; ===============================================================================================================================
; ===============================================================================================================================

#Region Method Startups
Func __storageGO_Startup()

	Local $sVarName = '__storageGO_'

	; check if already started
	Eval($sVarName & "1")

	; if already started then return
	If Not @error Then Return False

	; assign a single storage
	Assign($sVarName & "1", Null, 2)

	; set size and current index
	$__storageS_GO_Size = 1

	; add single storage to the index object
	$__storageS_GO_IndexObject(1)

EndFunc

Func __storageAL_Startup()
	_storageGO_CreateGroup('_storageAL')
EndFunc

Func __storageAO_Startup()

	If IsArray($__storageS_AO_StorageArray) Then Return

	Local $arElementGroup[1]
	$__storageS_AO_StorageArray = $arElementGroup
	$__storageS_AO_IndexObject(0)

EndFunc

Func __storageML_Startup()
	If $__storageS_ML_Maps == False Then
		Local $mGlobal[]
		$__storageS_ML_Maps = $mGlobal

		Return True
	EndIf

	Return False
EndFunc

; uses GLx, since the blacklist stays persistent for the whole runtime
Func __storageS_AntiCE_Startup()

	Local $arBlacklistStrings = StringSplit("SHELLEXECUTE;SHELLEXECUTEWAIT;RUN;RUNWAIT;RUNAS;CALL;EXECUTE;ASSIGN;EVAL;INETGET;INETREAD;OBJCREATE;MSGBOX", ';', 1)

	For $i = 1 To $arBlacklistStrings[0]
		_storageGLx_AddElement("ANTICE", $arBlacklistStrings[$i])
	Next

EndFunc
#EndRegion

#Region Group Vars
; the add group var functions cannot be map based. That would limit their size duo to Maps becoming slower the larger they are.
Func __storageG_AddGroupVar($vElementGroup, $sElementName)
	Local $oGroupVars = Eval("StorageS" & $vElementGroup)
	If IsObj($oGroupVars) == 0 Then
		$oGroupVars = ObjCreate("Scripting.Dictionary")
	EndIf

	$oGroupVars(String($sElementName))
	Assign("StorageS" & $vElementGroup, $oGroupVars, 2)
EndFunc

Func __storageGi_AddGroupVar($vElementGroup, $sElementName)
	Execute('__storageS_AssignMap($StorageGi' & $vElementGroup & ', $sElementName)')
	If @error Then Return False
	Return True
EndFunc

Func __storageGO_AddGroupVar($vElementGroup, $sElementName)
	If Not $__storageS_GO_GroupObject.Exists('g' & $vElementGroup) Then Return False
	$oGroupVars = $__storageS_GO_GroupObject('g' & $vElementGroup)

	$oGroupVars(String($sElementName))
	$__storageS_GO_GroupObject('g' & $vElementGroup) = $oGroupVars
	Return True
EndFunc

Func __storageAO_AddGroupVar($vElementGroup, $sElementName)
	If Not $__storageS_AO_GroupObject.Exists('g' & $vElementGroup) Then Return False
	$oGroupVars = $__storageS_AO_GroupObject('g' & $vElementGroup)

	$oGroupVars(String($sElementName))
	$__storageS_AO_GroupObject('g' & $vElementGroup) = $oGroupVars
	Return True
EndFunc
#EndRegion

#Region Playground
#EndRegion

; for the direct assign globals access
Func __storageS_AssignMap(ByRef $Var, Byref $Item)
	$Var[$Item] = Null
EndFunc

; for the direct assign globals access
Func __storageS_AssignMapData(ByRef $Var, Byref $Item, ByRef $Data)
	$Var[$Item] = $Data
EndFunc

; required for functions that share go storages
Func __storageGO_Claim($vElementGroup, $vElementData)
	If $__storageS_GO_IndexObject.Count == 0 Then ; no free storage available

		; increase size
		$__storageS_GO_Size += 1

		; claim it
		$__storageS_GO_PosObject($vElementGroup) = $__storageS_GO_Size

		; assign and return
		Return Assign('__storageGO_' & $__storageS_GO_Size, $vElementData, 2)

	Else ; pick a free storage

		; eh, how do i pick the first element in a dictobj
		For $i In $__storageS_GO_IndexObject
			Local $nPos = $i
			ExitLoop
		Next

		; claim it
		$__storageS_GO_IndexObject.Remove($nPos)
		$__storageS_GO_PosObject($vElementGroup) = $nPos

		; assign data and return
		Return Assign('__storageGO_' & $nPos, $vElementData, 2)

	EndIf
EndFunc

; required for functions that share gm storages
Func __storageGM_Claim($vElementGroup, $vElementData)
	Local $arIndexMap = MapKeys($__storageS_GM_IndexMap)
	If UBound($arIndexMap) == 0 Then

		; increase size
		$__storageS_GM_Size += 1

		; claim pos
		$__storageS_GM_PosMap[$vElementGroup] = $__storageS_GM_Size

		; assign and return
		Return Assign('__storageGM_' & $__storageS_GM_Size, $vElementData, 2)

	Else

		; claim pos
		MapRemove($__storageS_GM_IndexMap, $arIndexMap[0])
		$__storageS_GM_PosMap[$vElementGroup] = $arIndexMap[0]

		; assign and return
		Return Assign('__storageGM_' & $arIndexMap[0], $vElementData, 2)

	EndIf
EndFunc

; is required to fix stripper cuts
Func __storageS_StripFix()

	Return

	Local $1 = Null, $2 = Null, $3 = Null
	__storageS_AssignMap($1, $2)
	__storageS_AssignMapData($1, $2, $3)
EndFunc