<#
.SYNOPSIS
    Get MX Records from variable
.REQUIREMENTS
    - Internet Access 
.NOTES
    - This script is designed to run on a single computer.  Ideally, it should be run on the Tactical RMM server or other trusted device.
    - This script loops through each agent uninstalling the agent and deleting each from the backend.
.PARAMETERS
    - $DomainQuery   - The domain to be searched

.VERSION
	- v1.0 
#>
param(
    [string] $DomainQuery,
)

if ([string]::IsNullOrEmpty($DomainQuery)) {
    throw "DomainQuery must be defined. Use -DomainQuery <value> to pass it."
}

function Get-DnsAddressList
{
    param(
        [parameter(Mandatory=$true)][Alias("Host")]
          [string]$HostName)

    try {
        return [System.Net.Dns]::GetHostEntry($HostName).AddressList
    }
    catch [System.Net.Sockets.SocketException] {
        if ($_.Exception.ErrorCode -ne 11001) {
            throw $_
        }
        return = @()
    }
}

function Get-DnsMXQuery
{
    param(
        [parameter(Mandatory=$true)]
          [string]$DomainName)

    if (-not $Script:global_dnsquery) {
        $Private:SourceCS = @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace PM.Dns {
  public class MXQuery {
    [DllImport("dnsapi", EntryPoint="DnsQuery_W", CharSet=CharSet.Unicode, SetLastError=true, ExactSpelling=true)]
    private static extern int DnsQuery(
        [MarshalAs(UnmanagedType.VBByRefStr)]
        ref string pszName, 
        ushort     wType, 
        uint       options, 
        IntPtr     aipServers, 
        ref IntPtr ppQueryResults, 
        IntPtr pReserved);

    [DllImport("dnsapi", CharSet=CharSet.Auto, SetLastError=true)]
    private static extern void DnsRecordListFree(IntPtr pRecordList, int FreeType);

    public static string[] Resolve(string domain)
    {
        if (Environment.OSVersion.Platform != PlatformID.Win32NT)
            throw new NotSupportedException();

        List<string> list = new List<string>();

        IntPtr ptr1 = IntPtr.Zero;
        IntPtr ptr2 = IntPtr.Zero;
        int num1 = DnsQuery(ref domain, 15, 0, IntPtr.Zero, ref ptr1, IntPtr.Zero);
        if (num1 != 0)
            throw new Win32Exception(num1);
        try {
            MXRecord recMx;
            for (ptr2 = ptr1; !ptr2.Equals(IntPtr.Zero); ptr2 = recMx.pNext) {
                recMx = (MXRecord)Marshal.PtrToStructure(ptr2, typeof(MXRecord));
                if (recMx.wType == 15)
                    list.Add(Marshal.PtrToStringAuto(recMx.pNameExchange));
            }
        }
        finally {
            DnsRecordListFree(ptr1, 0);
        }

        return list.ToArray();
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MXRecord
    {
        public IntPtr pNext;
        public string pName;
        public short  wType;
        public short  wDataLength;
        public int    flags;
        public int    dwTtl;
        public int    dwReserved;
        public IntPtr pNameExchange;
        public short  wPreference;
        public short  Pad;
    }
  }
}
'@

        Add-Type -TypeDefinition $Private:SourceCS -ErrorAction Stop
        $Script:global_dnsquery = $true
    }

    [PM.Dns.MXQuery]::Resolve($DomainName) | % {
        $rec = New-Object PSObject
        Add-Member -InputObject $rec -MemberType NoteProperty -Name "Host"        -Value $_
        Add-Member -InputObject $rec -MemberType NoteProperty -Name "AddressList" -Value $(Get-DnsAddressList $_)
        $rec
    }
}

Get-DnsMXQuery -DomainName "$DomainQuery"
