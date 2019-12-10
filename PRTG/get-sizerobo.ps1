function Get-DirectorySizeWithRobocopy {
    param (
        [Parameter(Mandatory=$true)]
        [string]$folder
    )
 
    $fileCount = 0 ; 
    $totalBytes = 0 ; 
    robocopy /l /nfl /ndl $folder \localhostC$nul /e /bytes | ?{ 
        $_ -match "^[ t]+(Files|Bytes) :[ ]+d" 
    } | %{ 
        $line = $_.Trim() -replace '[ ]{2,}',',' -replace ' :',':' ; 
        $value = $line.split(',')[1] ; 
        if ( $line -match "Files:" ) { 
            $fileCount = $value } else { $totalBytes = $value } 
        } ; 
        [pscustomobject]@{Path=',';Files=$fileCount;Bytes=$totalBytes} 
    }