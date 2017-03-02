<#
    .DESCRIPTION
        Iterates over all Azure Web Sites you have access to and reports all connection strings
        All strings found are saved to temp and opened with the default associated program for csv files.

    .LINK
        Requires Azure PowerShell from https://azure.microsoft.com/en-us/downloads/
#>

Import-Module AzureRM.Websites

<#
    .DESCRIPTION
        Gets connection string information from an Azure Web App or Web App Slot
#>
Function Get-AzureRMWebAppConnectionString
{
    Param(
        $WebApp
    )

    $results = @()

    foreach($connStr in $WebApp.SiteConfig.ConnectionStrings)
    {
        $results += ([PSCustomObject]@{
            'ResourceGroup' = $WebApp.ResourceGroup
            'Site' = $WebApp.SiteName            
            'ConnStrType' = $connStr.Type
            'ConnStrName' = $connStr.Name
            'ConnStrValue' = $connStr.ConnectionString
            'State' = $WebApp.State
            'Type' = $WebApp.Type
            'DefaultHostName' = $WebApp.DefaultHostName
            'EnabledHostNames' = ($WebApp.EnabledHostNames -join ';')
        })
    }

    return $results
}

#Log in with your Azure account
Add-AzureRmAccount

$azuWebApps = Get-AzureRmWebApp

#We'll just pop these up on notepad at the end
$connStrResults = @()

foreach($azuWebApp in $azuWebApps)
{
    #For some reason the global Get command doesn't retrieve these settings. You need to specify the specific Web App name
    $azuWebApp.SiteName | Out-Host
    $azuWebApp = Get-AzureRmWebApp -Name $azuWebApp.Name -ResourceGroupName $azuWebApp.ResourceGroup -ErrorAction:Continue 
    $connStrResults += Get-AzureRMWebAppConnectionString -WebApp $azuWebApp    
    $azuWebAppSlots = Get-AzureRmWebAppSlot -WebApp $azuWebApp -ErrorAction:Continue

    #Let's also get each slotted site settings
    foreach($azuWebAppSlot in $azuWebAppSlots)
    {
        try
        {
            #All Web Apps have a default staging slot exposed through this API. It doesn't always exist.
            $azuWebAppSlot = Get-AzureRmWebAppSlot -Name $azuWebAppSlot.Name -ResourceGroupName $azuWebAppSlot.ResourceGroup -ErrorAction:SilentlyContinue
            
            if($?)
            {
                $connStrResults += Get-AzureRMWebAppConnectionString -WebApp $azuWebAppSlot
            }
        }
        catch
        {
            $_.Exception.Message | Write-Error
        }
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