[CmdletBinding()]
param (
    [Parameter()]
    [string]$CommitMessage,
    [string]$Token
)

$header = @{
    "authorization" = "token $Token"
    "Accept"        = "application/vnd.github.v3+json"
}

#Get all releases
$getReleases = Invoke-RestMethod -Method Get -Headers $header -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases"

#Check if a release draft exists
foreach ($release in $getReleases) {
    if ($release.draft -and ($release.tag_name -eq "vNext")) {
        Write-Host "Found draft with id $($release.id)"
        $releaseId = $release.id
        $releaseBody = $release.body
    }
}

$prNumber= $CommitMessage -split "\s+"[3]
$prMessage= $CommitMessage -split '`r`n'[2]

#Add merged PR details to release notes draft
if (-not [string]::IsNullOrWhiteSpace($releaseBody)) {
    $releaseBody += "`n- $prMessage (#$prNumber)"
}
else {
    $releaseBody = "- $prMessage (#$prNumber)"
}

#Create new draft body
$body = @{
    tag_name = "vNext"
    name     = "WIP - Next Release"
    body     = $releaseBody
    draft    = $true
}
$requestBody = ConvertTo-Json $body

if (!$releaseId) {
    $createRelease = Invoke-RestMethod -Method Post -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases" -Verbose
}
else {
    $updateRelease = Invoke-RestMethod -Method Patch -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases/$releaseId" -Verbose
}