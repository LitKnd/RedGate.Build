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

        # Pull Request Number
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Number,

        # A hashtable representing the properties to be set on the PR
        # This must match the format expected by the GitHub REST API
        # eg @{ assignees = ['YoMomma'], labels = ["so-fat"] }
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Hashtable] $Payload
    )
    Process
    {
        $PayloadJson = $Payload | ConvertTo-Json

        Use-Tls {
            $result = Invoke-RestMethod `
                    -Uri "https://api.github.com/repos/red-gate/$Repo/issues/$Number" `
                    -Headers @{Authorization="token $Token"} `
                    -Method Patch `
                    -Body $PayloadJson
        }

        return $result
    }
}


