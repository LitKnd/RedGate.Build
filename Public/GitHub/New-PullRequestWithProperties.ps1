<#
.SYNOPSIS
    Create a new pull request / update an existing pull request with a list of assigness or labels

.DESCRIPTION
    If a pull request is not opened yet, create a new one and assign it to a list of github users
    If a pull request already exists, assign it to a list of github users

.OUTPUTS
    A Pull Request object as per https://developer.github.com/v3/pulls/#get-a-single-pull-request
#>
Function New-PullRequestWithProperties
{
    [CmdletBinding()]
    [OutputType([Nullable])]
    Param
    (
        # The GitHub API token used to interact with the GitHub API.
        [Parameter(Mandatory)]
        [string] $Token,

        # The name of the repo the pull request will belong to.
        [Parameter(Mandatory)]
        [string] $Repo,

        # Title of the pull request.
        [Parameter(Mandatory)]
        [string] $Title,

        # Body of the pull request.
        [Parameter(Mandatory)]
        [string] $Body,

        # The name of the branch to pull in the $Base branch
        [Parameter(Mandatory)]
        [string] $Head,

        # A list of user logins to assign to the pull request.
        # Set this parameter to an empty list to unassign the pull request.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Assignees = $null,
        
        
        # A list of labels to assign to the pull request.
        # Set this parameter to an empty list to remove all labels
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Labels = $null,

        # The name of the branch to pull $Head into.
        # Defaults to master
        [string] $Base = 'master'
    )

    $PullRequest = Get-PullRequest -Token $Token -Repo $Repo -Head $Head

    if(!$PullRequest) {
        Write-Verbose "No open PR found - Creating a new one..."

        $PullRequest = New-PullRequest `
            -Token $Token `
            -Repo $Repo `
            -Head $Head `
            -Base $Base `
            -Title $Title `
            -Body $Body

        Write-Verbose "PR Created $($PullRequest.html_url)"
    } else {
        Write-Verbose "PR already exists: $($PullRequest.html_url)"
    }


    $Payload = CreatePRUpdatePayload -Assignees $Assignees -Labels $Labels
    if($Payload -ne $null){
        Write-Verbose "Assigning PR $($PullRequest.id) to $Assignees with Labels $Labels"
        
        $PullRequest = Update-PullRequest `
            -Token $Token `
            -Repo $Repo `
            -Number $PullRequest.number `
            -Payload $Payload

        Write-Verbose "PR $($PullRequest.id) assigned to $Assignees with Labels $Labels"
    }

    #return the PR object for consumers to use.
    $PullRequest
}

function CreatePRUpdatePayload($Assignees, $Labels){
    if($Labels -eq $null -and $Assignees -eq $null){
        return $null;
    }

    $Payload = @{};

    if($Assignees -ne $null){
        $Payload.assignees = $Assignees;
    }

    if($Labels -ne $null){
        $Payload.labels = $Labels;
    }

    return $Payload;
}