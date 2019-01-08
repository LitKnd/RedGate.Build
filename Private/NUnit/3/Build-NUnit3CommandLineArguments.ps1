function Build-NUnit3CommandLineArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $AssemblyPath,
        [bool] $x86,
        [int] $Timeout,
        [string] $FrameworkVersion,
        [string] $Where,
        [string] $TestResultFilenamePattern = 'TestResult',
        [string] $ProcessIsolation
    )

    $params = $AssemblyPath,
        "--result=`"$AssemblyPath.$TestResultFilenamePattern.xml`"",
        "--noheader",
        "--labels=On",
        "--out=`"$AssemblyPath.$TestResultFilenamePattern.TestOutput.txt`""

    if ($x86) {
        $params += "--x86"
    }

    if ($Timeout) {
        $params += "--timeout=$Timeout"
    }

    if ($FrameworkVersion) {
        $params += "--framework=$FrameworkVersion"
    }

    if ($Where) {
        $params += "--where=$Where"
    }
    
    if ($ProcessIsolation) {
        $params += "--process=$ProcessIsolation"
    }
    
    return $params
}
