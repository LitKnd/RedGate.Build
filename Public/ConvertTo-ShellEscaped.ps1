<#
.SYNOPSIS
  Shell-escapes one or more strings for use in a command-line when starting a process.
.DESCRIPTION
  Given one or more argument strings, for each argument, this function will escape double-quote characters and some backslash characters, and surround the string with double-quotes if necessary. The results are then concatenated, using a single ' ' separator character.

  See http://msdn.microsoft.com/en-us/library/a1y7w461.aspx for details on the necessary escaping.
.PARAMETER Arguments
  A list of raw strings to be escaped. Each individual string will be shell-escaped. The resulting escaped strings are then concatenated, using a single ' ' separator character.
.EXAMPLE
  ConvertTo-ShellEscaped 'C:\Program Files\'

  "C:\Program Files\\"
.EXAMPLE
  ConvertTo-ShellEscaped @('-path', 'C:\Program Files\', '-db', 'Data Source=local;Application Name="My app"')

  -path "C:\Program Files\\" -db "Data Source=local;Application Name=\"My app\""
#>
#requires -Version 2
function ConvertTo-ShellEscaped
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeLine = $True)]
        [AllowEmptyString()]
        [string[]] $Arguments
    )
    process {
        # Define regular expressions.
        $QuotesWithPossibleLeadingBackslashes = [regex] '\\*\"'
        $TrailingBackslashes = [regex] '\\+$'
        $NeedsSurroundingQuotes = [regex] '(^$)|\s|\"'

        # Shell escape each individual argument.
        $EscapedArguments = @()
        $Arguments | ForEach-Object {
            # If the string contains double-quotes, with possible leading backslash characters, we need
            # to double up the back-slash characters, and then escape the double-quotes with a further leading backslash.
            $Escaped = $QuotesWithPossibleLeadingBackslashes.Replace($_, {
                    param($Match) (New-Object string @('\', (2 * $Match.Value.Length - 1))) + '"'
            })

            # If the string ends with one or more trailing backslashes, we need to double them up.
            $Escaped = $TrailingBackslashes.Replace($Escaped, {
                    param($Match) New-Object string @('\', (2 * $Match.Value.Length))
            })

            # Finally, surround with quotes if necessary, because:
            # 1. The string is empty.
            # 2. Some escaping actually happened in the above replacement calls.
            # 3. The string contains some whitespace.
            if ($Escaped.Length -ne $_.Length -or $NeedsSurroundingQuotes.IsMatch($_))
            {
                $Escaped = "`"$Escaped`""
            }

            # Add the escaped string to the list.
            $EscapedArguments += $Escaped
        }

        # Join together the escaped arguments into a single string.
        return $EscapedArguments -join ' '
    }
}
