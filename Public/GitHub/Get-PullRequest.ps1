<#
        .SYNOPSIS
        Gets an Open PR from GitHub
        .DESCRIPTION
        Gets an Open PR from GitHub
        .PARAMETER Token
        A github API token wioth full Repo permissions
        .PARAMETER Repo
        The name of the repository to search
        .PARAMETER Head
        The head branch name
        .PARAMETER Base
        The Base branch name (Defaults to master)
        .OUTPUTS
        A PR or null if not found
#>
#requires -Version 2
function Get-PullRequest
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Token,

        [Parameter(Mandatory = $true)]
        [string] $Repo,

        [Parameter(Mandatory = $true)]
        [string] $Head,

        [string] $Base = "master"
    )

    Use-Tls {
        $prs = Invoke-RestMethod `
            -Uri "https://api.github.com/repos/red-gate/$Repo/pulls?head=red-gate:$Head&base=$Base" `
            -Headers @{Authorization="token $Token"} `
            -Method Get
    }

    if($prs.length -eq 0)
    {
        return $null
    }
    
    return $prs[0]
}

