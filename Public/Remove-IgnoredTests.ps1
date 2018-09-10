<#
.SYNOPSIS
  Remove ignored tests from a NUnit test results xml file.
.DESCRIPTION
  1. Load the NUnit tests results file
  2. Find any ignored tests (optional: matching a reason from -ReasonsIgnored) and remove them
  3.  Save back to xml.
.EXAMPLE
  Remove-IgnoredTests -TestResultsPath 'D:\TestResults.xml' -ReasonsIgnored 'Why are we writing tests like *'
#>
function Remove-IgnoredTests {
  [CmdletBinding()]
  param(
    # The path of the test results xml file to process
    [Parameter(Mandatory=$true)]
    [string] $TestResultsPath,

    # A list of ignored reason messages.
    # Only tests with a ignored reason matching a string in this list will be removed
    # wildcards '*' are supported
    [string[]] $ReasonsIgnored = @('*'),

    # Use this parameter to save the updated xml to a different file
    [string] $DestinationFilePath
  )

  # Crude parameter checking
  $TestResultsPath = Resolve-Path $TestResultsPath

  if( $DestinationFilePath -eq '' ) {
    $DestinationFilePath = $TestResultsPath
  } else {
    #resolve to full path because XmlDocument.Save() needs it. (thanks http://stackoverflow.com/questions/3038337/powershell-resolve-path-that-might-not-exist)
    $DestinationFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationFilePath)
  }

  Write-Verbose "Loading test results from $TestResultsPath"
  $xml = [xml](Get-Content $TestResultsPath)

  $ignoredTests = $xml | Select-Xml -XPath '//test-suite[@result="Ignored" or @label="Ignored"]'

  foreach($test in $ignoredTests) {
    foreach( $reason in @($ReasonsIgnored)  ) {
      if( $test.node.Reason.message.innertext -like $reason ) {
        # remove the test
        Write-Verbose "Removing ignored test: $($test.node.name)"
        $test.node.ParentNode.RemoveChild($test.node) | Out-Null
        break;
      }
    }
  }

  Write-Verbose "Saving updated results to $DestinationFilePath"
  $xml.Save( $DestinationFilePath)
}
