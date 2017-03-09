
<#
        .SYNOPSIS
        Opens a PR on  GitHub
        .DESCRIPTION
        Opens a PR on  GitHub
        .PARAMETER Token
        A github API token wioth full Repo permissions
        .PARAMETER Repo
        The name of the repository
        .PARAMETER Title
        The Title of the PR
        .PARAMETER Body
        The description of the PR.  Defaults to ""
        .PARAMETER Head
        The head branch name
        .PARAMETER Base
        The Base branch name (Defaults to master)
        .OUTPUTS
        A PR
#>
#requires -Version 2
function New-PullRequest
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Token,

        [Parameter(Mandatory = $true)]
        [string] $Repo,

        [Parameter(Mandatory = $true)]
        [string] $Title,

        [string] $Body = "",

        [Parameter(Mandatory = $true)]
        [string] $Head,

        [string] $Base = "master"
    )
    return Invoke-RestMethod `
            -Uri "https://api.github.com/repos/red-gate/$Repo/pulls" `
            -Headers @{Authorization="token $Token"} `
            -Method Post `
            -Body `
@"
{
    "title": "$Title",
    "body": "$Body",
    "head": "$Head",
    "base": "$Base"
}
"@
}