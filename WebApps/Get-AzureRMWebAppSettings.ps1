<#
    .DESCRIPTION
        Iterates over all Azure Web Sites you have access to and reports appSettings. 
        All settings found are saved to temp and opened with the default associated program for csv files.

    .LINK
        Requires Azure PowerShell from https://azure.microsoft.com/en-us/downloads/
#>

Import-Module AzureRM.Websites

#Log in with your Azure account
Add-AzureRmAccount

$azuWebApps = Get-AzureRmWebApp

#We'll just pop these up on notepad at the end
$appSettResults = @()
$connStrResults = @()

foreach($azuWebApp in $azuWebApps)
{
    #For some reason the global Get command doesn't retrieve these settings. You need to specify the specific Web App name
    $azuWebApp.SiteName | Out-Host
    $azuWebApp = Get-AzureRmWebApp -Name $azuWebApp.Name -ResourceGroupName $azuWebApp.ResourceGroup

    foreach($appSett in $azuWebApp.SiteConfig.AppSettings)
    {
        $appSettResults += ([PSCustomObject]@{
            'ResourceGroup' = $azuWebApp.ResourceGroup
            'Site' = $azuWebApp.SiteName
            'DefaultHostName' = $azuWebApp.DefaultHostName
            'AppSettingName' = $appSett.Name
            'AppSettingValue' = $appSett.Value
        })
    }
}

if($appSettResults.Count -eq 0)
{
    "There were no app settings found" | Write-Host -ForegroundColor Green
}
else
{
    $appSettResultsOutFile = [System.IO.Path]::GetTempFileName().Replace('.tmp','.csv')
    "Writing Connection Strings to file '{0}'" -f $appSettResultsOutFile | Write-Host -ForegroundColor Green
    $appSettResults | Export-Csv -NoTypeInformation -Path $appSettResultsOutFile
    Invoke-Item $appSettResultsOutFile
}