<#
	Path to where we find the object store.  On any of our standard WCMS installations, this will
	always be e:\Rhythmyx\ObjectStore
#>
$OBJECT_STORE = "C:\WCMTeam\Tools\ObjectStoreExtract"

# Filespec for content item descriptor files.
$typeDefFilter = "psx_*.xml"

function Extract ($fileInfo) {
	[xml]$doc = Get-Content $fileInfo

	$editorInfo = $doc.SelectSingleNode("/PSXApplication/PSXContentEditor")
	$attributes = $editorInfo.Attributes

	# Metadata.
	$contentTypeID = $attributes.ItemOf("contentType").Value
	$contentTypeName = $editorInfo.SelectSingleNode("PSXDataSet/name/text()").Value

	echo "Extracting type $contentTypeName ($contentTypeID)."

    # Find the list of fields
    $colFields = @();  # Empty array
    Select-Xml -Xml $editorInfo -XPath "//PSXUIDefinition/PSXDisplayMapper/PSXDisplayMapping" | ForEach-Object {
        
        $name = $_.Node.FieldRef
        $label = ""
        echo $name

        if( $_.Node.PSXUISet -ne $Null -and $_.Node.PSXUISet.Label -ne $Null -and $_.Node.PSXUISet.Label.PSXDisplayText -ne $Null) {
            $label = $_.Node.PSXUISet.Label.PSXDisplayText
            echo "Label $label"
        }
    }

<#	# Find the list of fields
	$colFields = @();  # Empty array
	$displayInfo = $editorInfo.SelectNodes("//PSXUIDefinition/PSXDisplayMapper/PSXDisplayMapping")
echo $displayInfo.Count

	ForEach-Object -InputObject $displayInfo {
		#$name = $_.Item.SelectSingleNode("FieldRef/text()").Value
		Get-Member -InputObject $_
		#echo "asfsa $name"

	}#>
}


Get-ChildItem $typeDefFilter -filter $typeDefs | ForEach-Object {
	Extract($_)
}
