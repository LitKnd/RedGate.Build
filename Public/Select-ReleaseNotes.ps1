function CreateRelease([version] $version)
{
    # https://learn-powershell.net/2013/08/03/quick-hits-set-the-default-property-display-in-powershell-on-custom-objects/
    # Set up the default display set and create the member set object for use later on
    # Configure a default display set
    $defaultDisplaySet = 'Version', 'Date', 'Blocks', 'Summary'

    # Create the default property display set
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
    
    # Default Release object is created here with nice properties when in a list
    $release = [pscustomobject]@{
        Version = $version
        Date = $nul
        Summary = $nul
        Blocks = @()
    }
    $release.PSObject.TypeNames.Insert(0,'RedGate.Build.VersionInformation')
    $release | Add-Member MemberSet PSStandardMembers $PSStandardMembers
    
    return $release
}

function TrimBlocks($release) {
    foreach($block in $release.Blocks) {
        $block.Value = $block.Value.Trim();
    } 
}

function FinalizeRelease($release, [string]$productName, $accumulator) {
    TrimBlocks($release)
    
    # To see the accumulator in action un-comment this line
    # $accumulator.GetEnumerator() | sort {$_.Key} -Descending
    
    $release.Summary = GetSummary -ProductName $productName -Release $release -Accumulator $accumulator
}

function AddFeature($accumulator, [int] $priority, [string] $feature) {
    # If the same feature exists at a lower priority - raise the priority for the given feature
    if ($accumulator.Values -contains $feature) {
        $accumulator.Remove(($accumulator.GetEnumerator() |? {$_.Value -eq $feature}).Key)
    }
    
    $key = "{0:0000000}" -f $priority    
    # Uniqueify (in a consistent way) if the same priority is used
    if ($accumulator.$key -ne $nul -and $accumulator.($key) -ne $feature) {
        $key = "{0:0000000}-$feature" -f $priority
    }

    $accumulator.($key) = $feature
}

function AddToBlock($release, [string]$currentHeader, [string]$line) {
    $matchingBlock = $release.Blocks |? {$_.Name -eq $currentHeader} | Select -First 1

    if ($matchingBlock) {
        $matchingBlock.Value += [System.Environment]::NewLine + $line
    } else {
        $release.Blocks += [pscustomobject]@{
            Name = $currentHeader
            Value = $line
        }
    }
}

function GetSummary($productName, $release, $accumulator) {    
    $summary = $accumulator.GetEnumerator() | sort {$_.Key} -Descending
    if ($summary) {
        return [string]::Join(", ", $summary.Value)
    } elseif ($productName) {
        if ($release.Version.Revision -ne -1) {
            return "$productName $($release.Version.ToString(3))"
        } else {
            return "$productName $($release.Version)"
        }
    } else {
        throw "Unable to generate summary, no -ProductName and no use of # Strapline blocks."
    }
}

<#
.SYNOPSIS
  Retrieves version information and release notes from a RELEASENOTES.md file or string
.DESCRIPTION
  Creates objects for each version block located in the file as defined by...
  Version+Date = '^#+\s*(?<version>[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?)(\s*-\s*(?<date>.*))?$'
  Date = '^#+\s*.*(?<date>\d\d\d\d.\d\d.\d\d)'
  Header = '^#+\s*(?<header>.+):?$'
  StraplineBlock = '^#+\s*Strapline\s*$'
  Strapline = '^\s*(?<priority>[0-9]+)\s*-\s*(?<feature>.*)\s*$'

  Example input
  -------------
  # Stuff here before the first version
  Is ignored.

  ## 1.2.3.4
  ##### Released on 2016-08-01
  This text goes into .Blocks.General
  ### Fixes
  FIX-01: This text goes into .Blocks.Fixes
  ### Internal:
  Don't show this to customers, it's in .Blocks.Internal

  (Alternative date reading from SQL Compare markdown)
  ----------------------------------------------------
  # 1.2.3 - August 1st 2016
  # 1.2 - March 3rd, 2016
  
  For strapline
  -------------
  ## 2.8.6.499
  ###### Released on 2016-07-12
  ### Strapline
  65 - Updated SQL Compare Engine
  50 - Login licensing
  50 - New feature usage reporting
  
  ### Features
  * New login based licensing: see https://www.red-gate.com/user-licensing for more details
  * New feature usage reporting. Opt in/out from Help > Help us improve our products...
  * SQL Dependency Tracker can now generate log files
  * Logging configuration menu added to Help menu
  * Updated SQL Compare engine
  
  ## 2.8.5.530
  ###### Released on 2016-04-26
  ### Strapline
  90 - SSMS 2016
  
  ### Features
  * Support for SSMS March 2016 Preview Refresh (VS2015 shell)
  * Updated product switcher and Redgate logo
  * Updated SQL Compare engine

.EXAMPLE
  Select-ReleaseNotes -ProductName "SQL Compare" -ReleaseNotesPath ..\SQLCompareUIs\COMPARE_RELEASENOTES.md

  Version      Date                Blocks                          Summary
  -------      ----                ------                          -------
  12.0.25.3064 13/09/2016 00:00:00 {General}                       SQL Compare 12.0.25
  12.0.24.3012 25/08/2016 00:00:00 {Fixes, General}                SQL Compare 12.0.24
  12.0.23.2976 25/08/2016 00:00:00 {Fixes, General}                SQL Compare 12.0.23
  12.0.22.2910 22/08/2016 00:00:00 {Fixes, General}                SQL Compare 12.0.22
  12.0.21.2819 16/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.21
  12.0.20.2791 11/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.20
  12.0.19.2758 09/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.19
  12.0.18.2723 05/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.18
  12.0.17.2708 04/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.17
  12.0.16.2688 03/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.16
  12.0.15.2659 02/08/2016 00:00:00 {Fixes}                         SQL Compare 12.0.15
  12.0.14.2614 28/07/2016 00:00:00 {Features, Fixes}               SQL Compare 12.0.14
  12.0.12.2546 22/07/2016 00:00:00 {Fixes}                         SQL Compare 12.0.12
  12.0.10.2453 15/07/2016 00:00:00 {Fixes}                         SQL Compare 12.0.10
  12.0.9.2436  14/07/2016 00:00:00 {Fixes}                         SQL Compare 12.0.9
  12.0.8.2363  12/07/2016 00:00:00 {Features, Fixes}               SQL Compare 12.0.8
  12.0.7.2257  30/06/2016 00:00:00 {Fixes}                         SQL Compare 12.0.7
.EXAMPLE
  Select-ReleaseNotes -ReleaseNotesPath ..\SQLDependencyTracker\RELEASENOTES.md

  Version   Date                Blocks            Summary
  -------   ----                ------            -------
  2.8.9                         {Features, Fixes} Updated SQL Compare Engine
  2.8.8.523 11/08/2016 00:00:00 {Fixes}           Updated SQL Compare Engine, Bug fixes
  2.8.7.512 01/08/2016 00:00:00 {General}         Updated SQL Compare Engine, Bug fixes
  2.8.6.499 12/07/2016 00:00:00 {Features}        Updated SQL Compare Engine, New feature usage reporting, Login licen...
  2.8.5.530 26/04/2016 00:00:00 {Features}        SSMS 2016, Updated SQL Compare Engine, New feature usage reporting, ...
  2.8.4.261 21/03/2016 00:00:00 {Features, Fixes} SSMS 2016, New appearance, Removed J#, Updated SQL Compare Engine, N...
  2.8.3                         {Never released}  SSMS 2016, New appearance, Removed J#, Updated SQL Compare Engine, N...
  2.8.2.138 17/11/2015 00:00:00 {Features, Fixes} SQL2016, SSMS 2016, New appearance, Removed J#, Updated SQL Compare ...
  2.8.1.182 29/07/2014 00:00:00 {Features}        SQL2016, SSMS 2016, New appearance, Removed J#, Updated SQL Compare ...
  
.EXAMPLE
  Select-ReleaseNotes -ProductName "SQL Source Control" -ReleaseNotesPath ..\SQLSourceControl\RELEASENOTES.md -Latest
  
  Version Date Blocks    Summary
  ------- ---- ------    -------
  5.1.5        {General} SQL Source Control 5.1.5
#>
function Select-ReleaseNotes {
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        # The path of the RELEASENOTES.md file to read from
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 0)]
        [string] $ReleaseNotesPath,
        # The RELEASENOTES markdown to select from
        [Parameter(Mandatory = $true, ParameterSetName = 'String', Position = 0)]
        [string] $ReleaseNotes,
        # Only return the top version block in the file
        [switch] $Latest,
        # Product name (if not using strapline this should be set to create a default summary based on at most 3 part version number)
        [string] $ProductName = $nul
    )
    if ($ReleaseNotesPath) {
        $Lines = Get-Content $ReleaseNotesPath
    } elseif ($ReleaseNotes) {
        # Makes testing easier
        $Lines = ($ReleaseNotes -Replace "'r").Split("`n")
    } else {
        # Shouldn't happen due to ParameterSetName usage above
        throw 'No $ReleaseNotesPath or $ReleaseNotes specified'
    }

    $VersionRegex = '^\s*#+\s*(?<version>[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?)(\s*-\s*(?<date>.*))?\s*$'
    $HeaderRegex = '^\s*#+\s*(?<header>.+):?\s*$'
    $DateRegex = '^\s*#+\s*.*(?<date>\d\d\d\d.\d\d.\d\d)'
    $StraplineStartRegex = '^\s*#+\s*Strapline\s*$'
    $StraplineRegex = '^\s*(?<priority>[0-9]+)\s*-\s*(?<feature>.*)\s*$'

    $Accumulator = @{}
    $StraplineAccumulator = $false
    $Release = $nul
    
    foreach($Line in $Lines) {
        $VersionMatch = [regex]::Match($Line, $VersionRegex)
        if ($VersionMatch.Success) {
            # If a $Release already was being filled in - clean it up and return it
            if ($Release) {
                FinalizeRelease -Release $Release -ProductName $ProductName -Accumulator $Accumulator

                # Return out of the pipeline
                $Release
                
                # If only getting one then ensure I skip everything else
                if ($Latest) {
                    $Release = $nul
                    break
                }
            }
            
            # Default Release object is created here with nice properties when in a list
            $CurrentHeader = 'General'
            $StraplineAccumulator = $false
            $Release = CreateRelease -Version $VersionMatch.Groups['version'].Value

            # Add the SQL Compare style date to the object if found
            if ($VersionMatch.Groups['date'].Success) {
                $simpleDate = $VersionMatch.Groups['date'].Value
                $simpleDate = $simpleDate -replace '(\d+)(st|nd|rd|th)', '$1' -replace ','
                $Release.Date = [DateTime] $simpleDate
            }
        } elseif ($Release) {
            # Only start populating things once we've seen a version and initialised a $Release
            $DateMatch = [regex]::Match($Line, $DateRegex)
            $StraplineStartMatch = [regex]::Match($Line, $StraplineStartRegex)
            $HeaderMatch = [regex]::Match($Line, $HeaderRegex)
            if ($DateMatch.Success) {
                # Date take precedence over header
                $StraplineAccumulator = $false
                $Release.Date = [DateTime] $DateMatch.Groups['date'].Value
            } elseif ($StraplineStartMatch.Success) {
                # Start the strapline accumulator
                $StraplineAccumulator = $true
            } elseif ($HeaderMatch.Success) {
                # New header, prepare to add to new block
                $StraplineAccumulator = $false
                $CurrentHeader = $HeaderMatch.Groups['header'].Value
            } else {
                # This is a line in a block, either a Strapline or a "normal" line
                if ($StraplineAccumulator) {
                    # Ignore newlines in Strapline section
                    if ($Line) {
                        $StraplineMatch = [regex]::Match($Line, $StraplineRegex)
                        if (!$StraplineMatch.Success) {
                            throw "Strapline expected (eg 123 - Title), encountered '$Line'"
                        }
                        AddFeature -accumulator $Accumulator `
                            -priority $StraplineMatch.Groups['priority'].Value `
                            -feature $StraplineMatch.Groups['feature'].Value
                    }
                } else {
                    # Any non date/header line is added to the current block as defined by $CurrentHeader
                    AddToBlock $Release $CurrentHeader $Line
                }
            }
        }
    }

    # Clean up and return the last $Release object being populated (if there is one)
    if ($Release) {
        FinalizeRelease -Release $Release -ProductName $ProductName -Accumulator $Accumulator
        $Release
    }
}
