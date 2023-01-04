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

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("api-token", "$CODACY_API_TOKEN")
$headers.Add("Content-Type", "application/json")

try {
    $restParams = @{
        Method             = 'DELETE'
        Uri                = "https://app.codacy.com/api/v3/organizations/gh/$RepositoryOwner/repositories/$RepositoryName"
        Headers            = $headers
        StatusCodeVariable = 'responseStatusCode'
    }

    $response = Invoke-RestMethod @restParams -SkipHttpErrorCheck
} catch [System.Net.WebException] {
    Write-Output "An exception was caught: $($_.Exception.Message). Ignoring"
}

Write-Output Response: $responseStatusCode
$response | ConvertTo-Json -Depth 10 | Write-Output