<#
.SYNOPSIS
    Update an existing GitHub pull request

.DESCRIPTION
    Can change assigned users.

.EXAMPLE
    Update-PullRequest -Repo RedGate.Build -Id 27 -Assignees user1, user2
    Assign user1 and user2 to pull request 27 of repo 'red-gate/RedGate.Build'
#>
Function Update-PullRequest
{
    [CmdletBinding()]
    [OutputType([Nullable])]
    Param
    (
        # Name of the organization the repo belong to
        $Organization = 'red-gate',

        # Name of the repo the pull request belong to
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Repo,

        # Personal Access token used to query the github api
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Token,

        # Pull Request ID
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Id,

        # A list of user logins to assign to the pull request.
        # Pass $null to unassign the pull request.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]] $Assignees
    )
    Process
    {
        $AssigneesJson = if($Assignees.length -eq 0) { '[]' } else { $Assignees | ConvertTo-Json }

        return Invoke-RestMethod `
                -Uri "https://api.github.com/repos/red-gate/$Repo/issues/$Id" `
                -Headers @{Authorization="token $Token"} `
                -Method Patch `
                -Body @"
{
    "assignees": $AssigneesJson
}
"@
    }
}
