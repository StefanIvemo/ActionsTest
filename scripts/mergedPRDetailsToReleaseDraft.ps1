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

#Get all releases including drafts
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
$FirstLine, $Rest = $CommitMessage -split '\n', 2 | Foreach-Object -MemberName Trim
$PR = $FirstLine -replace '.*(#\d+).*', '$1'
$releaseMessage = $Rest

#Get PR details from commit
$prNumber = ($PR -split "#")[1]
$getPullRequest = Invoke-RestMethod -Method Get -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/pulls/$prNumber"
$prLabel = $getPullRequest.labels.name
Write-Host "Found PR #$($getPullRequest.number) with label $prLabel by $($getPullRequest.user.login)"

#Commit details
$mergedCommit = @{
    prNumber      = $prNumber
    commitMessage = $releaseMessage
    commitAuthor  = $getPullRequest.user.login
    mergedDate    = $getPullRequest.merged_at
}
Write-Host "Building commit object"
Write-Host $mergedCommit

#Only process PRs with labels assigned
if ($prLabel -eq 'bugFix' -or $prLabel -eq 'newFeature' -or $prLabel -eq 'updatedDocs') {
    if (-not [string]::IsNullOrWhiteSpace($releaseBody)) {
        Write-Host "Found release body from draft"
        $releaseBody = $releaseBody | ConvertFrom-Json -AsHashtable -Depth 10
        Write-Host $releaseBody
        $releaseBody[$prLabel] += $mergedCommit
    }
    else {
        $releaseBody = @{
            newFeature  = @()
            bugFix      = @()
            updatedDocs = @()  
        }
        $releaseBody[$prLabel] += $mergedCommit   
    }
    Write-Host "Converting releasebody to json"
    $releaseBody = $releaseBody | ConvertTo-Json -Depth 10
    Write-Host "releaseBody:"
    Write-Host $releaseBody
    
    #Create new draft body
    $body = @{
        tag_name = "vNext"
        name     = "WIP - Next Release"
        body     = $releaseBody
        draft    = $true
    }
    $requestBody = ConvertTo-Json $body -Depth 10
    Write-Host $requestBody
    
    if (!$releaseId) {
        $createRelease = Invoke-RestMethod -Method Post -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases" -Verbose
    }
    else {
        $updateRelease = Invoke-RestMethod -Method Patch -Headers $Header -Body $requestBody -URI  "https://api.github.com/repos/StefanIvemo/ActionsTest/releases/$releaseId" -Verbose
    }
} 