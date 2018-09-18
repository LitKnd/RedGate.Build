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
    [string[]] $ReasonsIgnored = @(),

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

  $reasonsIgnoredString = ($ReasonsIgnored | ForEach-Object { "reason/message='$_'" }) -join " or "
  $whereClause = "//test-suite[(@result='Ignored' or @label='Ignored') and (" + $reasonsIgnoredString + ")]"

  $stringBuilder = [System.Text.StringBuilder]::new()
  $stringBuilder.AppendLine("<xsl:stylesheet version=`"1.0`" xmlns:xsl=`"http://www.w3.org/1999/XSL/Transform`">") | Out-Null
  $stringBuilder.AppendLine("<xsl:template match=`"@* | node()`"><xsl:copy><xsl:apply-templates select=`"@* | node()`"/></xsl:copy></xsl:template>") | Out-Null
  $stringBuilder.AppendLine("<xsl:template match=`"$whereClause`" />") | Out-Null
  $stringBuilder.AppendLine("</xsl:stylesheet>") | Out-Null
 
  $compiledTransform = [System.Xml.Xsl.XslCompiledTransform]::new()
  $stringReader = [System.IO.StringReader]::new($stringBuilder.ToString())
  $xmlReader = [System.Xml.XmlTextReader]::new($stringReader)
  $compiledTransform.Load($xmlReader)
  $stringReader.Dispose()
  $xmlReader.Dispose()

  $reader = [System.Xml.XmlReader]::Create($TestResultsPath)
  $filename = Split-Path -Path $TestResultsPath -Leaf
  $tempDirectory = New-TempDir
  $tempFileName = Join-Path $tempDirectory $filename
  $writer = [System.Xml.XmlWriter]::Create("$tempFileName")
  $compiledTransform.Transform($reader, $writer)

  $reader.Dispose()
  $writer.Dispose()

  $totalSleep = 0
  while (-not (Test-FileUnlocked -Path $TestResultsPath))
  {
    if ($totalSleep -ge 300)
    {
      throw [System.TimeoutException] "File $testResultsPath has been locked for more than 5 minutes."
    }
    Write-Host "File $testResultsPath locked. Sleeping for 10 seconds."
    $totalSleep += 10
    Start-Sleep -s 10
  }

  Write-Host "Moving temporary file to the specified location"
  Move-Item -Path $tempFileName -Destination $DestinationFilePath -Force -Verbose
  Write-Host "Removing the temporary directory"
  Remove-Item -Path $tempDirectory -Recurse -Force -Verbose
}