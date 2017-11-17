function Build-NUnit3CommandLineArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $AssemblyPath,
        [bool] $x86,
        [string] $FrameworkVersion,
        [string] $Where,
        [string] $TestResultFilenamePattern = 'TestResult'
    )

    $params = $AssemblyPath,
        "--result=`"$AssemblyPath.$TestResultFilenamePattern.xml`"",
        "--noheader",
        "--labels=On",
        "--out=`"$AssemblyPath.$TestResultFilenamePattern.TestOutput.txt`"",
        "--err=`"$AssemblyPath.$TestResultFilenamePattern.TestError.txt`""

    if($x86) {
        $params += "--x86"
    }

    if($FrameworkVersion) {
        $params += "--framework=$FrameworkVersion"
    }

    if($Where) {
        $params += "--where=$Where"
    }

    return $params
}
