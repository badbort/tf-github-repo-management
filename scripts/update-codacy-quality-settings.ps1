    # These values match the type QualitySettings in the Codacy v3 API and is used for both pull-request and commit quality settings.
    # See: https://api.codacy.com/api/api-docs#tocsqualitygate
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
        $RepositoryOwner,

        [Parameter()]
        [AllowNull()]
        [Nullable[System.Int32]]
        $issueThresholdThreshold = $null,

        [Parameter()]
        [string]
        $issueThresholdMinimumSeverity = $null,

        [Parameter()]
        [AllowNull()]
        [Nullable[System.Int32]]
        $securityIssueThreshold = $null,

        [Parameter()]
        [AllowNull()]
        [Nullable[System.Int32]]
        $duplicationThreshold = $null,

        [Parameter()]
        [AllowNull()]
        [Nullable[System.Double]]
        $coverageThresholdWithDecimals = $null,

        [Parameter()]
        [AllowNull()]
        [Nullable[System.Double]]
        $diffCoverageThreshold = $null,

        [Parameter()]
        [AllowNull()]
        [Nullable[System.Double]]
        $complexityThreshold = $null,

        [Parameter(Mandatory=$true)]
        [ValidateSet('pull-requests','commits',ErrorMessage = "{0} is not one of the allowed quality gates: {1}")]
        [String]$QualityType
    )

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("api-token", "$CODACY_API_TOKEN")
    $headers.Add("Content-Type", "application/json")

    $body = @{}

    # If a value is not defined then Codacy disables that check. Thus all following assignments 
    # are not added to the body if null
    if($issueThresholdThreshold -ne $null) {
        $body.issueThreshold ??= @{}
        $body.issueThreshold.threshold = $issueThresholdThreshold;
        Write-Output "Setting issueThresholdThreshold: $issueThresholdThreshold"
    }

    if($issueThresholdMinimumSeverity) {
        $body.issueThreshold ??= @{}
        $body.issueThreshold.minimumSeverity = $issueThresholdMinimumSeverity;
        Write-Output "Setting issueThresholdMinimumSeverity: $issueThresholdMinimumSeverity"
    }

    if($securityIssueThreshold -ne $null) {
        $body.securityIssueThreshold ??= $securityIssueThreshold;
        Write-Output "Setting securityIssueThreshold: $securityIssueThreshold"
    }

    if($duplicationThreshold -ne $null) {
        $body.duplicationThreshold ??= $duplicationThreshold;
        Write-Output "Setting duplicationThreshold: $duplicationThreshold"
    }

    if($coverageThresholdWithDecimals -ne $null) {
        $body.coverageThresholdWithDecimals ??= $coverageThresholdWithDecimals;
        Write-Output "Setting coverageThresholdWithDecimals: $coverageThresholdWithDecimals"
    }

    if($diffCoverageThreshold -ne $null) {
        $body.diffCoverageThreshold ??= $diffCoverageThreshold;
        Write-Output "Setting diffCoverageThreshold: $diffCoverageThreshold"
    }

    if($complexityThreshold -ne $null) {
        $body.complexityThreshold ??= $complexityThreshold;
        Write-Output "Setting complexityThreshold: $complexityThreshold"
    }

    $restParams = @{
        Method             = 'PUT'
        Uri                = "https://app.codacy.com/api/v3/organizations/gh/$RepositoryOwner/repositories/$RepositoryName/settings/quality/$QualityType"
        Headers            = $headers
        StatusCodeVariable = 'responseStatusCode'
        Body = $body | ConvertTo-Json
    }

    $response = Invoke-RestMethod @restParams

    # Checks last exist code of last command and throws
    if (!$?) {
        throw $_.ErrorDetails.Message
    }

    Write-Output "Response: $responseStatusCode"
    $response | ConvertTo-Json -Depth 10 | Write-Output
