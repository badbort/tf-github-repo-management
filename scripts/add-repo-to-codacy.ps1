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

try 
{
    $addRepoParams = @{
        Method             = 'POST'
        Uri                = 'https://app.codacy.com/api/v3/repositories'
        Headers            = $headers
        StatusCodeVariable = 'addRepoStatusCode'
        Body               = @{
            repositoryFullPath = "$RepositoryOwner/$RepositoryName"
            provider = "gh"
        } | ConvertTo-Json
    }

    Write-Host "Adding repo "$RepositoryOwner/$RepositoryName" to Codacy"

    try 
    {
        $addRepoResponse = Invoke-RestMethod @addRepoParams
    }
    catch 
    {
        $addRepoStatusCode = $_.Exception.Response.StatusCode

        # Checks if exception was thrown in last command
        # Does not throw when 409 conflict status code is returned as that occurs if the
        # repo was already been added to Codacy.
        if($addRepoStatusCode -eq [System.Net.HttpStatusCode]::Conflict) 
        {
            Write-Output "Repository may have been added already."
        } 
        else 
        {
            throw $_.ErrorDetails.Message
        }
    }
}
finally 
{
    Write-Output "Add repository returned status code $addRepoStatusCode. Response: $addRepoResponse"
    $addRepoResponse | ConvertTo-Json -Depth 10 | Write-Output
}