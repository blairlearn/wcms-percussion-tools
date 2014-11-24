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

    $reconciledList = CompareFileLists $oldFileList $newFileList
    CompareFields $oldStore $newStore $reconciledList

    EndComparisonReport
}

<#
    Compare the fields of types which are found in both the old and the new objectStores.

    $oldPath - Path to the old objectStore
    $newPath - Path to the new objectStore
    $reconciledFileList - List of type definition files which exist in both objectStores.
#>
function CompareFields($oldPath, $newPath, $reconciledFileList) {

    BeginCompare "Compare Fields"

    foreach($file in $reconciledFileList) {
        Write-Host $file
        [xml]$oldDoc = Get-Content "$oldPath\$file"
        [xml]$newDoc = Get-Content "$newPath\$file"

        $type = GetTypeFromFilename $file

        # Loop through the old set of fields, listing any that are missing or have changed.
        $fieldSet = $oldDoc.SelectNodes("//PSXUIDefinition/PSXDisplayMapper/PSXDisplayMapping")
        foreach($field in $fieldSet) {
            $fieldName = $field.FieldRef
            $newField = $newDoc.SelectSingleNode("//PSXUIDefinition/PSXDisplayMapper/PSXDisplayMapping/FieldRef[text() = '$fieldName']")

            if(-not $newField) {
                WriteComparison "$new::$type removed field '$fieldName'."
            }
        }

        # Loop through the new set of fields to find any additions.
        $fieldSet = $newDoc.SelectNodes("//PSXUIDefinition/PSXDisplayMapper/PSXDisplayMapping")
        foreach($field in $fieldSet) {
            $fieldName = $field.FieldRef
            $oldField = $oldDoc.SelectSingleNode("//PSXUIDefinition/PSXDisplayMapper/PSXDisplayMapping/FieldRef[text() = '$fieldName']")

            if(-not $oldField) {
                WriteComparison "$new::$type added field '$fieldName."
            }
        }

    }

    EndCompare
}


<#
    Compare the old and new lists of files.
    Types which aren't found in both locations are recorded in the ouptut file.

    Returns a list of files which are found in both locations.
#>
function CompareFileLists($oldFileList, $newFileList) {
    $mergedList = @()

    BeginCompare "Compare Type Lists"

    #Find items in the old list missing from the new one.
    $lookup = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($file in $newFileList) { $junk = $lookup.Add($file) }

    foreach($file in $oldFileList) {
        if (-not $lookup.Contains($file)) {
            $type = GetTypeFromFilename $file
            WriteComparison "Type $type removed in $new."
        }
    }

    #find items in the new list that didn't exist before.
    $lookup = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($file in $oldFileList) { $junk = $lookup.Add($file) }

    foreach($file in $newFileList) {
        if (-not $lookup.Contains($file)) {
            $type = GetTypeFromFilename $file
            WriteComparison "Type $type added in $new."
        } else {
            $mergedList += $file
        }
    }

    EndCompare

    return $mergedList
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
<h1>Compare $old to $new</h1>
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