<#
    .SYNOPSIS
    Ensures the branch exists. If it doesn't exist, a new branch is created using the HEAD commit

    .Description
    Behaviour:
    - Should fail if any commands failed
    - Should succeed if branch already exists, or branch was created
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $GITHUB_TOKEN,
    [Parameter(Mandatory = $true)]
    [string]
    $RepositoryName,
    [Parameter(Mandatory = $true)]
    [string]
    $RepositoryOwner,
    [Parameter(Mandatory = $true)]
    [string]
    $BranchName
)

# GitHub CLI api
# https://cli.github.com/manual/gh_api

# Get the latest commit on the existing default branch
$remoteRefs = git ls-remote https:///oauth2:$($GITHUB_TOKEN)@github.com/$RepositoryOwner/$RepositoryName

if(!$?)
{
    # Command failed
    Write-Error "Failure: $LASTEXITCODE"
    exit 1
}

Write-Output "$RepositoryOwner/$RepositoryName refs:"
$remoteRefs | Write-Output

$sha = $remoteRefs | awk '$2 == \"HEAD\" {print $1}'

# If our branch ref already exists we'll it to this variable and check for null
$branchExists = $remoteRefs | awk "`$2 == \`"refs/heads/$BranchName\`" {print}"

if($branchExists)
{
    Write-Output "Branch $BranchName already exists."
    Write-Output $branchExists
    exit 0
}

if(!$sha)
{
    Write-Error "Failed to locate latest commit SHA of default branch"
    exit 1
}

Write-Output "Creating branch '$BranchName' from latest commit $sha on HEAD"

# Login so we can use gh api commands
Write-Output $GITHUB_TOKEN | gh auth login --with-token 

# Create the ref
gh api `
    --method POST `
    -H "Accept: application/vnd.github+json" `
    /repos/$RepositoryOwner/$RepositoryName/git/refs `
    -f "ref=refs/heads/$BranchName" `
    -f sha=$sha

if(!$?)
{
    # Command failed
    Write-Error "Failed to create branch: $LASTEXITCODE"
    exit 1
}