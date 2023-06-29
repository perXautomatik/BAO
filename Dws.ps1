
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

# This script defines several functions for creating and controlling a remote desktop session using DWAgent.

# Define the Invoke-RemoteDesktop function
function Invoke-RemoteDesktop {

    # Get the parameters from the config.ini file
    $params = Get-ConfigParameters

    # Check if the email address of the DWService account is specified
    if ($params.sMailBD -ne "") {

        # Check if the technical mode is off and if the DWAgent program exists on the system
        if (($params.iModeTech -eq 0) -and (Test-Path -Path "$params.programFilesDir\$params.sAgent\runtime\dwagent.exe")) {

            # Check if a cache file exists for RemoteDesktop
            if (Test-Path -Path ".\Cache\BureauDistant") {

                # Uninstall DWAgent
                Uninstall-DWAgent -Params $params

                # Change the state of the button to "Desactiver"
                Change-ButtonState -ID $params.iIDAction -State "Desactiver"

                # Write to the cache file that RemoteDesktop is disabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "-1"
            }
            else {

                # Write to the log file that DWAgent is already installed and activate the button "Bureau Distant"
                Write-Log -Message "DWAgent déjà installé, activation du bouton 'Bureau Distant'" -Log $params.hLog

                # Write to the cache file that RemoteDesktop is enabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "1"

                # Change the state of the button to "Activer"
                Change-ButtonState -ID $params.iIDAction -State "Activer"

                # Disable the background image
                Disable-BackgroundImage
            }
        }
        else {

            # Check if the technical mode is off
            if ($params.iModeTech -eq 0) {

                # Write to the log file that RemoteDesktop is being activated
                Write-Log -Message "Activation du bureau distant" -Log $params.hLog

                # Change the state of the button to "Patienter"
                Change-ButtonState -ID $params.iIDAction -State "Patienter"

                # Check if a menu item exists for DWAgent
                if ($params.aMenu.ContainsKey($params.sAgent)) {

                    # Download and install DWAgent
                    Install-DWAgent -Params $params
                }
                else {

                    # Show a warning message that DWAgent is not part of BAO software and RemoteDesktop cannot be activated
                    Show-WarningMessage "$params.sAgent ne fait pas parti des logiciels de BAO. Activation Bureau Distant impossible"

                    # Write to the log file that DWAgent was not found in the config.ini file
                    Write-Log -Message "$params.sAgent dans config.ini introuvable" -Log $params.hLog

                    # Change the state of the button to "Desactiver"
                    Change-ButtonState -ID $params.iIDAction -State "Desactiver"
                }
            }
            else {

                # Launch Chrome with the DWService login page as an argument
                Start-Process -FilePath "chrome" -ArgumentList 'https://www.dwservice.net/fr/login.html'
            }
        }

        # Update the edit control with the log file content
        Update-GUIEditControl -ID $params.iIDEditLog -Log $params.hLog
    }
    else {

        # Show a warning message that the email address must be specified in the config.ini file
        Show-WarningMessage "L'adresse email de votre compte DWS doit être renseignée dans le fichier config.ini"

        # Change the state of the button to "Desactiver"
        Change-ButtonState -ID $params.iIDAction -State "Desactiver"
    }
}

# Define the Get-ConfigParameters function
function Get-ConfigParameters {

    # Declare an object to store the parameters
    $params = New-Object PSObject

    # Get the Program Files directory from the registry
    $programFilesDir = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir").ProgramFilesDir

    # Add it to the object as a property
    $params | Add-Member NoteProperty programFilesDir $programFilesDir

    # Read some variables from the config.ini file and add them to the object as properties
    $params | Add-Member NoteProperty sMailBD ((Get-Content -Path ".\config.ini" | Select-String -Pattern "MailBD=").Line.Split("=")[1])
    $params | Add-Member NoteProperty sAgent ((Get-Content -Path ".\config.ini" | Select-String -Pattern "Agent=").Line.Split("=")[1])
    $params | Add-Member NoteProperty sNom ((Get-Content -Path ".\config.ini" | Select-String -Pattern "Nom=").Line.Split("=")[1])
    $params | Add-Member NoteProperty iModeTech ((Get-Content -Path ".\config.ini" | Select-String -Pattern "ModeTech=").Line.Split("=")[1])

    # Read the menu items from the config.ini file and add them to the object as a property
    $aMenu = @{}
    foreach ($line in (Get-Content -Path ".\config.ini" | Select-String -Pattern "Menu=")) {
        $key = $line.Line.Split("=")[1]
        $value = $line.Line.Split("=")[2]
        $aMenu.Add($key, $value)
    }
    $params | Add-Member NoteProperty aMenu $aMenu

    # Return the object with the parameters
    return $params
}

# This script defines a function (_BureauDistant) for creating and controlling a remote desktop session using DWAgent.

# Define the _BureauDistant function
function _BureauDistant {

    # Get the parameters from the config.ini file
    $params = Get-ConfigParameters

    # Check if the email address of the DWService account is specified
    if ($params.sMailBD -ne "") {

        # Check if the technical mode is off and if the DWAgent program exists on the system
        if (($params.iModeTech -eq 0) -and (Test-Path -Path "$params.programFilesDir\$params.sAgent\runtime\dwagent.exe")) {

            # Check if a cache file exists for RemoteDesktop
            if (Test-Path -Path ".\Cache\BureauDistant") {

                # Uninstall DWAgent
                Uninstall-DWAgent -Params $params

                # Change the state of the button to "Desactiver"
                Change-ButtonState -ID $params.iIDAction -State "Desactiver"

                # Write to the cache file that RemoteDesktop is disabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "-1"
            }
            else {

                # Write to the log file that DWAgent is already installed and activate the button "Bureau Distant"
                Write-Log -Message "DWAgent déjà installé, activation du bouton 'Bureau Distant'" -Log $params.hLog

                # Write to the cache file that RemoteDesktop is enabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "1"

                # Change the state of the button to "Activer"
                Change-ButtonState -ID $params.iIDAction -State "Activer"

                # Disable the background image
                Disable-BackgroundImage
            }
        }
        else {

            # Check if the technical mode is off
            if ($params.iModeTech -eq 0) {

                # Write to the log file that RemoteDesktop is being activated
                Write-Log -Message "Activation du bureau distant" -Log $params.hLog

                # Change the state of the button to "Patienter"
                Change-ButtonState -ID $params.iIDAction -State "Patienter"

                # Check if a menu item exists for DWAgent
                if ($params.aMenu.ContainsKey($params.sAgent)) {

                    # Download and install DWAgent
                    Install-DWAgent -Params $params
                }
                else {

                    # Show a warning message that DWAgent is not part of BAO software and RemoteDesktop cannot be activated
                    Show-WarningMessage "$params.sAgent ne fait pas parti des logiciels de BAO. Activation Bureau Distant impossible"

                    # Write to the log file that DWAgent was not found in the config.ini file
                    Write-Log -Message "$params.sAgent dans config.ini introuvable" -Log $params.hLog

                    # Change the state of the button to "Desactiver"
                    Change-ButtonState -ID $params.iIDAction -State "Desactiver"
                }
            }
            else {

                # Launch Chrome with the DWService login page as an argument
                Start-Process -FilePath "chrome" -ArgumentList 'https://www.dwservice.net/fr/login.html'
            }
        }

        # Update the edit control with the log file content
        Update-GUIEditControl -ID $params.iIDEditLog -Log $params.hLog
    }
    else {

        # Show a warning message that the email address must be specified in the config.ini file
        Show-WarningMessage "L'adresse email de votre compte DWS doit être renseignée dans le fichier config.ini"

        # Change the state of the button to "Desactiver"
        Change-ButtonState -ID $params.iIDAction -State "Desactiver"
    }
}


# Define the Install-DWAgent function
function Install-DWAgent {

    # Get the parameters from the argument
    param (
        [Parameter(Mandatory=$true)]
        [PSObject]$Params
    )

    # Download DWAgent
    if (Download-DWAgent -Params $Params) {

        # Get the password and whether to save it or not from the user or the cache file
        $sMdp, $bSVGMdp = Get-Password -Params $Params

        # Check if the password is not empty
        if ($sMdp -ne "") {

            # Write to the log file that DWAgent is being installed
            Write-Log -Message "Installation de DWAgent" -Log $Params.hLog

            # If the password is to be saved, encrypt and write it to a file using a key derived from various system information
            if ($bSVGMdp -eq 1) {
                Encrypt-Data ($sMdp) ($Params.sMailBD + [Environment]::MachineName + [Environment]::UserName + [Environment]::UserDomainName + [Environment]::UserInteractive + [Environment]::OSVersion + [Environment]::ProcessorCount + [Environment]::SystemPageSize + [Environment]::SystemDirectory + [Environment]::TickCount64) | Set-Content -Path ".\Cache\Pwd\dws.sha"
            }

            # Update the status bar with "Installation de DWAgent"
            Set-GUIStatusBarText -Text " Installation de DWAgent"
            Set-GUIStatusBarProgress -Value 20

            # Run DWAgent with the email and password as arguments
            Start-Process -FilePath $Params.sProgrun -ArgumentList "-silent user=$Params.sMailBD password=$sMdp name='$Params.sNom'" -Wait

            # Check for errors
            if ($LASTEXITCODE -ne 0) {

                # Show a warning message that DWAgent could not be installed
                Show-WarningMessage "Impossible d'installer DWAgent"

                # Clear the status bar and progress bar
                Set-GUIStatusBarText -Text ""
                Set-GUIStatusBarProgress -Value 0

                # Change the state of the button to "Desactiver"
                Change-ButtonState -ID $Params.iIDAction -State "Desactiver"
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
                Change-ButtonState -ID $Params.iIDAction -State "Activer"

                # Write to the cache file that RemoteDesktop is enabled
                Set-Content -Path ".\Cache\BureauDistant" -Value "1"

                # Disable the background image
                Disable-BackgroundImage
            }
        }
        else {

            # Change the state of the button to "Desactiver"
            Change-ButtonState -ID $Params.iIDAction -State "Desactiver"
        }
    }
    else {

        # Show a warning message that DWAgent could not be downloaded
        Show-WarningMessage 'Echec du téléchargement de "DWAgent"'

        # Change the state of the button to "Desactiver"
        Change-ButtonState -ID $Params.iIDAction -State "Desactiver"
    }
}