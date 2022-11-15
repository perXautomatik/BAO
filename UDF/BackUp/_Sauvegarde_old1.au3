#cs

Copyright 2019 Bastien Rouches

This file is part of "Boîte A Outils"

    Boîte A Outils is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Boîte A Outils is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Boîte A Outils.  If not, see <https://www.gnu.org/licenses/>.
#ce

Func _SauvegardeAutomatique()

	_ChangerEtatBouton($iIDAction, "Patienter")

	; Known folders windows
	Local $mListeSVG[]
	$mListeSVG["{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"] = "Desktop"
	$mListeSVG["{56784854-C6CB-462b-8169-88E350ACB882}"] = "Contacts"
	$mListeSVG["{1777F761-68AD-4D8A-87BD-30B759FA33DD}"] = "Favorites"
	$mListeSVG["{374DE290-123F-4565-9164-39C4925E467B}"] = "Downloads"
	$mListeSVG["{FDD39AD0-238F-46AF-ADB4-6C85480369C7}"] = "Documents"
	$mListeSVG["{33E28130-4E1E-4676-835A-98395C3BC3BB}"] = "Pictures"
	$mListeSVG["{4BD8D571-6D19-48D3-BE97-422220080E43}"] = "Music"
	$mListeSVG["{18989B1D-99B5-455B-841C-AB7C74E4DDFC}"] = "Videos"
	$mListeSVG["{A52BBA46-E9E1-435F-B3D9-28DAA648C0F6}"] = "OneDrive"


	Local $bNet = False, $iBrowser = 0, $iExtpassword = 0, $iWifi = 0

	Local $hGUIsvg = GUICreate("Sauvegarde et restauration", 400, 240)
	GUICtrlCreateTab(10, 10, 380, 220)
	GUICtrlCreateTabItem("Sauvegarde")
	GUICtrlCreateLabel("Choisissez la source", 20, 40)
	GUICtrlSetData($statusbar, "Recherche en cours")
	GUICtrlSetData($statusbarprogress, 33)
	Local $iIDComboSource = GUICtrlCreateCombo(_WinAPI_ShellGetKnownFolderPath("{5E6C858F-0E22-4760-9AFE-EA3317B67173}"),20, 55, 360)

	Local $aDrive = DriveGetDrive ($DT_ALL)
	If @error = 0 Then
		For $i = 1 To $aDrive[0]
			If (StringUpper($aDrive[$i]) <> $HomeDrive AND DriveGetType($aDrive[$i]) = "Fixed") Then
				If(FileExists($aDrive[$i] & "\Users")) Then
					Local $aUsers = _FileListToArrayRec($aDrive[$i] & "\Users", "*|Default*;All Users;Public", 2)
					If @error = 0 Then
						For $k=1 To $aUsers[0]
							GUICtrlSetData($statusbarprogress, 66)
							GUICtrlSetData($iIDComboSource, StringUpper($aDrive[$i]) & "\Users\"& $aUsers[$k])
						Next
					EndIf
				EndIf
			EndIf
		Next
	EndIf

	GUICtrlSetData($statusbar, "")
	GUICtrlSetData($statusbarprogress, 0)

	GUICtrlCreateLabel("Choisissez la destination", 20, 80)
	Local $sFolderD = $sDossierRapport
	Local $iIDInput = GUICtrlCreateInput($sFolderD,20, 95, 260)
	Local $iIDBrowse = GUICtrlCreateButton("Parcourir",290, 92, 90, 25)

	Local $aDrive = DriveGetDrive ($DT_ALL)
	Local $sDossierDesti, $sLetter

;~ 	For $i = 1 To $aDrive[0]
;~ 		If (DriveGetType($aDrive[$i]) = "Removable" Or DriveGetType($aDrive[$i]) = "Fixed") Then
;~ 			If(DriveSpaceFree($aDrive[$i]) > 1000) Then
;~ 				GUICtrlSetData($iIDInput, StringUpper($aDrive[$i]) & " [" & DriveGetLabel($aDrive[$i]) & "] - Espace libre : " & Round((DriveSpaceFree($aDrive[$i]) / 1024), 2) & " Go")
;~ 			EndIf
;~ 		EndIf
;~ 	Next

	Local $iIDCheckBrowser = GUICtrlCreateCheckbox("Sauvegarder infos navigateurs (Edge, Chrome, Firefox)", 20, 120)
	Local $iIDCheckExtpassword = GUICtrlCreateCheckbox("Exporter avec ExtPassword! (Nirsoft)", 20, 140)
	Local $iIDCheckWifi = GUICtrlCreateCheckbox("Exporter les profils WiFi", 20, 160)

	Local $iIDButtonDemarrer = GUICtrlCreateButton("Sauvegarder", 100, 190, 90, 25, $BS_DEFPUSHBUTTON)
	Local $iIDButtonAnnuler = GUICtrlCreateButton("Annuler", 210, 190, 90, 25)

	GUICtrlCreateTabItem("Restauration")
	Local $sFolderRestau
	GUICtrlCreateLabel("Choisissez le dossier à restaurer", 20, 40)
	Local $iIDInputrestaur = GUICtrlCreateInput("",20, 55, 260)
	Local $iIDBrowserestaur = GUICtrlCreateButton("Parcourir",290, 52, 90, 25)
	Local $iIDRestaurUtil = GUICtrlCreateCheckbox("Restaurer dans les dossiers utilisateur", 20, 90)
	Local $iIDRestauBureau = GUICtrlCreateCheckbox("Restaurer le contenu du bureau dans un sous dossier", 20, 110)
	GUICtrlSetState($iIDRestauBureau, $GUI_DISABLE)
	Local $iIDRestauFavoris = GUICtrlCreateCheckbox("Restaurer les infos de Edge, Chrome et Firefox", 20, 130)
	Local $iIDRestauWifi = GUICtrlCreateCheckbox("Importer les profils WiFi", 20, 150)

	Local $iIDButtonDemarrerRestau = GUICtrlCreateButton("Restaurer", 100, 190, 90, 25, $BS_DEFPUSHBUTTON)
	Local $iIDButtonAnnulerRestau = GUICtrlCreateButton("Annuler", 210, 190, 90, 25)

	GUICtrlCreateTabItem("Réseau")
	GUICtrlCreateGroup("PC Source", 20, 40, 360, 130)
	GUICtrlCreateLabel("Nom de l'ordinateur de destination :", 30, 55)
	Local $iIDInputNameComput = GUICtrlCreateInput("", 230, 52, 140)
	Local $iIDCheckBrowserreseau = GUICtrlCreateCheckbox("Sauvegarder infos navigateurs (Edge, Chrome, Firefox)", 30, 75)
	Local $iIDCheckExtpasswordreseau = GUICtrlCreateCheckbox("Exporter avec ExtPassword! (Nirsoft)", 30, 95)
	Local $iIDCheckWifireseau = GUICtrlCreateCheckbox("Exporter les profils WiFi", 30, 115)
	Local $iIDInputCopier = GUICtrlCreateButton("Démarrer la copie", 140, 140, 120)
	GUICtrlSetTip(-1, 'Chemin vers le partage : "\\' & @ComputerName & '\SAUV"')
	GUICtrlCreategroup("PC Destination", 20,175, 360, 50)
	Local $iIDPCSource= GUICtrlCreateButton("Activer le partage", 30, 195, 120)
	GUICtrlSetTip(-1, 'Dossier de destination : "' & $sDossierRapport & '\Sauvegarde réseau"')
	If _FichierCacheExist("Partage") And _FichierCache("Partage") = 1 Then
		_ChangerEtatBouton($iIDPCSource, "Activer")
	EndIf
	;GUICtrlCreateLabel("Nom de l'ordinateur : ", 30, 175)
	Local $iIDInputShare = GUICtrlCreateInput(@ComputerName, 160, 195, 150)
	GUICtrlSetState(-1, $GUI_DISABLE)
	Local $iIDInputCopy = GUICtrlCreateButton("Copier", 320, 195, 50)

	GUICtrlCreateTabItem("")
	GUISetState(@SW_SHOW)

	Local $eGet = GUIGetMsg()

	While $eGet <> $GUI_EVENT_CLOSE And $eGet <> $iIDButtonAnnuler And $eGet <> $iIDButtonDemarrer And $eGet <> $iIDButtonAnnulerRestau
		If $eGet = $iIDComboSource Then
			If(GUICtrlRead($iIDComboSource) = _WinAPI_ShellGetKnownFolderPath("{5E6C858F-0E22-4760-9AFE-EA3317B67173}")) Then
				GUICtrlSetState ($iIDCheckWifi, $GUI_ENABLE)
			Else
				GUICtrlSetState ($iIDCheckWifi, $GUI_UNCHECKED)
				GUICtrlSetState ($iIDCheckWifi, $GUI_DISABLE)
			EndIf
		ElseIf $eGet = $iIDBrowse Then
			$sFolderD = FileSelectFolder("Dossier de destination", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}")
			GUICtrlSetData($iIDInput, $sFolderD)
		ElseIf $eGet = $iIDBrowserestaur Then
			$sFolderRestau = FileSelectFolder("Dossier à restaurer", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}")
			GUICtrlSetData($iIDInputrestaur, $sFolderRestau)
		ElseIf $eGet = $iIDRestaurUtil Then
			If(GUICtrlRead($iIDRestaurUtil) = $GUI_CHECKED) Then
				GUICtrlSetState($iIDRestauBureau, $GUI_ENABLE)
			Else
				GUICtrlSetState($iIDRestauBureau, BitOR($GUI_DISABLE, $GUI_UNCHECKED))
			EndIf
		ElseIf $eGet = $iIDButtonDemarrerRestau Then
			If FileExists(GUICtrlRead($iIDInputrestaur)) Then
				If StringInStr(GUICtrlRead($iIDInputrestaur), $sDossierRapport) And GUICtrlRead($iIDRestaurUtil) = $GUI_UNCHECKED Then
					_Attention("La source et la destination de la sauvegarde sont identiques, choisissez un autre emplacement")
				Else
					ExitLoop
				EndIf
			Else
				_Attention('Le dossier "' & GUICtrlRead($iIDInputrestaur) & '"' & " n'existe pas")
			EndIf
		ElseIf $eGet = $iIDInputCopy Then
			ClipPut(GUICtrlRead($iIDInputShare))
		ElseIf $eGet = $iIDPCSource Then
			If _FichierCacheExist("Partage") And _FichierCache("Partage") = 1 Then
				_FileWriteLog($hLog, 'Désactivation du partage')
				RunWait(@ComSpec & ' /C net user bao_share /delete', "", @SW_HIDE)
				RunWait(@ComSpec & ' /C net share SAUV /delete', "", @SW_HIDE)
				_ChangerEtatBouton($iIDPCSource, "Desactiver")
				_FichierCache("Partage",2)
			Else

				Local $sEverybody

				Dim $Obj_WMIService = ObjGet("winmgmts:\\" & "localhost" & "\root\cimv2")
				Dim $Obj_Services = $Obj_WMIService.ExecQuery("Select name from Win32_SystemAccount where SID='S-1-1-0'")
				Local $Obj_Item
				For $Obj_Item In $Obj_Services
					$sEverybody = $Obj_Item.Name
				Next

				if $sEverybody <> "" Then
					DirCreate($sDossierRapport & "\Sauvegarde réseau")
					; Création d'un user pour le partage
					RunWait(@ComSpec & ' /C net user bao_share bao /add', "", @SW_HIDE)
					RunWait(@ComSpec & ' /C net share SAUV /delete&net share SAUV="' & $sDossierRapport & "\Sauvegarde réseau" & '" /GRANT:"bao_share",FULL&CACLS "' & $sDossierRapport & "\Sauvegarde réseau" & '" /e /p "' & $sEverybody & '":f"', "", @SW_HIDE)
					_ChangerEtatBouton($iIDPCSource, "Activer")
					_FichierCache("Partage",1)
				Else
					_Attention("Le compte 'Tout le monde' est introuvable pour le partage de " & $sDossierRapport & "\Sauvegarde réseau")
				EndIf
			EndIf
		ElseIf $eGet = $iIDInputCopier Then
			If GUICtrlRead($iIDInputNameComput) = "" Then
				_Attention("Merci d'indiquer le nom de l'ordinateur de destination")
			Else
				RunWait(@ComSpec & ' /C net use \\' & GUICtrlRead($iIDInputNameComput) & '\SAUV /USER:bao_share bao', "", @SW_HIDE)
				If FileExists("\\" & GUICtrlRead($iIDInputNameComput) & "\SAUV") Then
					$bNet = True
					ExitLoop
				Else
					_Attention("Le partage réseau n'a pas été trouvé, essayez de redémarrer l'ordinateur")
				EndIf
			EndIf
		EndIf
		$eGet = GUIGetMsg()
	WEnd

	If($eGet = $iIDButtonDemarrer Or $eGet = $iIDInputCopier) Then

		; Sauvegarde session actuelle
		If($bNet Or GUICtrlRead($iIDComboSource) = _WinAPI_ShellGetKnownFolderPath("{5E6C858F-0E22-4760-9AFE-EA3317B67173}")) Then

			$sLetter = StringLeft(GUICtrlRead($iIDInput), 2)

			If $bNet Then
				_FileWriteLog($hLog, 'Sauvegarde via le réseau')
				$sDossierDesti = "\\" & GUICtrlRead($iIDInputNameComput) & "\SAUV"
				If(GUICtrlRead($iIDCheckBrowserreseau) = $GUI_CHECKED) Then
					$iBrowser = 1
				EndIf

				If(GUICtrlRead($iIDCheckExtpasswordreseau) = $GUI_CHECKED) Then
					$iExtpassword = 1
				EndIf

				If(GUICtrlRead($iIDCheckWifireseau) = $GUI_CHECKED) Then
					$iWifi = 1
				EndIf
			ElseIf(GUICtrlRead($iIDInput) = $sDossierRapport) Then
 				_Attention('La destination étant incluse dans la source, les fichiers seront sauvegardés dans le dossier "' & $sLetter & "\Sauvegarde " & $sNom & " du " & StringReplace(_NowDate(),"/","") & '"')
				$sDossierDesti = $sLetter & "\Sauvegarde " & $sNom & " du " & StringReplace(_NowDate(),"/","")
				DirCreate($sDossierDesti)
				FileCreateShortcut($sDossierDesti & "\", $sDossierRapport & "\Sauvegarde.lnk")
			Else
				$sDossierDesti = GUICtrlRead($iIDInput) & "\Sauvegarde " & $sNom & " du " & StringReplace(_NowDate(),"/","")
 			EndIf

			If $bNet = False Then
				_FileWriteLog($hLog, 'Sauvegarde des documents de la session ouverte')
				If(GUICtrlRead($iIDCheckBrowser) = $GUI_CHECKED) Then
					$iBrowser = 1
				EndIf

				If(GUICtrlRead($iIDCheckExtpassword) = $GUI_CHECKED) Then
					$iExtpassword = 1
				EndIf

				If(GUICtrlRead($iIDCheckWifi) = $GUI_CHECKED) Then
					$iWifi = 1
				EndIf
			EndIf

			GUIDelete()

			If($sLetter <> "" And DirCreate($sDossierDesti & '\Autres données\') = 1) Then

				_FileWriteLog($hLog, 'Sauvegarde destination : "' & $sDossierDesti & '"')

				If $iExtpassword = 1 And MapExists($aMenu, "extpassword") Then
					_Telecharger($aMenu["extpassword"])
					TrayTip ( "Aide", 'Cliquez sur "View > HTML Report - All Items"', 10 , 1 )
					Local $iPidW = _Executer("extpassword")
					While(ProcessExists($iPidW))
						If FileExists(@ScriptDir & "\Cache\Download\extpassword\report.html") Then
							Sleep(2000)
							FileMove(@ScriptDir & "\Cache\Download\extpassword\report.html", $sDossierDesti & "\Autres données\ExtPasswordReport.html", 1)
							_FileWriteLog($hLog, 'ExtPasswordReport.html généré')
							ProcessClose($iPidW)
						EndIf
					WEnd
				EndIf

				If $iBrowser = 1 Then

					; navigateurs pris en charge
					Local $mProfilsBrowsers[]
					$mProfilsBrowsers["Chrome"]=@LocalAppDataDir & "\Google\Chrome"
					$mProfilsBrowsers["Chromium"]=@LocalAppDataDir & "\Chromium"
					$mProfilsBrowsers["Edge"]=@LocalAppDataDir & "\Microsoft\Edge"
					$mProfilsBrowsers["Brave"]=@LocalAppDataDir & "\BraveSoftware\Brave-Browser"
					$mProfilsBrowsers["AvastBrowser"]=@LocalAppDataDir & "\AVAST Software\Browser"
					$mProfilsBrowsers["Opera"]=@AppDataDir & "\Opera Software\Opera Stable"

					Local $aBrowsers = MapKeys($mProfilsBrowsers)

					; Firefox
					If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles")) Then
						Local $iSizeBookmarkFF = 0
						Local $aTempFF = _FileListToArray(@AppDataDir & "\Mozilla\Firefox\Profiles\", "*", 2)
						;_Attention(@ScriptDir & "\Outils\sqlite3.dll")
						_SQLite_Startup(@ScriptDir & "\Outils\sqlite3.dll", False, 1)
						;MsgBox(0, "",_SQLite_LibVersion())
						For $sTmpDoc In $aTempFF
							If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\bookmarkbackups")) Then
								DirCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\bookmarkbackups", $sDossierDesti & "\Autres données\Firefox\", 1)
								_FileWriteLog($hLog, "Marque-pages de Firefox (" & $sTmpDoc & ") sauvegardés")
							EndIf
							If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite")) Then

								FileCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\places.sqlite", 9)
								If $iSizeBookmarkFF <> 0 And FileGetSize(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite") > $iSizeBookmark Then
									$iSizeBookmarkFF = FileGetSize(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite"
									Local $hFileSizeFF = FileOpen($sDossierDesti & "\Autres données\Firefox.txt", 2)
									FileWriteLine($hFileSizeFF, $sTmpDoc)
									FileClose($hFileSizeFF)
								EndIf
								_FileWriteLog($hLog, "Nettoyage du profil " & $sTmpDoc & " de Firefox")
								; Nettoyage de l'historique tout en gardant les favoris:
								;ConsoleWrite("_SQLite_LibVersion=" & _SQLite_LibVersion() & @CRLF)
								_SQLite_Open($sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\places.sqlite")
								_SQLite_Exec(-1, "DELETE FROM moz_historyvisits; VACUUM;")
								_SQLite_Close()
							EndIf
							If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\logins.json") And FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\key4.db")) Then
								FileCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\logins.json", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\logins.json", 9)
								FileCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\key4.db", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\key4.db", 9)
							EndIf
						Next
						_SQLite_Shutdown()
					Else
						_FileWriteLog($hLog, "Firefox : aucun profil trouvé")
					EndIf

					For $sBrowser in $aBrowsers
						Local $iSizeBookmark
						If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Default\")) Then
							_FileWriteLog($hLog, 'Sauvegarde de ' & $sBrowser)
							If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Bookmarks")) Then
								$iSizeBookmark = FileGetSize($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Bookmarks)
								FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Bookmarks", $sDossierDesti & "\Autres données\" & $sBrowser & "\Default\Bookmarks", 9)
							EndIf
							If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Login Data")) Then
								FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Login Data", $sDossierDesti & "\Autres données\" & $sBrowser & "\Default\Login Data", 9)
							EndIf

							Local $iProfil = 1
							While FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\"))
								If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks")) Then
									If  FileGetSize($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks") > $iSizeBookmark Then
										$iSizeBookmark = FileGetSize($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks"
										Local $hFileSize = FileOpen($sDossierDesti & "\Autres données\" & $sBrowser & ".txt", 2)
										FileWriteLine($hFileSize, "Profile " & $iProfil)
										FileClose($hFileSize)
									EndIf
									FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks", $sDossierDesti & "\Autres données\" & $sBrowser & "\Profile " & $iProfil & "\Bookmarks", 9)
								EndIf
								If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Login Data")) Then
									FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Login Data", $sDossierDesti & "\Autres données\" & $sBrowser & "\Profile " & $iProfil & "\Login Data", 9)
								EndIf
								$iProfil += 1
							WEnd
						Else
							_FileWriteLog($hLog, $sBrowser & " : aucun profil trouvé")
						EndIf
					Next
				EndIf

				If $iWifi = 1 Then
					DirCreate($sDossierDesti & '\Autres données\WiFi')
					RunWait(@ComSpec & ' /c netsh wlan export profile key = clear folder = "' & $sDossierDesti & '\Autres données\WiFi"', '', @SW_HIDE)
					;ClipPut(@ComSpec & ' /c netsh wlan export profile key = clear folder = ' & $sDossierDesti & "\Autres données\WiFi")
					If DirRemove($sDossierDesti & '\Autres données\WiFi') Then
						_FileWriteLog($hLog, 'Aucun profil WiFi trouvé')
					Else
						_FileWriteLog($hLog, 'Profils WiFi sauvegardés')
						Local $hBatWiFi = FileOpen($sDossierDesti & "\Autres données\WiFi\Import profils wifi.bat", 1)
						FileWriteLine($hBatWiFi, '@echo off')
						FileWriteLine($hBatWiFi, '')
						FileWriteLine($hBatWiFi, 'for %%f in (.\*.xml) do (')
						FileWriteLine($hBatWiFi, 'netsh wlan add profile filename=".\%%f"')
						FileWriteLine($hBatWiFi, ')')
					EndIf
				EndIf

				Local $iInc = Round(100/8)

				Local $aKeysDocs = MapKeys($mListeSVG)

				For $sKeys In $aKeysDocs

					GUICtrlSetData($statusbar, " Copie " & _WinAPI_ShellGetKnownFolderPath($sKeys))
					GUICtrlSetData($statusbarprogress, $iInc)
					$iInc = $iInc + Round(100/8)

					If($sLetter <> "\\" And DriveSpaceFree($sLetter) < DirGetSize(_WinAPI_ShellGetKnownFolderPath($sKeys)) / 1048576) Then
						_Attention("Espace sur le disque " & $sLetter & " insuffisant")
						_FileWriteLog($hLog, 'Dossier "' & _WinAPI_ShellGetKnownFolderPath($sKeys) & '" non sauvegardé : espace disque insuffisant')
					Else
						RunWait(@ComSpec & ' /c robocopy "' & _WinAPI_ShellGetKnownFolderPath($sKeys) & '" "' &  $sDossierDesti & '\' & $mListeSVG[$sKeys] & '" /E /B /R:1 /W:1')
						_FileWriteLog($hLog, 'Dossier "' & $mListeSVG[$sKeys] & '" : ' & Round(DirGetSize($sDossierDesti & "\" & $mListeSVG[$sKeys]) / (1024 * 1024 * 1024), 2) & " sur " & Round(DirGetSize(_WinAPI_ShellGetKnownFolderPath($sKeys)) / (1024 * 1024 * 1024), 2) & " Go copiés")
					EndIf

				Next

				If(FileExists(@LocalAppDataDir & "\Microsoft\Outlook")) Then
					DirCopy(@LocalAppDataDir & "\Microsoft\Outlook", $sDossierDesti & "\Autres données\Outlook", 1)
					_FileWriteLog($hLog, "PST de Microsoft Outlook sauvegardés")
				EndIf

;~ 				FileSetPos($hFichierRapport, 0, $FILE_BEGIN)
				_FileWriteLog($hLog, 'Création du fichier"' & $sDossierDesti & '\Autres données\Infos sauvegarde.txt"')
 				Local $hFichierSauvegarde = FileOpen($sDossierDesti & "\Autres données\Infos sauvegarde.txt", 1)
;~ 				FileWrite($hFichierSauvegarde, FileRead($hFichierRapport))

				Local $aListe = _ListeProgrammes()
				$aListe = _ArrayUnique($aListe, 0, 0, 0, 0)

				FileWriteLine($hFichierSauvegarde, "Programmes installés :")
				For $sProgi in $aListe
					FileWriteLine($hFichierSauvegarde, " - " & $sProgi)
				Next
				FileWriteLine($hFichierSauvegarde, "")

				FileWriteLine($hFichierSauvegarde, "Liste des imprimantes installées :")

				Local $iPID1 = Run(@ComSpec & ' /c wmic printer get DriverName, Name, Portname', "", @SW_HIDE, $STDOUT_CHILD)
				ProcessWaitClose($iPID1)
				FileWrite($hFichierSauvegarde, _WinAPI_OemToChar(StdoutRead($iPID1)))

				Local $iPID2 = Run(@ComSpec & ' /c ipconfig /all', "", @SW_HIDE, $STDOUT_CHILD)
				ProcessWaitClose($iPID2)
				FileWrite($hFichierSauvegarde, _WinAPI_OemToChar(StdoutRead($iPID2)))

				FileClose($hFichierSauvegarde)

				GUICtrlSetData($statusbar, "")
				GUICtrlSetData($statusbarprogress, 0)
				_UpdEdit($iIDEditLog, $hLog)
				_ChangerEtatBouton($iIDAction, "Activer")
				If(_FichierCacheExist("Sauvegarde") = 0) Then
					_FichierCache("Sauvegarde", "1")
				EndIf
				If $bNet Then
					_Attention("Sauvegarde terminée")
				EndIf
			Else
				_Attention("Echec de la création du dossier " & $sDossierDesti)
				_ChangerEtatBouton($iIDAction, "Desactiver")
			EndIf
		Else
			$sLetter = StringLeft(GUICtrlRead($iIDInput), 2)
			Local $sSource = GUICtrlRead($iIDComboSource)
			Local $sPos = StringInStr($sSource, "\", 0, -1)
			Local $sUserSlave = StringTrimLeft($sSource, $sPos)

			_FileWriteLog($hLog, 'Sauvegarde de la session "' & $sSource & '"')
			$sDossierDesti =  GUICtrlRead($iIDInput) & "\Sauvegarde " & $sUserSlave & " du " & StringReplace(_NowDate(),"/","")

			GUIDelete()


			If($sLetter <> "" And DirCreate($sDossierDesti & '\Autres données\') = 1) Then

				_FileWriteLog($hLog, 'Sauvegarde sur : "' & $sDossierDesti & '"')

				If $iExtpassword = 1 And MapExists($aMenu, "extpassword") Then
					_Telecharger($aMenu["extpassword"])
					TrayTip ( "Aide", 'Saisissez "' & StringLeft(GUICtrlRead($sSource), 2) & '" dans "External Drive Path" ' & @CRLF & 'Cliquez ensuite sur "View > HTML Report - All Items"', 10 , 1 )
					Local $iPidW = _Executer("extpassword")
					ClipPut(StringLeft(GUICtrlRead($sSource), 2))
					While(ProcessExists($iPidW))
						If FileExists(@ScriptDir & "\Cache\Download\extpassword\report.html") Then
							Sleep(2000)
							FileMove(@ScriptDir & "\Cache\Download\extpassword\report.html", $sDossierDesti & "\Autres données\ExtPasswordReport.html", 1)
							_FileWriteLog($hLog, 'ExtPasswordReport.html généré')
							ProcessClose($iPidW)
						EndIf
					WEnd
				EndIf

				GUICtrlSetData($statusbar, " Copie " & $sSource & " en cours")
				GUICtrlSetData($statusbarprogress, 50)

				If(DriveSpaceFree($sLetter) < (DirGetSize($sSource) - DirGetSize($sSource & "\Appdata")) / 1048576) Then
					_Attention("Espace sur le disque " & $sLetter & " insuffisant")
					_FileWriteLog($hLog, '  Dossier "' & $sSource & '" non sauvegardé : espace disque insuffisant')
				Else
					RunWait(@ComSpec & ' /c robocopy "' & $sSource & '" "' &  $sDossierDesti & '" /E /B /R:1 /W:1 /XJ /XD "' & $sSource & '\Appdata"')
					_FileWriteLog($hLog, 'Dossier "' & $sSource & '" : ' & Round(DirGetSize($sDossierDesti) / (1024 * 1024 * 1024), 2) & " sur " & Round((DirGetSize($sSource) - DirGetSize($sSource & "\Appdata")) / (1024 * 1024 * 1024), 2) & " Go copiés")
				EndIf

				If $iBrowser = 1 Then

					; navigateurs pris en charge
					Local $mProfilsBrowsersSlave[]
					$mProfilsBrowsersSlave["Chrome"] = $sSource & "\AppData\Local\Google\Chrome"
					$mProfilsBrowsersSlave["Chromium"] = $sSource & "\AppData\Local\Chromium"
					$mProfilsBrowsersSlave["Edge"] = $sSource & "\AppData\Local\Microsoft\Edge"
					$mProfilsBrowsersSlave["Brave"] = $sSource & "\AppData\Local\BraveSoftware\Brave-Browser"
					$mProfilsBrowsersSlave["AvastBrowser"] = $sSource & "\AppData\Local\AVAST Software\Browser"
					$mProfilsBrowsersSlave["Opera"] =  $sSource & "\Roaming\Opera Software\Opera Stable"

					Local $aBrowsers = MapKeys($mProfilsBrowsers)

					; Firefox
					If(FileExists($sSource & "\Mozilla\Firefox\Profiles")) Then
						Local $iSizeBookmarkFF = 0
						Local $aTempFF = _FileListToArray(@AppDataDir & "\Mozilla\Firefox\Profiles\", "*", 2)
						;_Attention(@ScriptDir & "\Outils\sqlite3.dll")
						_SQLite_Startup(@ScriptDir & "\Outils\sqlite3.dll", False, 1)
						;MsgBox(0, "",_SQLite_LibVersion())
						For $sTmpDoc In $aTempFF
							If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\bookmarkbackups")) Then
								DirCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\bookmarkbackups", $sDossierDesti & "\Autres données\Firefox\", 1)
								_FileWriteLog($hLog, "Marque-pages de Firefox (" & $sTmpDoc & ") sauvegardés")
							EndIf
							If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite")) Then

								FileCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\places.sqlite", 9)
								If $iSizeBookmarkFF <> 0 And FileGetSize(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite") > $iSizeBookmark Then
									$iSizeBookmarkFF = FileGetSize(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite"
									Local $hFileSizeFF = FileOpen($sDossierDesti & "\Autres données\Firefox.txt", 2)
									FileWriteLine($hFileSizeFF, $sTmpDoc)
									FileClose($hFileSizeFF)
								EndIf
								_FileWriteLog($hLog, "Nettoyage du profil " & $sTmpDoc & " de Firefox")
								; Nettoyage de l'historique tout en gardant les favoris:
								;ConsoleWrite("_SQLite_LibVersion=" & _SQLite_LibVersion() & @CRLF)
								_SQLite_Open($sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\places.sqlite")
								_SQLite_Exec(-1, "DELETE FROM moz_historyvisits; VACUUM;")
								_SQLite_Close()
							EndIf
							If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\logins.json") And FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\key4.db")) Then
								FileCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\logins.json", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\logins.json", 9)
								FileCopy(@AppDataDir & "\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\key4.db", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\key4.db", 9)
							EndIf
						Next
						_SQLite_Shutdown()
					Else
						_FileWriteLog($hLog, "Firefox : aucun profil trouvé")
					EndIf

					For $sBrowser in $aBrowsers
						Local $iSizeBookmark
						If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Default\")) Then
							_FileWriteLog($hLog, 'Sauvegarde de ' & $sBrowser)
							If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Bookmarks")) Then
								$iSizeBookmark = FileGetSize($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Bookmarks)
								FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Bookmarks", $sDossierDesti & "\Autres données\" & $sBrowser & "\Default\Bookmarks", 9)
							EndIf
							If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Login Data")) Then
								FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Default\Login Data", $sDossierDesti & "\Autres données\" & $sBrowser & "\Default\Login Data", 9)
							EndIf

							Local $iProfil = 1
							While FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\"))
								If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks")) Then
									If  FileGetSize($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks") > $iSizeBookmark Then
										$iSizeBookmark = FileGetSize($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks"
										Local $hFileSize = FileOpen($sDossierDesti & "\Autres données\" & $sBrowser & ".txt", 2)
										FileWriteLine($hFileSize, "Profile " & $iProfil)
										FileClose($hFileSize)
									EndIf
									FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Bookmarks", $sDossierDesti & "\Autres données\" & $sBrowser & "\Profile " & $iProfil & "\Bookmarks", 9)
								EndIf
								If(FileExists($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Login Data")) Then
									FileCopy($mProfilsBrowsers[$sBrowser] & "\User Data\Profile " & $iProfil & "\Login Data", $sDossierDesti & "\Autres données\" & $sBrowser & "\Profile " & $iProfil & "\Login Data", 9)
								EndIf
								$iProfil += 1
							WEnd
						Else
							_FileWriteLog($hLog, $sBrowser & " : aucun profil trouvé")
						EndIf
					Next
				EndIf


				If(FileExists($sSource & "\AppData\Local\Google\Chrome\User Data\Default\Bookmarks")) Then
					FileCopy($sSource & "\AppData\Local\Google\Chrome\User Data\Default\Bookmarks", $sDossierDesti & "\Autres données\Chrome\Bookmarks", 9)
					_FileWriteLog($hLog, "Favoris de Google Chrome sauvegardés")
				EndIf

				If(FileExists($sSource & "\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks")) Then
					FileCopy($sSource & "\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks", $sDossierDesti & "\Autres données\Edge\Bookmarks", 9)
					_FileWriteLog($hLog, "Favoris de Microsoft Edge sauvegardés")
				EndIf

				If(FileExists($sSource & "\Roaming\Local\Mozilla\Firefox\Profiles")) Then
					Local $aTempFF = _FileListToArray(@AppDataDir & "\Mozilla\Firefox\Profiles\", "*", 2)
					_SQLite_Startup(@ScriptDir & "\Outils\sqlite3.dll", False, 1)
					For $sTmpDoc In $aTempFF
						If(FileExists($sSource & "\Roaming\Local\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\bookmarkbackups")) Then
							DirCopy($sSource & "\Roaming\Local\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\bookmarkbackups", $sDossierDesti & "\Autres données\Firefox\"& $sTmpDoc & "\bookmarkbackups", 9)
						EndIf
						If(FileExists($sSource & "\Roaming\Local\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite")) Then

							FileCopy($sSource & "\Roaming\Local\Mozilla\Firefox\Profiles\" & $sTmpDoc & "\places.sqlite", $sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\places.sqlite", 9)

							_FileWriteLog($hLog, "Nettoyage du profil " & $sTmpDoc & " de Firefox")
							; Nettoyage de l'historique tout en gardant les favoris:
							;ConsoleWrite("_SQLite_LibVersion=" & _SQLite_LibVersion() & @CRLF)
							_SQLite_Open($sDossierDesti & "\Autres données\Firefox\" & $sTmpDoc & "\places.sqlite")
							_SQLite_Exec(-1, "DELETE FROM moz_historyvisits; VACUUM;")
							_SQLite_Close()
						EndIf
					Next
					_SQLite_Shutdown()
					_FileWriteLog($hLog, "Marque-pages de Firefox sauvegardés et nettoyés")
				EndIf

				If(FileExists($sSource & "\AppData\Local\Microsoft\Outlook")) Then
					DirCopy($sSource& "\AppData\Local\Microsoft\Outlook", $sDossierDesti & "\Autres données\Outlook", 1)
					_FileWriteLog($hLog, "PST de Microsoft Outlook sauvegardés")
				EndIf

				GUICtrlSetData($statusbar, "")
				GUICtrlSetData($statusbarprogress, 0)
				_UpdEdit($iIDEditLog, $hLog)
				_ChangerEtatBouton($iIDAction, "Activer")
				If(_FichierCacheExist("Sauvegarde") = 0) Then
					_FichierCache("Sauvegarde", "1")
				EndIf
			Else
				_Attention("Echec de la création du dossier " & $sDossierDesti)
				_ChangerEtatBouton($iIDAction, "Desactiver")
			EndIf

		EndIf
	ElseIf $eGet = $iIDButtonDemarrerRestau Then
		Local $sDossierRestau = $sDossierRapport
		Local $iUtil, $iBureau, $iNav, $iRestWifi
		If(GUICtrlRead($iIDRestaurUtil) = $GUI_CHECKED) Then
			$iUtil = 1
			If(GUICtrlRead($iIDRestauBureau) = $GUI_CHECKED) Then
				$iBureau = 1
			EndIf
		EndIf
		If(GUICtrlRead($iIDRestauFavoris) = $GUI_CHECKED) Then
			$iNav = 1
		EndIf
		If(GUICtrlRead($iIDRestauWifi) = $GUI_CHECKED) Then
			$iRestWifi = 1
		EndIf

		Local $sDossierSourceRestau = GUICtrlRead($iIDInputrestaur)
		Local $sPossl = StringInStr($sDossierSourceRestau, "\", 0, -1)
		Local $sDossierRestau = $sDossierRapport & "\" & StringTrimLeft($sDossierSourceRestau, $sPossl)

		GUIDelete()

		_FileWriteLog($hLog, "Restauration des données")

		If $iRestWifi = 1 And FileExists($sDossierSourceRestau & "\Autres données\WiFi\") Then
			Local $aTempProfils = _FileListToArray($sDossierSourceRestau & "\Autres données\WiFi", "*.xml", 1)
			_ArrayDelete($aTempProfils, 0)
			For $sTmpWifi In $aTempProfils
				RunWait(@ComSpec & ' /c netsh wlan add profile filename="' & $sDossierSourceRestau & '\Autres données\WiFi\' & $sTmpWifi & '" user=all', '', @SW_HIDE)
				;ClipPut(@ComSpec & ' /c netsh wlan add profile filename="' & $sDossierSourceRestau & '\Autres données\WiFi\' & $sTmpWifi & '" user=all')
				_FileWriteLog($hLog, 'Profil wifi importé : ' & $sTmpWifi)
			Next
		EndIf

		If($iUtil = 0) Then
			_FileWriteLog($hLog, 'Restauration de données dans le dossier rapport')
			If(DriveSpaceFree($HomeDrive) < DirGetSize($sDossierSourceRestau) / 1048576) Then
				_Attention("Espace sur le disque " & $HomeDrive & " insuffisant")
				_FileWriteLog($hLog, '  Dossier "' & $sDossierSourceRestau & '" non restauré : espace disque insuffisant')
				_UpdEdit($iIDEditLog, $hLog)
				_ChangerEtatBouton($iIDAction, "Desactiver")
			Else
				RunWait(@ComSpec & ' /c robocopy "' & $sDossierSourceRestau & '" "' &  $sDossierRestau & '" /E /B /R:1 /W:1')
				_FileWriteLog($hLog, 'Restauration du dossier "' & $sDossierSourceRestau & '" dans "' & $sDossierRestau & '" : ')
				_FileWriteLog($hLog, @TAB & Round(DirGetSize($sDossierRestau) / (1024 * 1024 * 1024), 2) & " sur " & Round((DirGetSize($sDossierSourceRestau)) / (1024 * 1024 * 1024), 2) & " Go copiés")
				_UpdEdit($iIDEditLog, $hLog)
				_ChangerEtatBouton($iIDAction, "Activer")
				If(_FichierCacheExist("Sauvegarde") = 0) Then
					_FichierCache("Sauvegarde", "1")
				EndIf
			EndIf
		Else
			_FileWriteLog($hLog, 'Restauration de données "en place"')
			Local $iInc = Round(100/8)

			Local $aKeysDocs = MapKeys($mListeSVG)

			For $sKeys In $aKeysDocs

				GUICtrlSetData($statusbar, " Copie " & _WinAPI_ShellGetKnownFolderPath($sKeys))
				GUICtrlSetData($statusbarprogress, $iInc)
				$iInc = $iInc + Round(100/8)
				If(DriveSpaceFree($HomeDrive) < DirGetSize($sDossierSourceRestau) / 1048576) Then
					_Attention("Espace sur le disque " & $HomeDrive & " insuffisant")
					_FileWriteLog($hLog, '  Dossier "' & $sDossierSourceRestau & '" non restauré : espace disque insuffisant')
				Else
					If $iBureau = 1 And $mListeSVG[$sKeys] = "Desktop" Then
						_FileWriteLog($hLog, 'Restauration du bureau dans un sous dossier')
						;_Debug(@ComSpec & ' /c xcopy "' & $sDossierSourceRestau & '\' & $mListeSVG[$sKeys] & '" "' & _WinAPI_ShellGetKnownFolderPath($sKeys) & '" "\Sauvegarde du bureau\" /E /Y /C')
						;DirCreate(_WinAPI_ShellGetKnownFolderPath($sKeys) & '\Sauvegarde du bureau')
						RunWait(@ComSpec & ' /c xcopy "' & $sDossierSourceRestau & '\' & $mListeSVG[$sKeys] & '" "' & _WinAPI_ShellGetKnownFolderPath($sKeys) & '\Sauvegarde du bureau\" /E /Y /C')
					Else
						RunWait(@ComSpec & ' /c robocopy "' & $sDossierSourceRestau & '\' & $mListeSVG[$sKeys] & '" "' & _WinAPI_ShellGetKnownFolderPath($sKeys) & '" /E /B /R:1 /W:1')
					EndIf
					_FileWriteLog($hLog, 'Dossier "' & $mListeSVG[$sKeys] & '" : ' & Round(DirGetSize(_WinAPI_ShellGetKnownFolderPath($sKeys)) / (1024 * 1024 * 1024), 2) & " sur " & Round(DirGetSize($sDossierSourceRestau & "\" & $mListeSVG[$sKeys]) / (1024 * 1024 * 1024), 2) & " Go copiés")
				EndIf
			Next

			If FileExists($sDossierSourceRestau & "\Autres données") Then
				DirCopy($sDossierSourceRestau & "\Autres données", $sDossierRestau & "\Autres données", 0)
			Else
				_FileWriteLog($hLog, 'Dossier "Autres données" absent de la sauvegarde')
				If $iNav = 1 Then
					_Attention("Le dossier à restaurer ne contient pas les favoris des navigateurs")
					$iNav = 0
				EndIf
			EndIf

			If $iNav = 1 Then

				If(FileExists(@LocalAppDataDir & "\Microsoft\Edge\User Data\Default\")) Then
					If FileExists($sDossierSourceRestau & "\Autres données\Edge\Bookmarks") Then
						FileCopy($sDossierSourceRestau & "\Autres données\Edge\Bookmarks", @LocalAppDataDir & "\Microsoft\Edge\User Data\Default\Bookmarks", 1)
						_FileWriteLog($hLog,"Favoris de Microsoft Edge restaurés")
					Else
						_FileWriteLog($hLog, "La sauvegarde ne contient pas de favoris de Edge")
					EndIf
				Else
					_Attention("Microsoft Edge semble ne pas être installé, les favoris sont dans le dossier rapport")
				EndIf

				If(FileExists(@LocalAppDataDir & "\Google\Chrome\User Data\Default\")) Then
					If FileExists($sDossierSourceRestau & "\Autres données\Chrome\Bookmarks") Then
						FileCopy($sDossierSourceRestau & "\Autres données\Chrome\Bookmarks", @LocalAppDataDir & "\Google\Chrome\User Data\Default\Bookmarks", 1)
						_FileWriteLog($hLog,"Favoris de Google Chrome restaurés")
					Else
						_FileWriteLog($hLog, "La sauvegarde ne contient pas de favoris de Chrome")
					EndIf
				Else
					_Attention("Google Chrome semble ne pas être installé, les favoris sont dans le dossier rapport")
				EndIf

				If(FileExists(@AppDataDir & "\Mozilla\Firefox\Profiles")) Then
					Local $aTempFFsource = _FileListToArray($sDossierSourceRestau & "\Autres données\Firefox\", "*default-release", 2)
					If @error = 0 Then
						Local $sDestiFF
						Local $aTempFF = _FileListToArray(@AppDataDir & "\Mozilla\Firefox\Profiles\", "*default-release", 2)
						If @error = 0 Then
							If FileExists($sDossierSourceRestau & "\Autres données\Firefox\"& $aTempFFsource[1] &"\places.sqlite") Then
								FileCopy($sDossierSourceRestau & "\Autres données\Firefox\"& $aTempFFsource[1] &"\places.sqlite", @AppDataDir & "\Mozilla\Firefox\Profiles\" & $aTempFF[1] & "\places.sqlite", 1)
								_FileWriteLog($hLog, "Marque-pages de Firefox restaurés")
							Else
								_FileWriteLog($hLog, "Le dossier source de Firefox ne contient pas de marques pages")
							EndIf
						Else
							_FileWriteLog($hLog, "Pas de profil par défaut trouvé dans le dossier de destination pour Firefox")
						EndIf
					Else
						_FileWriteLog($hLog, "Pas de profil par défaut trouvé dans le dossier à restaurerpour Firefox")
					EndIf
				EndIf
			EndIf
			GUICtrlSetData($statusbar, "")
			GUICtrlSetData($statusbarprogress, 0)
			_UpdEdit($iIDEditLog, $hLog)
			_ChangerEtatBouton($iIDAction, "Activer")
			If(_FichierCacheExist("Sauvegarde") = 0) Then
				_FichierCache("Sauvegarde", "1")
			EndIf
		EndIf
	Else
		GUIDelete()
		_ChangerEtatBouton($iIDAction, "Desactiver")
	EndIf
EndFunc

Func _CopierSur()
	Local $hGUIcopie = GUICreate("Copie BAO sur support externe", 400, 80)

	Local $iIDCombo = GUICtrlCreateCombo("Choisissez la destination",10, 10, 380)

	Local $aDrive = DriveGetDrive ($DT_ALL)
	Local $sDossierDesti, $sLetter

	For $i = 1 To $aDrive[0]
		If (DriveGetType($aDrive[$i]) = "Removable" Or DriveGetType($aDrive[$i]) = "Fixed") Then
			If StringUpper($aDrive[$i]) <> $HomeDrive Then
				GUICtrlSetData($iIDCombo, StringUpper($aDrive[$i]) & " [" & DriveGetLabel($aDrive[$i]) & "] - Espace libre : " & Round((DriveSpaceFree($aDrive[$i]) / 1024), 2) & " Go")
			EndIf
		EndIf
	Next

	Local $iIDButtonDemarrer = GUICtrlCreateButton("Copier", 100, 40, 90, 25, $BS_DEFPUSHBUTTON)
	Local $iIDButtonAnnuler = GUICtrlCreateButton("Annuler", 210, 40, 90, 25)
	GUISetState(@SW_SHOW)

	Local $eGet = GUIGetMsg()

	While $eGet <> $GUI_EVENT_CLOSE And $eGet <> $iIDButtonAnnuler And $eGet <> $iIDButtonDemarrer
		$eGet = GUIGetMsg()
	WEnd

	If($eGet = $iIDButtonDemarrer And GUICtrlRead($iIDCombo) <> "Choisissez la destination") Then

		$sLetter = StringLeft(GUICtrlRead($iIDCombo), 2)
		GUIDelete()

		$sDossierDesti = $sLetter & "\BAO"
		_FileWriteLog($hLog, 'Copie de BAO sur "' & $sDossierDesti & '"')
		_UpdEdit($iIDEditLog, $hLog)
		GUICtrlSetData($statusbar, "Copie en cours")
		RunWait(@ComSpec & ' /c robocopy "' & @ScriptDir & '" "' &  $sDossierDesti & '" /MIR /XD "' & @ScriptDir & '\Cache\Pwd\"')
		GUICtrlSetData($statusbar, "")
		;DirCopy(@ScriptDir, $sDossierDesti, 1)
	Else
		GUIDelete()
	EndIf

EndFunc