
# This script defines a function (Invoke-RemoteDesktop) for creating and controlling a remote desktop session.
# The function takes one parameter:
# $ModeTech: a flag that indicates whether to use the technical mode or not
# The function also reads some variables from a config.ini file, such as:
# $sMailBD: the email address of the DWService account
# $sAgent: the name of the DWAgent program
# $sNom: the name of the computer

# Define the Uninstall-DWAgent function
function Uninstall-DWAgent {

    # Get the Program Files directory from the registry
    $programFilesDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir").ProgramFilesDir

    # Check if the DWAgent program exists on the system
    if (Test-Path -Path "$programFilesDir\$sAgent\runtime\dwagent.exe") {

        # Get the list of processes with the name "dwagent.exe"
        $process = Get-Process -Name "dwagent.exe"

        # For each process, stop it
        foreach ($p in $process) {
            Stop-Process -Id $p.Id
        }

        # Copy the dwaglnc.exe file from the DWAgent folder to the tmp folder
        Copy-Item -Path "$programFilesDir\$sAgent\native\dwaglnc.exe" -Destination "$env:LOCALAPPDATA\bao\tmp\" -Force

        # Run dwagent.exe with the uninstall argument
        Start-Process -FilePath "$programFilesDir\$sAgent\runtime\dwagent.exe" -ArgumentList "-S -m installer uninstall" -Wait

        # Run dwagsvc.exe with various arguments to remove auto-run, service, shortcuts, etc.
        Start-Process -FilePath "$programFilesDir\$sAgent\native\dwagsvc.exe" -ArgumentList "removeAutoRun" -Wait
        Start-Process -FilePath "$programFilesDir\$sAgent\native\dwagsvc.exe" -ArgumentList "stopService" -Wait
        Start-Process -FilePath "$programFilesDir\$sAgent\native\dwagsvc.exe" -ArgumentList "deleteService" -Wait
        Start-Process -FilePath "$programFilesDir\$sAgent\native\dwagsvc.exe" -ArgumentList "removeShortcuts" -Wait

        # Run dwaglnc.exe with the remove argument to remove the DWAgent folder
        Start-Process -FilePath "$env:LOCALAPPDATA\bao\tmp\dwaglnc.exe" -ArgumentList 'remove "' + $programFilesDir + '\DWAgent"' -Wait
    }
}
function Invoke-RemoteDesktop ($ModeTech) 
    {

    # Get the Program Files directory from the registry
    $programFilesDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir").ProgramFilesDir

    # Read the email address of the DWService account from the config.ini file
    $sMailBD = (Get-Content -Path ".\config.ini" | Select-String -Pattern "MailBD=").Line.Split("=")[1]

    # Check if the email address is not empty
    if ($sMailBD -ne "") {

        # Read the name of the DWAgent program from the config.ini file
        $sAgent = (Get-Content -Path ".\config.ini" | Select-String -Pattern "Agent=").Line.Split("=")[1]

        # Read the name of the computer from the config.ini file
        $sNom = (Get-Content -Path ".\config.ini" | Select-String -Pattern "Nom=").Line.Split("=")[1]

        # Check if the technical mode is off and if the DWAgent program exists on the system
        if (($ModeTech -eq 0) -and (Test-Path -Path "$programFilesDir\$sAgent\runtime\dwagent.exe")) {

            # Check if a cache file exists for RemoteDesktop
            if (Test-Path -Path ".\Cache\BureauDistant") {

                # Write to the log file that DWAgent is being uninstalled
                Write-Log -Message "Désinstallation DWAgent"

                # Uninstall DWAgent
                Uninstall-DWAgent

                # Change the state of the button to "Desactiver"
                Change-ButtonState -ID $iIDAction -State "Desactiver"

                # Write to the cache file that RemoteDesktop is disabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "-1"
            }
            else {

                # Write to the log file that DWAgent is already installed and activate the button "Bureau Distant"
                Write-Log -Message "DWAgent déjà installé, activation du bouton 'Bureau Distant'"

                # Write to the cache file that RemoteDesktop is enabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "1"

                # Change the state of the button to "Activer"
                Change-ButtonState -ID $iIDAction -State "Activer"

                # Disable the background image
                Disable-BackgroundImage
            }
        }
        else {

            # Check if the technical mode is off
            if ($ModeTech -eq 0) {

                # Write to the log file that RemoteDesktop is being activated
                Write-Log -Message "Activation du bureau distant"

                # Change the state of the button to "Patienter"
                Change-ButtonState -ID $iIDAction -State "Patienter"

                # Check if a menu item exists for DWAgent
                if ($aMenu.ContainsKey($sAgent)) {

                    # Download DWAgent
                    if (Download-DWAgent) {

                        # Declare some variables for storing the password and whether to save it or not
                        $sMdp = ""
                        $bSVGMdp = 0

                        # Check if a password file exists in the cache folder
                        if (Test-Path -Path ".\Cache\Pwd\dws.sha") {

                            # Decrypt and read the password from the file using a key derived from various system information
                            $sMdp = [System.Text.Encoding]::Unicode.GetString(Decrypt-Data (Get-Content -Path ".\Cache\Pwd\dws.sha") ($sMailBD + [Environment]::MachineName + [Environment]::UserName + [Environment]::UserDomainName + [Environment]::UserInteractive + [Environment]::OSVersion + [Environment]::ProcessorCount + [Environment]::SystemPageSize + [Environment]::SystemDirectory + [Environment]::TickCount64))
                        }
                        else {

                            # Create a GUI for entering and saving the password for DWService
                            $hGUIDWS = New-GUIForm -Title "Activation du bureau distant" -Width 400 -Height 105
                            New-GUILabel -Text 'Saisissez le mot de passe DWService pour "' + $sMailBD + '" :' -Left 10 -Top 15
                            $iPWD = New-GUITextBox -Left 10 -Top 42 -Width 200 -Height 20 -Password
                            $iMem = New-GUICheckBox -Text "Mémoriser le mot de passe ?" -Left 220 -Top 40
                            $iIDValider = New-GUIButton -Text "Valider" -Left 125 -Top 70 -Width 150 -Height 25

                            # Show the GUI and wait for user input
                            Show-GUIForm

                            while ($true) {

                                # Get the user input
                                $iIdDWS = Read-GUIMessage

                                # Switch on the user input
                                switch ($iIdDWS) {

                                    # If the user closes the GUI, exit the loop
                                    $GUI_EVENT_CLOSE {
                                        break
                                    }

                                    # If the user clicks the "Valider" button, get the password and whether to save it or not, and exit the loop
                                    $iIDValider {
                                        if ((Get-GUITextBoxText -ID $iPWD) -ne "") {
                                            $sMdp = Get-GUITextBoxText -ID $iPWD
                                        }

                                        if (Get-GUICheckBoxState -ID $iMem) {
                                            $bSVGMdp = 1
                                        }
                                        break
                                    }
                                }
                            }

                            # Delete the GUI
                            Remove-GUIForm
                        }

             
                        # Check if the password is not empty
                        if ($sMdp -ne "") {

                            # Write to the log file that DWAgent is being installed
                            Write-Log -Message "Installation de DWAgent"

                            # If the password is to be saved, encrypt and write it to a file using a key derived from various system information
                            if ($bSVGMdp -eq 1) {
                                Encrypt-Data ($sMdp) ($sMailBD + [Environment]::MachineName + [Environment]::UserName + [Environment]::UserDomainName + [Environment]::UserInteractive + [Environment]::OSVersion + [Environment]::ProcessorCount + [Environment]::SystemPageSize + [Environment]::SystemDirectory + [Environment]::TickCount64) | Set-Content -Path ".\Cache\Pwd\dws.sha"
                            }

                            # Update the status bar with "Installation de DWAgent"
                            Set-GUIStatusBarText -Text " Installation de DWAgent"
                            Set-GUIStatusBarProgress -Value 20

                            # Run DWAgent with the email and password as arguments
                            Start-Process -FilePath $sProgrun -ArgumentList "-silent user=$sMailBD password=$sMdp name='$sNom'" -Wait

                            # Check for errors
                            if ($LASTEXITCODE -ne 0) {

                                # Show a warning message that DWAgent could not be installed
                                Show-WarningMessage "Impossible d'installer DWAgent"

                                # Clear the status bar and progress bar
                                Set-GUIStatusBarText -Text ""
                                Set-GUIStatusBarProgress -Value 0

                                # Change the state of the button to "Desactiver"
                                Change-ButtonState -ID $iIDAction -State "Desactiver"
                            }
                            else {

                                # Update the progress bar to 100%
                                Set-GUIStatusBarProgress -Value 100

                                # Wait for 2 seconds
                                Start-Sleep -Seconds 2

                                # Clear the status bar and progress bar
                                Set-GUIStatusBarText -Text ""
                                Set-GUIStatusBarProgress -Value 0

                                # Change the state of the button to "Activer"
                                Change-ButtonState -ID $iIDAction -State "Activer"

                                # Write to the cache file that RemoteDesktop is enabled
                                Set-Content -Path ".\Cache\BureauDistant" -Value "1"

                                # Disable the background image
                                Disable-BackgroundImage
                            }
                        }
                        else {

                            # Change the state of the button to "Desactiver"
                            Change-ButtonState -ID $iIDAction -State "Desactiver"
                        }

                        # Check if DWAgent was downloaded successfully
                        if (Download-DWAgent) {

                            # Do nothing (the code above handles the installation)
                        }
                        else {

                            # Show a warning message that DWAgent could not be downloaded
                            Show-WarningMessage 'Echec du téléchargement de "DWAgent"'

                            # Change the state of the button to "Desactiver"
                            Change-ButtonState -ID $iIDAction -State "Desactiver"
                        }

                        # Check if a menu item exists for DWAgent
                        if ($aMenu.ContainsKey($sAgent)) {

                            # Do nothing (the code above handles the download and installation)
                        }
                        else {

                            # Show a warning message that DWAgent is not part of BAO software and RemoteDesktop cannot be activated
                            Show-WarningMessage "$sAgent ne fait pas parti des logiciels de BAO. Activation Bureau Distant impossible"

                            # Write to the log file that DWAgent was not found in the config.ini file
                            Write-Log -Message "$sAgent dans config.ini introuvable"

                            # Change the state of the button to "Desactiver"
                            Change-ButtonState -ID $iIDAction -State "Desactiver"
                        }

                        # Check if the technical mode is on
                        if ($ModeTech -eq 1) {

                            # Launch Chrome with the DWService login page as an argument
                            Start-Process -FilePath "chrome" -ArgumentList 'https://www.dwservice.net/fr/login.html'
                        }

                        # Update the edit control with the log file content
                        Update-GUIEditControl -ID $iIDEditLog -Log $hLog

                        # Check if the email address of the DWService account is specified in the config.ini file
                        if ($sMailBD -eq "") {

                            # Show a warning message that the email address must be specified in the config.ini file
                            Show-WarningMessage "L'adresse email de votre compte DWS doit être renseignée dans le fichier config.ini"

                            # Change the state of the button to "Desactiver"
                            Change-ButtonState -ID $iIDAction -State "Desactiver"
                        }

