[CmdletBinding()]
param (
    [Parameter()]
    [string]$PRTitle,
    [string]$PRNumber,
    [string]$Token
)

$Header = @{
    "authorization" = "token $Token"
    "Accept" = "application/vnd.github.v3+json"
}

#Get all releases
$getReleases = Invoke-RestMethod -Method Get -Headers $Header -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases"

#Check if a release draft exists
foreach ($release in $getReleases){
    if ($release.draft -and ($release.tag_name -eq "vNext")) {
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
    tag_name    = "vNext"
    name        = "WIP - Next Release"
    body        = $draftBody
    draft       = $true
}
$requestBody=ConvertTo-Json $Body
$createReleaseDraft = Invoke-RestMethod -Method Post -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases" -Verbose