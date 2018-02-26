#requires -Version 4 -Modules Pester

Describe 'Merge-PullRequest' {

    Context 'When there are no PRs to merge' {

        It 'should not throw any exception' {
            { Merge-PullRequest -GithubApiToken 'fake-token' -Repo 'nonexistent-repo' -Branch 'nonexistent-branch' -Revision 'nonexistent-revision' } | Should Not Throw
        }
    }
}
