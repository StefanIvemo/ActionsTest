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

#Parse commit message
$FirstLine,$Rest = $CommitMessage -split '\n',2 | Foreach-Object -MemberName Trim
$PR = $FirstLine -replace '.*(#\d+).*', '$1'
$releaseMessage ='{0} ({1})' -f $Rest, $PR
Write-Host $releaseMessage

#Add merged PR details to release notes draft
if (-not [string]::IsNullOrWhiteSpace($releaseBody)) {
    $releaseBody += "`n- $releaseMessage"
}
else {
    $releaseBody = "- $releaseMessage"
}
Write-Host $releaseBody

#Create new draft body
$body = @{
    tag_name = "vNext"
    name     = "WIP - Next Release"
    body     = $releaseBody
    draft    = $true
}
$requestBody = ConvertTo-Json $body
Write-Host $requestBody

if (!$releaseId) {
    $createRelease = Invoke-RestMethod -Method Post -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases" -Verbose
}
else {
    $updateRelease = Invoke-RestMethod -Method Patch -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases/$releaseId" -Verbose
}