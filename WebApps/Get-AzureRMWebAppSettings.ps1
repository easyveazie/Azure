<#
    .DESCRIPTION
        Iterates over all Azure Web Sites you have access to and reports appSettings. 
        All settings found are saved to temp and opened with the default associated program for csv files.

    .LINK
        Requires Azure PowerShell from https://azure.microsoft.com/en-us/downloads/
#>


<#
    .DESCRIPTION
        Gets appSetting information from an Azure Web App or Web App Slot
#>
Function Get-AzureRMWebAppSettings
{
    Param(
        $WebApp
    )

    $results = @()

    foreach($appSett in $WebApp.SiteConfig.AppSettings)
    {
        $results += ([PSCustomObject]@{
            'ResourceGroup' = $WebApp.ResourceGroup
            'Site' = $WebApp.SiteName            
            'AppSettingName' = $appSett.Name
            'AppSettingValue' = $appSett.Value
            'State' = $WebApp.State
            'Type' = $WebApp.Type
            'DefaultHostName' = $WebApp.DefaultHostName
            'EnabledHostNames' = ($WebApp.EnabledHostNames -join ';')
        })
    }

    return $results
}

Import-Module AzureRM.Websites

#Log in with your Azure account
Add-AzureRmAccount

$azuWebApps = Get-AzureRmWebApp

#We'll just pop these up on notepad at the end
$appSettResults = @()

foreach($azuWebApp in $azuWebApps)
{
    #For some reason the global Get command doesn't retrieve these settings. You need to specify the specific Web App name
    $azuWebApp.SiteName | Out-Host
    $azuWebApp = Get-AzureRmWebApp -Name $azuWebApp.Name -ResourceGroupName $azuWebApp.ResourceGroup -ErrorAction:Continue 
    $appSettResults += Get-AzureRMWebAppSettings -WebApp $azuWebApp    
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
                $appSettResults += Get-AzureRMWebAppSettings -WebApp $azuWebAppSlot
            }
        }
        catch
        {
            $_.Exception.Message | Write-Error
        }
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