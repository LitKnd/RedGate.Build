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
        [string] $Repo,

        # (Optional) The title of the PR created in GitHub
        [string] $PRTitle = "Redgate Nuget Package Auto-Update",

        # The name of the branch that will be pushed with any changes
        [string] $UpdateBranchName = 'pkg-auto-update',

        # (Optional) github api access token with full repo permissions
        # If passed in, changes will be committed, pushed to github and a
        #               pull request will be created/updated.
        # If not set, changes will not be committed. No pull request will be created
        [Parameter(ValueFromPipelineByPropertyName)]
        $GithubAPIToken,

        # The root directory of the solution
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $RootDir,

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
        $UpdatedPackages = UpdatePackageConfigs -RootDir $RootDir -Solution $Solution -IncludedPackages $IncludedPackages -ExcludedPackages $ExcludedPackages -NuspecFiles $NuspecFiles
        
        $UpdatedPackages += UpdatePackageReferences -RootDir $RootDir -IncludedPackages $IncludedPackages -ExcludedPackages $ExcludedPackages

        if(!$GithubAPIToken) {
            Write-Warning "-GithubAPIToken was not passed in, skip committing changes."
            return
        }

        $CommitMessage = @"
Updated $($UpdatedPackages.Count) Redgate packages:
$($UpdatedPackages -join "`n")
"@

        $PRBody = @"
The following packages were updated:
`````````
$($UpdatedPackages -join "`n")
`````````
This PR was generated automatically.

"@

        if(Test-Path .\.github\PULL_REQUEST_TEMPLATE.md){
            $PRBody += (Get-Content .\.github\PULL_REQUEST_TEMPLATE.md) -join "`n";
        }

        if(Push-GitChangesToBranch -BranchName $UpdateBranchName -CommitMessage $CommitMessage) {
            $PR = New-PullRequestWithProperties `
                -Token $GithubAPIToken `
                -Repo $Repo `
                -Head $UpdateBranchName `
                -Assignees $Assignees `
                -Labels $Labels `
                -Title $PRTitle `
                -Body $PRBody

            Write-Verbose "Pull request is available at: $($PR.html_url)"
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

function UpdatePackageConfigs([string]$RootDir, [string]$Solution, [string[]]$IncludedPackages, [string[]]$ExcludedPackages, [string[]] $NuspecFiles) {
    $packageConfigFiles = GetNugetPackageConfigs -RootDir $RootDir
    
    if (-not $packageConfigFiles) {
        return
    }

    $RedgatePackageIDs = GetNugetPackageIds `
        -PackageConfigs $packageConfigFiles `
        -IncludedPackages $IncludedPackages `
        -ExcludedPackages $ExcludedPackages

    $UpdatedPackages = @()
    
    UpdateNugetPackages -PackageIds $RedgatePackageIDs -Solution $Solution | % { if ($_ -match "Successfully installed '([\w\.]*)") { $UpdatedPackages += $Matches[1] } $_ } | Write-Verbose

    if($NuspecFiles) {
        Resolve-Path $NuspecFiles |
            Select-Object -ExpandProperty Path |
            Update-NuspecDependenciesVersions `
                -PackagesConfigPaths $packageConfigFiles.FullName `
                -DoNotUpdate $ExcludedPackages `
                -Verbose
    }
    
    $UpdatedPackages | Select -Unique | Write-Output
}

function UpdatePackageReferences([string]$RootDir, [string[]]$IncludedPackages, [string[]]$ExcludedPackages) {
    Get-ChildItem $RootDir -Filter *.csproj -Recurse | % { 
        $file = $_.FullName
        $packages = @()
        (Get-Content $_.FullName | % {
            if ($_  -match "<PackageReference Include=`"(?<PackageName>[\.\w]+)`" Version=`"(?<PackageVersion>[\d\.]+)`"") {
                $packages = $packages + @(@{ Name = $Matches.PackageName; Version = $Matches.PackageVersion })
            }
        })
        
        $filteredPackages = @()
        foreach($pattern in $IncludedPackages) {
            $filteredPackages += $packages | Where-Object { $_.Name -like $pattern}
        }

        if($ExcludedPackages) {
            # Remove excluded packages if any
            $filteredPackages = $filteredPackages | Where-Object { $ExcludedPackages -notcontains $_.Name }
        }
        
        $updatedPackages = @()
        if ($filteredPackages) {
            try {
                $filteredPackages | % {
                    $packageName = $_.Name
                    $oldVersion = $_.Version
                    
                    dotnet add "$file" package $packageName | % {
                        if ($_ -match "PackageReference for package '$packageName' version '(?<Version>[\d\.]+)'") {
                            $newVersion = $Matches.Version
                            if ($newVersion -ne $oldVersion) {
                                $updatedPackages += @("$packageName ($oldVersion -> $newVersion)")
                            }
                        }
                    } | Write-Host
                }
            } finally {
                Pop-Location
            }
        
            $updatedPackages | Write-Output
        }
    } | Select -Unique
}
