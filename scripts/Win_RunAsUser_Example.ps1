<#
.SYNOPSIS
    This is a template example script for doing stuff in userland

.DESCRIPTION
    Fully functional example for RunAsUser run from SYSTEM, including getting return data and exit 1 from Userland

.NOTES
    Change Log
    V1.0 6/25/2022 Initial release by silversword411
#>

# Make sure RunAsUser is installed
if (Get-Module -ListAvailable -Name RunAsUser) {
    # Write-Output "RunAsUser Already Installed"
} 
else {
    Write-Output "Installing RunAsUser"
    Install-Module -Name RunAsUser -Force
}

# Make sure Tactical RMM temp script folder exists
If (!(Test-Path "c:\ProgramData\TacticalRMM\temp\")) {
    Write-Output "Creating c:\ProgramData\TacticalRMM\temp Folder"
    New-Item "c:\ProgramData\TacticalRMM\temp" -ItemType Directory
}

Write-Output "Hello from Systemland"

Invoke-AsCurrentUser -ScriptBlock {
    # Put all Userland code here
    $raulogPath = "c:\ProgramData\TacticalRMM\temp\raulog.txt"
    $exit1Path = "c:\ProgramData\TacticalRMM\temp\exit1.txt"

    Write-Output "Hello from Userland" | Out-File -append -FilePath $raulogPath 
    If (test-path "c:\temp\") {
        Write-Output "Test for c:\temp\ folder passed which is Exit 0" | Out-File -append -FilePath $raulogPath 
    }
    else {
        Write-Output "Test for c:\temp\ folder failed which is Exit 1" | Out-File -append -FilePath $raulogPath 
        # Writing exit1.txt for Userland Exit 1 passing to Systemland for returning to Tactical
        Write-Output "Exit 1" | Out-File -append -FilePath $exit1Path
    }
}

# Get userland return info for Tactical Script History
$exitdata = Get-Content -Path "c:\ProgramData\TacticalRMM\temp\raulog.txt" -ErrorAction SilentlyContinue
Write-Output $exitdata
# Cleanup raulog.txt File
Remove-Item -Path "c:\ProgramData\TacticalRMM\temp\raulog.txt" -ErrorAction SilentlyContinue

# Checking for Userland Exit 1
If (Test-Path -Path "c:\ProgramData\TacticalRMM\temp\exit1.txt" -PathType Leaf) {
    Write-Output 'Return Exit 1 to Tactical from Userland'
    Remove-Item -Path "c:\ProgramData\TacticalRMM\temp\exit1.txt" -ErrorAction SilentlyContinue
    Exit 1
}
