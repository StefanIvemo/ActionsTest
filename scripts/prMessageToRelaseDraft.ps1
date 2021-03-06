[CmdletBinding()]
param (
    [Parameter()]
    [string]$PRTitle,
    [string]$PRNumber,
    [string]$Token
)

#Get all releases
$getReleases = Invoke-RestMethod -Method Get -Authentication Bearer -Token $Token -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases"

#Check if a release draft exists
foreach ($release in $getReleases){
    if ($release.draft -and ($release.name -eq "WIP - Next Release")) {
        Write-Host "Found a draft with id $($release.id)"
        $draftID=$release.id
        $draftBody=$release.body
    }
}

#Add merged PR to release notes draft
if (-not [string]::IsNullOrWhiteSpace($draftBody)) {
    $draftBody += "$PRTitle (#$PRNumber)"
} else {
    $draftBody = "$PRTitle (#$PRNumber)"
}

#Create new draft
$Body = @{
    tag_name    = "WIP - Next Release"
    name        = "WIP - Next Release"
    body        = $draftBody
    draft       = true
}
$createReleaseDraft = Invoke-RestMethod -Method Post -Authentication Bearer -Token $Token -Body $Body -URI  "https://api.github.com/repos/StefanIvemo/BicepPowerShell/releases" 