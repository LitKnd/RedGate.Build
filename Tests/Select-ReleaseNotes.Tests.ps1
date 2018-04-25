#requires -Version 4 -Modules Pester

Describe 'Select-ReleaseNotes' {
    InModuleScope RedGate.Build {
        Context 'Two Part Version' {
            Mock Get-Content { '# 1.2' }
            $v = Select-ReleaseNotes -ProductName "Test" -ReleaseNotesPath 'DoesNotExist\RELEASENOTES.md'
            $v.Version | Should Be '1.2'
            $v.Summary | Should Be 'Test 1.2'
            $v.Date | Should Be $nul
            $v.Blocks.Count | Should Be 0
        }
    }

    InModuleScope RedGate.Build {
        Context 'Three Part Version' {
            Mock Get-Content { '##1.2.3' }
            $v = Select-ReleaseNotes -ProductName "Test" -ReleaseNotesPath 'DoesNotExist\RELEASENOTES.md'
            $v.Version | Should Be '1.2.3'
            $v.Summary | Should Be 'Test 1.2.3'
            $v.Date | Should Be $nul
            $v.Blocks.Count | Should Be 0
        }
    }

    InModuleScope RedGate.Build {
        Context 'Four Part Version' {
            Mock Get-Content { '### 1.2.3.4   ' }
            $v = Select-ReleaseNotes -ProductName "Test" -ReleaseNotesPath 'DoesNotExist\RELEASENOTES.md'
            $v.Version | Should Be '1.2.3.4'
            $v.Summary | Should Be 'Test 1.2.3'
            $v.Date | Should Be $nul
            $v.Blocks.Count | Should Be 0
        }
    }

    InModuleScope RedGate.Build {
        Context 'SDT Top' {
            $v = Select-ReleaseNotes -ReleaseNotes @"
# SQL Dependency Tracker Release Notes
## 2.8.9
General content
### Strapline
100 - Feature

### Features
Cool feature

### Fixes
* Nasty fix
"@
            $v.Version | Should Be '2.8.9'
            $v.Summary | Should Be 'Feature'
            $v.Date | Should Be $nul
            $v.Blocks[0].Name | Should Be 'General'
            $v.Blocks[0].Value | Should Be 'General content'
            $v.Blocks[1].Name | Should Be 'Features'
            $v.Blocks[1].Value | Should Be 'Cool Feature'
            $v.Blocks[2].Name | Should Be 'Fixes'
            $v.Blocks[2].Value | Should Be '* Nasty fix'
        }
    }

    InModuleScope RedGate.Build {
        Context 'SOC Date' {
            $v = Select-ReleaseNotes -ProductName "SQL Source Control" -ReleaseNotes @"
## 5.1.4
###### Released on 2016-07-08
"@
            $v.Version | Should Be '5.1.4'
            $v.Summary | Should Be 'SQL Source Control 5.1.4'
            $v.Date | Should Be ([DateTime] '2016-07-08')
            $v.Blocks.Count | Should Be 0
        }
    }

    InModuleScope RedGate.Build {
        Context 'SQL Compare Date' {
            $v = Select-ReleaseNotes -ProductName "SQL Compare" -ReleaseNotes @"
## 12.0.25.3064 - September 13th 2016
"@
            $v.Version | Should Be '12.0.25.3064'
            $v.Summary | Should Be 'SQL Compare 12.0.25'
            $v.Date | Should Be ([DateTime] '2016-09-13')
            $v.Blocks.Count | Should Be 0
        }
    }

    InModuleScope RedGate.Build {
        Context 'Multiple Versions' {
            $vs = Select-ReleaseNotes -ReleaseNotes @"
# SQL Dependency Tracker Release Notes
## 2.8.9
### Strapline
65 - Updated SQL Compare Engine

### Features
* Updated to the latest SQL Compare engine, version 12, featuring a number of fixes and enhancements.  Removes support for SQL Server 2000 databases.

### Fixes
* Latest UI components, fixes initial window position, layout issues and a rare crash

## 2.8.8.523
###### Released on 2016-08-11
### Strapline
10 - Bug fixes

### Fixes
* Updated feature usage reporting library
* Latest UI components, uses a more legible font on the menu
* Old activations of SQL Dependency Tracker now work as expected

## 2.8.7.512
###### Failed release on 2016-08-01
"@
            $vs.Length | Should Be 3
            $vs[0].Version | Should Be '2.8.9'
            $vs[0].Summary | Should Be 'Updated SQL Compare Engine'
            $vs[0].Date | Should Be $nul
            $vs[0].Blocks.Count | Should Be 2
            $vs[0].Blocks[0].Name | Should Be 'Features'
            $vs[0].Blocks[0].Value | Should Be '* Updated to the latest SQL Compare engine, version 12, featuring a number of fixes and enhancements.  Removes support for SQL Server 2000 databases.'
            $vs[0].Blocks[1].Name | Should Be 'Fixes'
            $vs[0].Blocks[1].Value | Should Be '* Latest UI components, fixes initial window position, layout issues and a rare crash'

            $fixes = '* Updated feature usage reporting library' + [System.Environment]::NewLine + `
'* Latest UI components, uses a more legible font on the menu' + [System.Environment]::NewLine + `
'* Old activations of SQL Dependency Tracker now work as expected'

            $vs[1].Version | Should Be '2.8.8.523'
            $vs[1].Summary | Should Be 'Updated SQL Compare Engine, Bug Fixes'
            $vs[1].Date | Should Be ([DateTime] '2016-08-11')
            $vs[1].Blocks.Count | Should Be 1
            $vs[1].Blocks[0].Name | Should Be 'Fixes'
            $vs[1].Blocks[0].Value | Should Be $fixes

            $vs[2].Version | Should Be '2.8.7.512'
            $vs[2].Summary | Should Be 'Updated SQL Compare Engine, Bug Fixes'
            $vs[2].Date | Should Be ([DateTime] '2016-08-01')
            $vs[2].Blocks.Count | Should Be 0
        }
    }

    InModuleScope RedGate.Build {
        Context 'Latest Multiple Versions' {
            $v = Select-ReleaseNotes -ProductName "Test" -Latest -ReleaseNotes @"
# SQL Dependency Tracker Release Notes
## 2.8.9
### Features
* Updated to the latest SQL Compare engine, version 12, featuring a number of fixes and enhancements.  Removes support for SQL Server 2000 databases.

### Fixes
* Latest UI components, fixes initial window position, layout issues and a rare crash

## 2.8.8.523
###### Released on 2016-08-11
### Fixes
* Updated feature usage reporting library
* Latest UI components, uses a more legible font on the menu
* Old activations of SQL Dependency Tracker now work as expected

## 2.8.7.512
###### Failed release on 2016-08-01
"@
            $v.Version | Should Be '2.8.9'
            $v.Summary | Should Be 'Test 2.8.9'
            $v.Date | Should Be $nul
            $v.Blocks.Count | Should Be 2
            $v.Blocks[0].Name | Should Be 'Features'
            $v.Blocks[0].Value | Should Be '* Updated to the latest SQL Compare engine, version 12, featuring a number of fixes and enhancements.  Removes support for SQL Server 2000 databases.'
            $v.Blocks[1].Name | Should Be 'Fixes'
            $v.Blocks[1].Value | Should Be '* Latest UI components, fixes initial window position, layout issues and a rare crash'
        }
    }

    InModuleScope RedGate.Build {
        Context 'Strapline Same Priority' {
            $vs = Select-ReleaseNotes -ProductName "Test" -ReleaseNotes @"
## 1.2.3.4
### Strapline
50-Top
10-Bottom

## 1.0.0.0
### Strapline
10          -              Also Bottom
"@
            $vs.Length | Should Be 2
            $vs[0].Version | Should Be '1.2.3.4'
            $vs[0].Summary | Should Be 'Top, Bottom'

            $vs[1].Version | Should Be '1.0.0.0'
            $vs[1].Summary | Should Be 'Top, Also Bottom, Bottom'
        }
    }
    
    InModuleScope RedGate.Build {
        Context 'Older Feature Higher Priority' {
            $vs = Select-ReleaseNotes -ProductName "Test" -ReleaseNotes @"
## 1.2.3.4
### Strapline
50 - Top
10 -Thing

## 1.0.0.0
### Strapline
99- Thing
"@
            $vs.Length | Should Be 2
            $vs[0].Version | Should Be '1.2.3.4'
            $vs[0].Summary | Should Be 'Top, Thing'

            $vs[1].Version | Should Be '1.0.0.0'
            $vs[1].Summary | Should Be 'Thing, Top'
        }
    }
        
    InModuleScope RedGate.Build {
        Context 'Duplicate Priority Older Feature Higher Priority' {
            $vs = Select-ReleaseNotes -ProductName "Test" -ReleaseNotes @"
## 1.2.3.4
### Strapline
50 - Top
10 - Other thing
10 - Thing

## 1.0.0.0
### Strapline
99 - Thing
"@
            $vs.Length | Should Be 2
            $vs[0].Version | Should Be '1.2.3.4'
            $vs[0].Summary | Should Be 'Top, Thing, Other thing'

            $vs[1].Version | Should Be '1.0.0.0'
            $vs[1].Summary | Should Be 'Thing, Top, Other thing'
        }
    }

    InModuleScope RedGate.Build {
        Context 'Invalid Strapline' {
            { Select-ReleaseNotes -ProductName "Test" -ReleaseNotes @"
## 1.2.3.4
### Strapline
50. This would look like 1. xxx on github (bad)
"@} | Should Throw
        }
    }
    
    InModuleScope RedGate.Build {
        Context 'Not Strapline' {
            { Select-ReleaseNotes -ProductName "Test" -ReleaseNotes @"
## 1.2.3.4
### Strapline
Just trying to put any text here isn't allowed
"@} | Should Throw
        }
    }
    
    InModuleScope RedGate.Build {
        Context 'Version in Strapline' {
            $v = Select-ReleaseNotes -ProductName "Test" -Latest -ReleaseNotes @"
## 3.1.1
### Strapline
50 - SQL Doc 3.1.1
"@
            $v.Version | Should Be '3.1.1'
            $v.Summary | Should Be 'SQL Doc 3.1.1'
        }
    }

        InModuleScope RedGate.Build {
        Context 'Blocks are in correct order' {
            $v = Select-ReleaseNotes -ProductName "Test" -Latest -ReleaseNotes @"
## 3.1.1
This is a release

### Introduction
Text

### Features
* A feature

### Fixes
* A fix
"@
            $v.Blocks.Count | Should Be 4
            $v.Blocks[0].Name | Should Be 'General'
            $v.Blocks[1].Name | Should Be 'Introduction'
            $v.Blocks[2].Name | Should Be 'Features'
            $v.Blocks[3].Name | Should Be 'Fixes'
        }
    }

# Many existing release scripts call GetEnumerator() on the Blocks object
        InModuleScope RedGate.Build {
        Context 'Blocks can be accessed through GetEnumerator' {
            $v = Select-ReleaseNotes -ProductName "Test" -Latest -ReleaseNotes @"
## 3.1.1
### Features
* A feature

### Fixes
* A fix
"@
            $enumerator = $v.Blocks.GetEnumerator()
            $enumerator.MoveNext() | Should Be $true
            $enumerator.Current.Name | Should Be 'Features'
            $enumerator.Current.Value | Should Be '* A feature'
            $enumerator.MoveNext() | Should Be $true
            $enumerator.Current.Name | Should Be 'Fixes'
            $enumerator.Current.Value | Should Be '* A fix'
            $enumerator.MoveNext() | Should Be $false
        }
    }
}

# Indentation in block content is preserved
InModuleScope RedGate.Build {
    Context 'Indentation is preserved' {
        $v = Select-ReleaseNotes -ProductName "Test" -Latest -ReleaseNotes @"
## 3.1.1
### Features
* A feature

  With indented content, whose whitespace
  ought to be preserved

* Another feature
"@
        $v.Blocks[0].Value | Should Be @"
* A feature

  With indented content, whose whitespace
  ought to be preserved

* Another feature
"@
    }
}
