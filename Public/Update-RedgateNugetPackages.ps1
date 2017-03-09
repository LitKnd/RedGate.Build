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
        # Set this parameter to an empty list to unassign the pull request.
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Assignees = $null,


        # A list of labels to assign to the pull request.
        # Set this parameter to an empty list to remove all labels
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]] $Labels = $null,

        # (Optional) A list of nuspec files for which we will update
        # the //metadata/dependencies version ranges.
        # Wildcards are supported
        [string[]] $NuspecFiles
    )
    begin {
        Push-Location $RootDir
        # Let's display all verbose messages for the time being
        $local:VerbosePreference = 'Continue'
    }
    Process
    {
        $packageConfigFiles = GetNugetPackageConfigs -RootDir $RootDir

        $RedgatePackageIDs = GetNugetPackageIds `
            -PackageConfigs $packageConfigFiles `
            -IncludedPackages $IncludedPackages `
            -ExcludedPackages $ExcludedPackages

        UpdateNugetPackages -PackageIds $RedgatePackageIDs -Solution $Solution

        Resolve-Path $NuspecFiles | Update-NuspecDependenciesVersions -PackagesConfigPaths $packageConfigFiles -verbose

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
                -Labels $Labels `
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
    end {
        Pop-Location
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

Function GetNugetPackageConfigs([Parameter(Mandatory, Position=0)]$RootDir)
{
    Get-ChildItem $RootDir -Recurse -Filter 'packages.config' `
        | Where-Object{ $_.fullname -notmatch "\\(.build)|(packages)\\" }
}

function GetNugetPackageIds(
    [Parameter(Mandatory = $true)][System.IO.FileInfo[]] $PackageConfigs,
    [string[]] $IncludedPackages = @('Redgate.*'),
    [string[]] $ExcludedPackages)
{
    $AllPackages = $PackageConfigs | ForEach-Object {
        ([Xml]($_ | Get-Content)).packages.package.id
    } | Select-Object -Unique

    $FilteredPackageIDs = @()
    foreach($pattern in $IncludedPackages) {
        $FilteredPackageIDs += $AllPackages | Where-Object { $_ -like $pattern}
    }

    if($ExcludedPackages) {
        # Remove execluded packages if any
        $FilteredPackageIDs = $FilteredPackageIDs | Where-Object { $ExcludedPackages -notcontains $_ }
    }

    return $FilteredPackageIDs | Select-Object -Unique | Sort-Object
}
