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

        # A list of user logins to assign to the pull request.
        # Set this parameter to an empty list to unassign the pull request.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Assignees = $null,
        
        # A list of labels to assign to the pull request.
        # Set this parameter to an empty list to remove all labels
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Labels = $null
    )
    Process
    {
        if($Labels -eq $null -and $Assignees -eq $null){
            return
        }

        $AssigneesJson = JsonifyList -List $Assignees;
        $LabelsJson = JsonifyList -List $Labels;

        return Invoke-RestMethod `
                -Uri "https://api.github.com/repos/red-gate/$Repo/issues/$Number" `
                -Headers @{Authorization="token $Token"} `
                -Method Patch `
                -Body @"
{
    "assignees": $AssigneesJson,
    "labels": $LabelsJson
}
"@
    }
}

function JsonifyList($List){
    if($List -eq $null){
        return "null";
    }

    $json =switch($List.count) {
        0 { '[]' }
        1 { "[`"$List`"]"}
        default { $List | ConvertTo-Json }
    }

    return $json;
}
