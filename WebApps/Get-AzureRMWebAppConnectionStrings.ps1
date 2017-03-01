<#
    .DESCRIPTION
        Iterates over all Azure Web Sites you have access to and reports all connection strings
        All strings found are saved to temp and opened with the default associated program for csv files.

    .LINK
        Requires Azure PowerShell from https://azure.microsoft.com/en-us/downloads/
#>

Import-Module AzureRM.Websites

#Log in with your Azure account
Add-AzureRmAccount

$azuWebApps = Get-AzureRmWebApp

#We'll just pop these up on notepad at the end
$connStrResults = @()

foreach($azuWebApp in $azuWebApps)
{
    #For some reason the global Get command doesn't retrieve these settings. You need to specify the specific Web App name
    $azuWebApp.SiteName | Out-Host
    $azuWebApp = Get-AzureRmWebApp -Name $azuWebApp.Name -ResourceGroupName $azuWebApp.ResourceGroup
 
    foreach($connStr in $azuWebApp.SiteConfig.ConnectionStrings)
    {
        $connStrResults += ([PSCustomObject]@{
            'ResourceGroup' = $azuWebApp.ResourceGroup
            'Site' = $azuWebApp.SiteName
            'DefaultHostName' = $azuWebApp.DefaultHostName
            'ConnStrType' = $connStr.Type
            'ConnStrName' = $connStr.Name
            'ConnStrValue' = $connStr.ConnectionString
        })
    }    
}

if($connStrResults.Count -eq 0)
{
    "There were no connection strings found" | Write-Host -ForegroundColor Green
}
else
{
    $connStrResultsOutFile = [System.IO.Path]::GetTempFileName().Replace('.tmp','.csv')
    "Writing Connection Strings to file '{0}'" -f $connStrResultsOutFile | Write-Host -ForegroundColor Green
    $connStrResults | Export-Csv -NoTypeInformation -Path $connStrResultsOutFile
    Invoke-Item $connStrResultsOutFile
}