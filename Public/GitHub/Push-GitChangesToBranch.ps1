<#
.SYNOPSIS
    Commit every change and push force to a given branch

.DESCRIPTION
    Create a commit containing all the changes in the current git repo.
    Force-push that commit to a git branch

.EXAMPLE
    Push-GitChangesToBranch -BranchName 'my-branch' -CommitMessage 'This is my commit message'
    Will commit any git changes and push-force them to 'my-branch'
#>
Function Push-GitChangesToBranch
{
    [CmdletBinding()]
    [OutputType([Nullable])]
    Param
    (
        # The branch to push --force to
        [Parameter(Mandatory, Position=0)]
        $BranchName,

        # The git commit message
        [Parameter(Mandatory, Position=1)]
        $CommitMessage,

        # The value 'user.name' used when creating the commit
        # Defaults to rg-buildmonkey
        $CommitUsername = 'rg-buildmonkey',

        # The value 'user.email' used when creating the commit
        # Defaults to github-buildmonkey@red-gate.com
        $CommitEmail = 'github-buildmonkey@red-gate.com',

        # The name of the remote to push to.
        # Defaults to origin
        $RemoteName = 'origin'
    )

    $changes = execute-command { & git status --porcelain}
    if (!$changes){
        Write-Verbose "No changes to commit" -verbose
        return $null
    }

    $GitLocalUserName = git config --local user.name
    $GitLocalEmail = git config --local user.email

    git config --local user.name $CommitUsername
    git config --local user.email $CommitEmail

    execute-command { & git checkout -B $BranchName }
    execute-command { & git add --all }
    execute-command { & git commit -am $CommitMessage }
    execute-command { & git push -f $RemoteName $BranchName`:$BranchName }
    if($GitLocalUserName){
        git config --local user.name $GitLocalUserName
        git config --local user.email $GitLocalEmail
    }else{
        git config --local --unset user.name
        git config --local --unset user.email
    }
}
