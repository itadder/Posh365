Function Watch-ToLicense {
    <#
    .SYNOPSIS
    
    .EXAMPLE

    #>
    [CmdletBinding()]
    Param (
        [Parameter()]
        [System.IO.FileInfo] $GuidFolder,        
        [Parameter()]
        [string[]] $optionsToAdd
    )

    $RootPath = $env:USERPROFILE + "\ps\"
    $User = $env:USERNAME

    $targetAddressSuffix = Get-Content ($RootPath + "$($user).TargetAddressSuffix")

    $WatcherJob = Start-Job -Name WatchToLicense {
        $optionsToAdd = $args[0]
        $GuidFolder = $args[1]
        $targetAddressSuffix = $args[2]
        Set-Location $GuidFolder
        Connect-Cloud $targetAddressSuffix -AzureADver2
        Start-Sleep -Seconds 120
        while (Test-Path $GuidFolder) {
            Get-ChildItem -Path $GuidFolder -File -Verbose -ErrorAction SilentlyContinue | ForEach {
                if ($_ -and !($_.name -eq 'ALLDONE')) {
                    Get-Content $_.VersionInfo.filename | Set-CloudLicense -ExternalOptionsToAdd $optionsToAdd
                    Remove-Item $_.VersionInfo.filename -verbose
                }
                if ($_.name -eq "ALLDONE" -and (Get-ChildItem -Path $GuidFolder).count -eq 1) {
                    Remove-Item $_.VersionInfo.filename -verbose
                }
            }
        }
        Disconnect-AzureAD
    } -ArgumentList $optionsToAdd, $GuidFolder, $targetAddressSuffix | Out-Null 
}    
