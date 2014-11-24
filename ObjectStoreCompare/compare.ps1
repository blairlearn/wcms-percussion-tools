<#
	$oldStore - Path to where we find the object store.
    $outputStore - Where to put the generated files.
#>
param ($old, $new)

$OutputFile = "ComparisonReport.htm"

function Main($oldPath, $newPath) {

    if(-not $oldPath -or -not $newPath)
    {
        Write-Host ""
        Write-Host 'You must specify $oldPath - Path to the old object store.'
        Write-Host '             and $newPath - Path to the new object store.'
        exit
    }

    $oldStore = "$oldPath\ObjectStore"
    $newStore = "$newPath\ObjectStore"

    StartComparisonReport

    $oldFileList = GetTypeFileList($oldStore)
    $newFileList = GetTypeFileList($newStore)

    CompareFileLists $oldFileList $newFileList

    EndComparisonReport
}

function CompareFileLists($oldFileList, $newFileList) {
    BeginCompare "Compare File Lists"


    #Find items in the old list missing from the new one.
    $lookup = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($file in $newFileList) { $junk = $lookup.Add($file) }

    foreach($file in $oldFileList) {
        if (-not $lookup.Contains($file)) {
            $type = GetTypeFromFilename $file
            WriteComparison "Type $type not found in $new."
        }
    }

    #find items in the new list that didn't exist before.
    $lookup = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($file in $oldFileList) { $junk = $lookup.Add($file) }

    foreach($file in $newFileList) {
        if (-not $lookup.Contains($file)) {
            $type = GetTypeFromFilename $file
            WriteComparison "Type $type added in $new."
        }
    }

    EndCompare
}

<# Returns an array of file names from the location specified in $path #>
function GetTypeFileList($path) {
    # Filespec for content item descriptor files.
    $typeDefFilter = "psx_*.xml"

    $fileList = @()
    Get-ChildItem $path -filter $typeDefFilter -name | ForEach-Object { $fileList = $fileList + $_ }
    return $fileList
}

function GetTypeFromFilename($filename) {
    # Trim the leading "psx_ce" and the trailing .xml extension.
    $typeName = $filename.Substring(6, $filename.LastIndexOf(".") - 6)
    return $typeName
}

function BeginCompare($title) {
$html = "<section>
    <h2>$title</h2>
    <ul>"
    Write-Host $title":"
    Add-Content $OutputFile -Value $html
}

function EndCompare() {
$html = "</ul></section>"
    Add-Content $OutputFile -Value $html
    
}

function WriteComparison($message) {
    Write-Host $message
    $html = "<li>$message</li>"
    Add-Content $OutputFile -Value $html
}


function StartComparisonReport() {
    $html = "
<html>
<body>
"
#    [System.IO.File]::CreateText($OutputFile)
#    [System.IO.File]::AppendAlLText($OutputFile, $html)
    $junk = New-Item -Name $OutputFile -type File -force
    Add-Content $OutputFile -Value $html
}

function EndComparisonReport() {
$html = "
</body>
</html>
"
    Add-Content $OutputFile -Value $html
}


Main $old $new