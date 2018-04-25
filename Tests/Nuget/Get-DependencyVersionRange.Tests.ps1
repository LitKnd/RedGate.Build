#requires -Version 4 -Modules Pester

. $PSScriptRoot\..\..\Private\Nuget\Get-DependencyVersionRange.ps1

Describe 'Get-DependencyVersionRange' {

    function ShouldThrowException($argument){
        try {
            Get-DependencyVersionRange $argument
            throw 'Get-DependencyVersionRange should have thrown an exception'
        } catch {
            $_.Exception.Message | Should Match "Cannot validate argument on parameter 'Version'"
        }
    }

    It 'should throw exception when version is null or empty' {
      ShouldThrowException ''
      ShouldThrowException $null
    }

    It 'should handle a single number version' {
        Get-DependencyVersionRange '1' | Should Be '[1]'
    }

    It 'should handle a 3 part number version' {
        Get-DependencyVersionRange '1.2.3' | Should Be '[1.2.3, 2.0.0)'
    }

    It 'should handle a 3 part number version with suffix' {
        Get-DependencyVersionRange '1.2.3-suffix' -verbose | Should Be '[1.2.3-suffix, 2.0.0-suffix)'
    }

    It 'should handle a 3 part version with suffix where the suffix contains a dash' {
        Get-DependencyVersionRange '1.2.3-suffix-b' -verbose | Should Be '[1.2.3-suffix-b, 2.0.0-suffix-b)'
    }
    
    It 'should handle a 3 part version when specificversion specified' {
        Get-DependencyVersionRange '1.2.3' -SpecificVersion | Should Be '[1.2.3]'
    }
}
