<#
.SYNOPSIS
    Updates all the packages in a solution whose ID starts with `Redgate.` and creates a PR

.DESCRIPTION
    Updates all the packages in a solution whose ID starts with `Redgate.` and creates a PR

#>
Function Update-RedgateNugetPackages
{
    [CmdletBinding()]
    [OutputType([Nullable])]
    Param
    (
        # Name of the repo the pull request belong to
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Repo,

        # github api access token with full repo permissions
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $GithubAPIToken,

        # The root directory of the solution
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $RootDir,

        # The solution file name
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Solution,

        # A list of user logins to assign to the pull request.
        # Omit this parameter to unassign the pull request.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string[]] $Assignees
    )
    begin {
        # Let's display all verbose messages for the time being
        $local:VerbosePreference = 'Continue'
    }
    Process
    {
        $RedgatePackageIDs = Get-NugetPackageIDs -RootDir $RootDir `
                                | Where-Object{ $_ -like "Redgate.*"} `

        UpdateNugetPackages -PackageIds $RedgatePackageIDs -Solution $Solution

        Set-Location $RootDir
        "Location: $(Get-Location)"

        $UpdateBranchName = 'pkg-auto-update'

        if(Push-GitChangesToBranch -BranchName $UpdateBranchName -CommitMessage "Updated $RedgatePackageIDs") {
            New-PullRequestWithAssignees `
                -Token $GithubAPIToken `
                -Repo $Repo `
                -Head $UpdateBranchName `
                -Base $Base `
                -Title "Redgate Nuget Package Auto-Update" `
                -Body "The following packages were updated: $RedgatePackageIDs.  This PR was generated automatically."
        }
    }
}

function UpdateNugetPackages($PackageIds, $Solution){
    $NugetPackageParams = $PackageIds `
                        | ForEach-Object {
                            "-id", $_
                        }
    execute-command {
        & $NugetExe update $Solution -Verbosity detailed -noninteractive $NugetPackageParams
    }
}
