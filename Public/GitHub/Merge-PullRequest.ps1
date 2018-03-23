<#
.SYNOPSIS
  Merge a pull request.
.DESCRIPTION
  If an pull request with the "merge-when-green" label exists for the given branch and revision,
  this command will merge that pull request.
  If no such pull request exists, this command does nothing.
  This command does not check test status, and should only be called once all relevant tests have passed.
#>
function Merge-PullRequest {
  [CmdletBinding()]
  param(
    # An API token with push permission for your repo.
    [Parameter(Mandatory=$true)]
    [string] $GithubApiToken,

    # The owner of the Github repository
    [Parameter(Mandatory=$false)]
    [string] $owner = "red-gate",

    # The name of the Github repository
    [Parameter(Mandatory=$true)]
    [string] $Repo,

    # The branch that has just successfully built
    [Parameter(Mandatory=$true)]
    [string] $Branch,

    # The revision that has just successfully built.  Truncated revisions are allowed.
    [Parameter(Mandatory=$true)]
    [string] $revision
  )
    if (-not $GithubApiToken) { throw "Github API token needed" }
    if (-not $owner) { throw "owner needed. Whose repo is it?" }
    if (-not $repo) { throw "repo name needed." }
    if (-not $branch) { throw "branch name needed." }
    if (-not $revision) { throw "revision needed. Passing an empty string here would allow any revision to be merged, which can be dangerous if more commits are pushed while the build is in progress." }

    $base64token = [System.Convert]::ToBase64String([char[]]$GithubApiToken);
    $headers = @{ Authorization="Basic $base64token" };

    Use-Tls {
        $searchUri = "https://api.github.com/search/issues?q=user%3A$owner+repo%3A$repo+type%3Apr+state%3Aopen+label%3Amerge-when-green+head%3A$branch"
        Write-Host "Searching for matching PRs with $searchUri"
        $pulls = Invoke-RestMethod -Headers $headers -Uri $searchUri
        if ($pulls.total_count -lt 1)
        {
            Write-Host "No open PRs labeled 'merge-when-green' for branch $branch. Bye!";
            return;
        }
        $pull = $pulls.items | Select -First 1
        $pullNumber = $pull.number
        $pullDetails = Invoke-RestMethod -Headers $headers -Uri https://api.github.com/repos/$owner/$repo/pulls/$pullNumber
        $pullSha = $pullDetails.head.sha
        if (!$pullSha.StartsWith($revision, "CurrentCultureIgnoreCase"))
        {
            Write-Host "This build [$revision] isn't for the head commit, [$pullSha].  Bye!";
            return;
        }
        Write-Host "Merging #$pullNumber..."
        $body = @{sha = $pullSha} | ConvertTo-Json
        Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$owner/$repo/pulls/$pullNumber/merge" -Body $body -Method PUT
        
        Write-Host "Done.  Deleting branch $branch..."
        Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$owner/$repo/git/refs/heads/$branch" -Method DELETE
    }
}
