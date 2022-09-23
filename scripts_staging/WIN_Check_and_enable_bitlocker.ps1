<#
.SYNOPSIS
    Checks and Enables Bitlocker
.DESCRIPTION
    Checks if TPM available and Enables bitlocker on system drive, and shows recovery key.	Stops if Windows Home Edition
    
.OUTPUTS
    Results are printed to the console.
.NOTES
 #>

$ProdHomePro = Get-ComputerInfo | select WindowsProductName
write-host $ProdHomePro
if ($ProdHomePro.WindowsProductName -like '*Home*') { exit 0 }
$TPM = Get-TPM
$BLinfo = Get-Bitlockervolume

if($blinfo.ProtectionStatus -eq 'Off' -and $blinfo.EncryptionPercentage -eq '0'){

if ($TPM.TPMPresent -eq 'True' -and $TPM.TPMReady -eq 'True')

        {
        $Volume = (Get-WmiObject -Class Win32_EncryptableVolume -Namespace "root\CIMv2\Security\MicrosoftVolumeEncryption" | Where-Object { $_.DriveLetter -eq $Env:SystemDrive })
                if ($Volume.DriveLetter -eq $env:SystemDrive)
                       { Enable-BitLocker -EncryptionMethod Aes128 -RecoveryPasswordProtector -MountPoint $env:SystemDrive -SkipHardwareTest
                       Enable-BitLockerAutoUnlock -MountPoint $env:SystemDrive
                }
        $bitlockerrecovery = (get-bitlockervolume -mountpoint $Env:SystemDrive).keyprotector | foreach {$_.recoverypassword} | where {$_ -ne ""}
        write-host "Bitlocker key is: $bitlockerrecovery"
        


        
        }
}
if($blinfo.ProtectionStatus -eq 'On'){
    $bitlockerrecovery = (get-bitlockervolume -mountpoint $Env:SystemDrive).keyprotector | foreach {$_.recoverypassword} | where {$_ -ne ""}
    write-host "Bitlocker key is: $bitlockerrecovery"

}
