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

        # A list of packages that will be upgraded.
        # Wildcards can be used.
        # Defaults to Redgate.*
        [string[]] $IncludedPackages = @('Redgate.*'),

        # A list of packages we do NOT want to update.
        # Shame on you if you're using this! (but yeah it can be handy :blush:)
        [string[]] $ExcludedPackages,

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
        $RedgatePackageIDs = Get-NugetPackageIDs `
            -RootDir $RootDir `
            -IncludedPackages $IncludedPackages `
            -ExcludedPackages $ExcludedPackages

        UpdateNugetPackages -PackageIds $RedgatePackageIDs -Solution $Solution

        Set-Location $RootDir
        "Location: $(Get-Location)"

        $UpdateBranchName = 'pkg-auto-update'

        $CommitMessage = @"
Updated $($RedgatePackageIDs.Count) Redgate packages:
$($RedgatePackageIDs -join "`n")
"@

        if(Push-GitChangesToBranch -BranchName $UpdateBranchName -CommitMessage $CommitMessage) {
            $PR = New-PullRequestWithAssignees `
                -Token $GithubAPIToken `
                -Repo $Repo `
                -Head $UpdateBranchName `
                -Assignees $Assignees `
                -Title "Redgate Nuget Package Auto-Update" `
                -Body @"
The following packages were updated (or are already up to date):
`````````
$($RedgatePackageIDs -join "`n")
`````````
This PR was generated automatically.
"@

            "Pull request is available at: $($PR.html_url)"
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
