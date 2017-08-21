function Build-NUnitCommandLineArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $AssemblyPath,
        [string] $FrameworkVersion,
        [string[]] $ExcludedCategories = @(),
        [string[]] $IncludedCategories = @(),
        [string] $TestResultFilenamePattern = 'TestResult'
    )

    $params = $AssemblyPath,
        "/xml=`"$AssemblyPath.$TestResultFilenamePattern.xml`"",
        '/nologo',
        '/nodots',
        '/noshadow',
        '/labels',
        "/out:`"$AssemblyPath.$TestResultFilenamePattern.TestOutput.txt`"",
        "/err:`"$AssemblyPath.$TestResultFilenamePattern.TestError.txt`""

    if($FrameworkVersion) {
        $params += "/framework:$FrameworkVersion"
    }

    #add the /exclude param if $ExcludedCategories is not empty:
    if($ExcludedCategories) {
        $params += "/exclude:$($ExcludedCategories -join ';')"
    }

    #add the /include param if $IncludedCategories is not empty:
    if($IncludedCategories) {
        $params += "/include:$($IncludedCategories -join ';')"
    }

    return $params
}
