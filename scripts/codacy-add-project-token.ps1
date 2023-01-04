# When adding a repo to codacy using the API we don't end up with a project token. This script checks if one is added, and adds one if none were found.

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $CODACY_API_TOKEN,
    [Parameter(Mandatory = $true)]
    [string]
    $RepositoryName,
    [Parameter(Mandatory = $true)]
    [string]
    $RepositoryOwner
)

# Common headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-token", $CODACY_API_TOKEN)
$headers.Add("Content-Type", "application/json")

$getTokenParams = @{
    Method             = 'GET'
    Uri                = "https://app.codacy.com/api/v3/organizations/gh/$RepositoryOwner/repositories/$RepositoryName/tokens"
    Headers            = $headers
    StatusCodeVariable = 'getTokensStatusCode'
}

$addRepoResponse = Invoke-RestMethod @getTokenParams

# Checks last exist code of last command and throws
if (!$?) {
    throw $_.ErrorDetails.Message
}
    
Write-Output "Get tokens response: $getTokensStatusCode"

if($addRepoResponse.data.Length -lt 1) {
    Write-Output "Repository $RepositoryName has no project api token added. Adding new one..."

    $addTokenParams = @{
        Method             = 'POST'
        Uri                = "https://app.codacy.com/api/v3/organizations/gh/$RepositoryOwner/repositories/$RepositoryName/tokens"
        Headers            = $headers
        StatusCodeVariable = 'addTokenStatusCode'
    }

    Invoke-RestMethod @addTokenParams
    Write-Output "Add project api token response code: $addTokenStatusCode"
    
    # Checks last exist code of last command and throws
    if (!$?) {
        throw $_.ErrorDetails.Message
    }

} else {
    Write-Output "Repository $RepositoryName already has a project api token. No actions performed"
}