#requires -Version 4 -Modules Pester

# An Amazing test that will check that every function exported by this module does
# indeed have its Powershell help well defined.
Describe 'All exported functions help should be defined' {

  Get-Command -Module RedGate.Build | where {
      $_.Name -notlike '*TeamCity*' `
      -and $_.Name -notlike 'Write-CI*' `
      -and $_.Name -notlike 'Write-VSTS*'
    } | ForEach {
    $command = $_
    Context "Command $($command.Name)" {

      $help = Get-Help $command.Name

      It 'should have a synopsis' {
        $help.Synopsis | Should Not BeNullOrEmpty
        $help.Synopsis.Trim() | Should Not Be $command.Name
      }
      It 'should have a description' {
        $help.Description | Should Not BeNullOrEmpty
      }

      if($help.parameters.parameter) {
        $help.parameters.parameter | ForEach {
          $param = $_
          It "should have a description for parameter $($param.Name)" {
            $param.Description | Should Not BeNullOrEmpty
          }
        }
      }

    }
  }

}
