#requires -Version 4 -Modules Pester

Describe 'Test-NugetPackage' {

    It "should return `$True for a package version that exists" {
        $result = Test-NugetPackage -Name Newtonsoft.Json -Version 9.0.1
        $result | Should Be $True
    }

    It "should return `$False for a package that doesn't exist" {
        $result = Test-NugetPackage -Name Totally.Made.Up.Package -Version 1.0.0
        $result | Should Be $False
    }

    It "should return `$False for a package that exists, but the version doesn't exist" {
        $result = Test-NugetPackage -Name Newtonsoft.Json -Version 9999.9999.9999
        $result | Should Be $False
    }
}
