<#
    .SYNOPSIS
        Gets SQL Database information for each database that is present on the target instance(s) of SQL Server.

    .DESCRIPTION
        The Get-DbaDatabase command gets SQL database information for each database that is present on the target instance(s) of
        SQL Server. If the name of the database is provided, the command will return only the specific database information.

    .PARAMETER InputObject
        The Object to Filter

    .PARAMETER Property
        Name of the Property of InputObject to compare

    .PARAMETER Value
        Object that Property is compared against

    .PARAMETER In
        Members of InputObject where the value of the Property is within the Value set are returned

    .PARAMETER NotIn
        Members of InputObject where the value of the Property is not within the Value set are returned

    .PARAMETER Eq
        Members of InputObject where the value of the Property is equivalent to the Value

    .PARAMETER Ne
        Members of InputObject where the value of the Property is not not equivalent to the Value

    .PARAMETER Collation
        Name of the collation to use for comparison


    .NOTES
        Tags: Database
        Author: Charles Hightower

        Website: https://dbatools.io
        Copyright: (c) 2021 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT
    .EXAMPLE
        PS C:\> $server = Connect-DbaInstance -SqlInstance localhost
        PS C:\> $lastCopyOnlyBackups = Get-DbaDbBackupHistory -SqlInstance $server -LastFull -IncludeCopyOnly | Where-Object IsCopyOnly
        PS C:\> $server.Databases | Compare-DbaCollationSensitiveObject -Property Name -In -Value $lastCopyOnlyBackups.Database -Collation $server.Collation

        Returns all databases on the local default SQL Server instance with copy only backups using the collation of the SqlInstance

    .EXAMPLE
        PS C:\> $server = Connect-DbaInstance -SqlInstance localhost
        PS C:\> $lastFullBackups = Get-DbaDbBackupHistory -SqlInstance $server -LastFull
        PS C:\> $server.Databases | Compare-DbaCollationSensitiveObject -Property Name -NotIn -Value $lastFullBackups.Database -Collation $server.Collation

        Returns only the databases on the local default SQL Server instance without a Full Backup, using the collation of the SqlInstance

#>
Function Compare-DbaCollationSensitiveObject {
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [psObject]$InputObject,
        [parameter(Mandatory)]
        [string]$Property,
        [parameter(Mandatory, ParameterSetName = 'In')]
        [switch]$In,
        [parameter(Mandatory, ParameterSetName = 'NotIn')]
        [switch]$NotIn,
        [parameter(Mandatory, ParameterSetName = 'Eq')]
        [switch]$Eq,
        [parameter(Mandatory, ParameterSetName = 'Ne')]
        [switch]$Ne,
        [parameter(Mandatory)]
        [object]$Value,
        [parameter(Mandatory)]
        [String]$Collation)
    begin {
        #If InputObject is passed in by name, change it to a pipeline, so we can use the process block
        if ($PSBoundParameters['InputObject']) {
            $newParamaters = $PSBoundParameters
            $newParamaters.Remove('InputObject')
            return $InputObject | Compare-DbaCollationSensitiveObject @newParamaters
        }
        $stringComparer = (New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server).getStringComparer($Collation)
    }
    process {
        $obj = $_
        switch ($PsCmdlet.ParameterSetName) {
            "In" {
                foreach ($ref in $obj."$Property") {
                    foreach ($dif in $Value) {
                        if ($stringComparer.Compare($ref, $dif) -eq 0) {
                            return $obj
                        }
                    }
                }
                break
            }
            "NotIn" {
                foreach ($ref in $obj."$Property") {
                    $matchFound = $false
                    foreach ($dif in $Value) {
                        if ($stringComparer.Compare($ref, $dif) -eq 0) {
                            $matchFound = $true
                        }
                    }
                    if (-not $matchFound) {
                        return $obj
                    }
                }
                break
            }
            "Eq" {
                foreach ($ref in $obj."$Property") {
                    if ($stringComparer.Compare($ref, $Value) -eq 0) {
                        return $obj
                    }
                }
                break
            }
            "Ne" {
                foreach ($ref in $obj."$Property") {
                    if ($stringComparer.Compare($ref, $Value) -ne 0) {
                        return $obj
                    }
                }
                break
            }
        }
    }
    end { }
}