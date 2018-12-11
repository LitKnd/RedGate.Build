#requires -Version 2 -Modules Pester


Describe 'Update-AssemblyVersion' {

    BeforeEach {
        $FilePath = [System.IO.Path]::GetTempFileName()
        $FilePath2 = [System.IO.Path]::GetTempFileName()
    }
    
    AfterEach {
        if (Test-Path $FilePath) {
            Remove-Item $FilePath
        }
        if (Test-Path $FilePath2) {
            Remove-Item $FilePath2
        }
    }

    function Set-FileContents($Contents) {
        [System.IO.File]::WriteAllText($FilePath, $Contents)
    }
    
    function Get-FileContents() {
        return [System.IO.File]::ReadAllText($FilePath)
    }

    function Set-FileContents2($Contents) {
        [System.IO.File]::WriteAllText($FilePath2, $Contents)
    }
    
    function Get-FileContents2() {
        return [System.IO.File]::ReadAllText($FilePath2)
    }
    
    Context 'setting the AssemblyVersion' {
        function Check($Original, $Expected) {
            Set-FileContents($Original)
            $FilePath | Update-AssemblyVersion -Version '1.2.3.4'
            Get-FileContents | Should Be $Expected
        }
        It 'should succeed with a four-part version number' {
            Check 'AssemblyVersion("0.0.0.0")' 'AssemblyVersion("1.2.3.4")'
        }
        It 'should succeed with a three-part version number' {
            Check 'AssemblyVersion("0.0.0")' 'AssemblyVersion("1.2.3.4")'
        }
        It 'should succeed with a two-part version number' {
            Check 'AssemblyVersion("0.0")' 'AssemblyVersion("1.2.3.4")'
        }
        It 'should succeed with a single-digit version number' {
            Check 'AssemblyVersion("0")' 'AssemblyVersion("1.2.3.4")'
        }
        It 'should succeed with a version number containing wildcards' {
            Check 'AssemblyVersion("1.0.*")' 'AssemblyVersion("1.2.3.4")'
            Check 'AssemblyVersion("1.*")' 'AssemblyVersion("1.2.3.4")'
        }
        It 'should accomodate white-space' {
            Check 'AssemblyVersion ("0.0.0.0")' 'AssemblyVersion ("1.2.3.4")'
            Check 'AssemblyVersion( "0.0.0.0")' 'AssemblyVersion( "1.2.3.4")'
            Check 'AssemblyVersion("0.0.0.0" )' 'AssemblyVersion("1.2.3.4" )'
        }
        It 'should accomodate a @"..." string literal' {
            Check 'AssemblyVersion(@"0.0.0.0")' 'AssemblyVersion(@"1.2.3.4")'
        }
    }
    
    Context 'setting the AssemblyFileVersion' {
        function Check($Original, $Expected) {
            Set-FileContents($Original)
            $FilePath | Update-AssemblyVersion -Version '5.6.7.8' -FileVersion '1.2.3.4'
            Get-FileContents | Should Be $Expected
        }
        It 'should succeed with a four-part version number' {
            Check 'AssemblyFileVersion("0.0.0.0")' 'AssemblyFileVersion("1.2.3.4")'
        }
        It 'should succeed with a three-part version number' {
            Check 'AssemblyFileVersion("0.0.0")' 'AssemblyFileVersion("1.2.3.4")'
        }
        It 'should succeed with a two-part version number' {
            Check 'AssemblyFileVersion("0.0")' 'AssemblyFileVersion("1.2.3.4")'
        }
        It 'should succeed with a single-digit version number' {
            Check 'AssemblyFileVersion("0")' 'AssemblyFileVersion("1.2.3.4")'
        }
        It 'should succeed with a version number containing wildcards' {
            Check 'AssemblyFileVersion("1.0.*")' 'AssemblyFileVersion("1.2.3.4")'
            Check 'AssemblyFileVersion("1.*")' 'AssemblyFileVersion("1.2.3.4")'
        }
        It 'should accomodate white-space' {
            Check 'AssemblyFileVersion ("0.0.0.0")' 'AssemblyFileVersion ("1.2.3.4")'
            Check 'AssemblyFileVersion( "0.0.0.0")' 'AssemblyFileVersion( "1.2.3.4")'
            Check 'AssemblyFileVersion("0.0.0.0" )' 'AssemblyFileVersion("1.2.3.4" )'
        }
        It 'should accomodate a @"..." string literal' {
            Check 'AssemblyFileVersion(@"0.0.0.0")' 'AssemblyFileVersion(@"1.2.3.4")'
        }
    }
    
    Context 'setting the AssemblyInformationalVersion' {
        function Check($Original, $Expected) {
            Set-FileContents($Original)
            $FilePath | Update-AssemblyVersion -Version '5.6.7.8' `
                                                               -FileVersion '9.10.11.12' `
                                                               -InformationalVersion '1.2.3.4'
            Get-FileContents | Should Be $Expected
        }
        It 'should succeed with a four-part version number' {
            Check 'AssemblyInformationalVersion("0.0.0.0")' 'AssemblyInformationalVersion("1.2.3.4")'
        }
        It 'should succeed with a three-part version number' {
            Check 'AssemblyInformationalVersion("0.0.0")' 'AssemblyInformationalVersion("1.2.3.4")'
        }
        It 'should succeed with a two-part version number' {
            Check 'AssemblyInformationalVersion("0.0")' 'AssemblyInformationalVersion("1.2.3.4")'
        }
        It 'should succeed with a single-digit version number' {
            Check 'AssemblyInformationalVersion("0")' 'AssemblyInformationalVersion("1.2.3.4")'
        }
        It 'should succeed with a version number containing wildcards' {
            Check 'AssemblyInformationalVersion("1.0.*")' 'AssemblyInformationalVersion("1.2.3.4")'
            Check 'AssemblyInformationalVersion("1.*")' 'AssemblyInformationalVersion("1.2.3.4")'
        }
        It 'should accomodate white-space' {
            Check 'AssemblyInformationalVersion ("0.0.0.0")' 'AssemblyInformationalVersion ("1.2.3.4")'
            Check 'AssemblyInformationalVersion( "0.0.0.0")' 'AssemblyInformationalVersion( "1.2.3.4")'
            Check 'AssemblyInformationalVersion("0.0.0.0" )' 'AssemblyInformationalVersion("1.2.3.4" )'
        }
        It 'should accomodate a @"..." string literal' {
            Check 'AssemblyInformationalVersion(@"0.0.0.0")' 'AssemblyInformationalVersion(@"1.2.3.4")'
        }
        It 'should accomodate a NuGet-style pre-release suffix' {
            Check 'AssemblyInformationalVersion("0.0.0.0-dev")' 'AssemblyInformationalVersion("1.2.3.4")'
        }
    }
    
    Context 'inheriting Version numbers for optional Version parameters' {
        It 'should inherit the AssemblyFileVersion from the AssemblyVersion' {
            Set-FileContents('AssemblyFileVersion("0.0.0.0")')
            $FilePath | Update-AssemblyVersion -Version '1.2.3.4'
            Get-FileContents | Should Be 'AssemblyFileVersion("1.2.3.4")'
        }
        It 'should inherit the AssemblyInformationalVersion from the AssemblyFileVersion' {
            Set-FileContents('AssemblyInformationalVersion("0.0.0.0")')
            $FilePath | Update-AssemblyVersion -Version '5.6.7.8' -FileVersion '1.2.3.4'
            Get-FileContents | Should Be 'AssemblyInformationalVersion("1.2.3.4")'
        }
        It 'should inherit the AssemblyInformationalVersion from the AssemblyVersion when the AssemblyInformationalVersion is absent' {
            Set-FileContents('AssemblyInformationalVersion("0.0.0.0")')
            $FilePath | Update-AssemblyVersion -Version '1.2.3.4'
            Get-FileContents | Should Be 'AssemblyInformationalVersion("1.2.3.4")'
        }
    }
    
    Context 'multiple files' {
        It 'should inherit the AssemblyFileVersion from the AssemblyVersion' {
            Set-FileContents('AssemblyFileVersion("0.0.0.0")')
            Set-FileContents2('AssemblyFileVersion("0.0.0.0")')
            @($FilePath, $FilePath2) | Update-AssemblyVersion -Version '1.2.3.4'
            Get-FileContents | Should Be 'AssemblyFileVersion("1.2.3.4")'
            Get-FileContents2 | Should Be 'AssemblyFileVersion("1.2.3.4")'
        }
    }
}
