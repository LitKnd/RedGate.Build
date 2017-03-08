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
    Process
    {
        $RedgatePackageIDs = Get-NugetPackageIDs -RootDir $RootDir `
                                | Where-Object{ $_ -like "Redgate.*"} `
        
        UpdateNugetPackages -PackageIds $RedgatePackageIDs -Solution $Solution

        $changes = git status --porcelain
        if ($changes -eq $null){
            return;
        }
        
        $UpdateBranchName = "pkg-auto-update"
        CreateNewBranchAndForcePush -NewBranchName $UpdateBranchName -CommitMessage "Updated $RedgatePackageIDs"

        $ExistingPR = Get-PullRequest -Token $GithubAPIToken -Repo $Repo -Head $UpdateBranchName
        
        if($ExistingPR -eq $null){
            "No open PR found - Creating a new one..."
            $NewPR = New-PullRequest -Token $GithubAPIToken -Repo $Repo -Head $UpdateBranchName -Title "Redgate Nuget Package Auto-Update" -Body "The following packages were updated: $RedgatePackageIDs.  This PR was generated automatically."
            "PR Created ${NewPR.url}"
            "Assigning PR ${NewPR.id} to $NugetAutoUpdateAssignees"
            Update-PullRequest -Token $GithubAPIToken -Repo $Repo -Number $NewPR.number -Assignees $Assignees
            "PR Assigned"
            
        }else{
            "PR already exists:"
            ${ExistingPR}
        }
    }
}

function CreateNewBranchAndForcePush($NewBranchName, $CommitMessage){
    $GitLocalUserName = git config --local user.name
    $GitLocalEmail = git config --local user.email

    git config --local user.name "rgbuildmonkey"
    git config --local user.email "github-buildmonkey@red-gate.com"

    exec { & git checkout -B $NewBranchName }
    exec { & git commit -am $CommitMessage }
    exec { & git push -f origin $NewBranchName`:$NewBranchName }
    
    git config --local user.name $GitLocalUserName
    git config --local user.email $GitLocalEmail
}

function UpdateNugetPackages($PackageIds, $Solution){
    $NugetPackageParams = $PackageIds `
                        | ForEach-Object {
                            "-id", $_
                        }  
    exec {
        & $NugetExe update $Solution -Verbosity detailed -noninteractive $NugetPackageParams
    }
}