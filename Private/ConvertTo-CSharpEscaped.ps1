<#
.SYNOPSIS
  Escapes a string so it can be put in double quotes in a C# file
.PARAMETER String
  A list of raw strings to be escaped. Each individual string will be shell-escaped. The resulting escaped strings are then concatenated, using a single ' ' separator character.
.EXAMPLE
  ConvertTo-CSharpEscaped 'Hello "world"!\ <- there's a backslash'

  Hello \"world\"!\\ <- there's a backslash
#>
#requires -Version 2
function ConvertTo-CSharpEscaped
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeLine = $True)]
        [AllowEmptyString()]
        [string] $String
    )
    # See https://blogs.msdn.microsoft.com/csharpfaq/2004/03/12/what-character-escape-sequences-are-available/
    return $String.Replace('\', '\\') ` # Backslash must be first in this list, otherwise we will escape backslashes we've put in
        .Replace('"', '\"') `
        .Replace("`0", '\0') `
        .Replace("`a", '\a') `
        .Replace("`b", '\b') `
        .Replace("`f", '\f') `
        .Replace("`n", '\n') `
        .Replace("`r", '\r') `
        .Replace("`t", '\t') `
        .Replace("`v", '\v')
}
