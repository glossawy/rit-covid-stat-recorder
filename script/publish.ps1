param(
    [string] $Version,
    [string] $Author,
    [string] $Tag
)

if ( -not ($Version)) {
    throw "You must supply a version either as the first argument, or via -Version. Ex: 1.2-beta"
    exit 1
}

if ( -not ($Author)) {
    throw "You must supply an author either as the second argument, or via -Author. Ex: Glossawy"
    exit 1
}

if ( -not ($Tag)) {
    throw "You must supply a docker tag name either as the third argument, or via -Tag. Ex: rit-covid-recorder"
    exit 1
}

function record {
    param(
        [parameter(ValueFromRemainingArguments)]
        [string[]] $Passthrough
    )

    Write-Host "+ $Passthrough"
    Invoke-Expression "$Passthrough"
}

$LocalTag = $Tag
$DockerHubTag = "$Author/$Tag"

Write-Host "App        : $AppTag"
Write-Host "Author     : $Author"
Write-Host "Docker Tag : $DockerTag"
Write-Host "Version    : $Version"
Write-Host

record .\gradlew --console verbose assemble

record docker build -f .\Dockerfile -t "$LocalTag" --build-arg version="$Version" .

record docker tag "$LocalTag" "$DockerHubTag":"$Version"
record docker tag "$LocalTag" "$DockerHubTag":current

record docker push "$DockerHubTag":"$Version"
record docker push "$DockerHubTag":current
