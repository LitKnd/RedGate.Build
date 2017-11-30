function Publish-ResultsAndLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $AssemblyPath,
        [String] $TestResultFilenamePattern = 'TestResult',
        [bool] $ImportResultsToCIServer
    )

    if($ImportResultsToCIServer) {
      CI-ImportNUnitReport "$AssemblyPath.$TestResultFilenamePattern.xml"
    }

    # Tell teamcity to keep our test output logs as well. This could come in handy
    $assemblyFilename = Split-Path $AssemblyPath -Leaf
    # $AssemblyPath.$TestResultFilenamePattern.*x* ? That's a horrible way to only get the .xml and .txt file in 1 line.
    # (and skip the *.coverage.snap file if any)
    # Teamcity doesn't seem to let you add files to an existing zipped file.... oh well...
    TeamCity-PublishArtifact "$AssemblyPath.$TestResultFilenamePattern.*x* => logs/tests/$assemblyFilename.$TestResultFilenamePattern/logs.zip"
}
