[CmdletBinding()]
param()

function Execute-Command {
  [CmdletBinding(DefaultParameterSetName='ScriptBlock')]
  param(
      [Parameter(Mandatory=$true,ParameterSetName='Command')]
      [string] $Command,
      [Parameter(Mandatory=$true,ParameterSetName='Command')]
      [string[]] $Arguments,
      [Parameter(Mandatory=$true,ParameterSetName='ScriptBlock',Position=0)]
      [scriptblock] $ScriptBlock,
      [int[]] $ValidExitCodes=@(0)
  )

  if( $PsCmdlet.ParameterSetName -eq 'Command' ) {

    $Command = Resolve-Path $Command
    Execute-Command -ScriptBlock { & $Command $Arguments } -ValidExitCodes $ValidExitCodes

  } else {

    Write-Verbose @"
Executing: $ScriptBlock
"@

    . $ScriptBlock
  	if ($ValidExitCodes -notcontains $LastExitCode) {
  		throw "Command {$ScriptBlock} exited with code $LastExitCode."
  	}

  }
}

function Test-FileUnlocked {
  [CmdletBinding()]
  param(
    # The path of the file to check the lock status of
    [Parameter(Mandatory=$true)]
    [string] $Path
  )

  try {
    $Path = Resolve-Path $Path
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    $stream.Close()
    $stream.Dispose()
    return $true
  }
  catch {
    return $false
  }
}

function Wait-FileUnlocked {
  [CmdletBinding()]
  param(
    # The path of the file that is being waited on
    [Parameter(Mandatory=$true)]
    [string] $Path,
    # The timeout value in seconds
    [Parameter(Mandatory=$false)]
    [int] $Timeout = 300
  )

  $totalSleep = 0
  while (-not (Test-FileUnlocked -Path $Path))
  {
    if ($totalSleep -ge $Timeout)
    {
      throw [System.TimeoutException] "File $Path has been locked for more than $Timeout seconds."
    }
    Write-Verbose "File $Path locked. Sleeping for 10 seconds."
    $totalSleep += 10
    Start-Sleep -s 10
  }
}
