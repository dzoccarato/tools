param (
    [Parameter(Mandatory=$false)][switch]$HELP,
    [Parameter(Mandatory=$false)][switch]$MAJOR,
    [Parameter(Mandatory=$false)][switch]$MINOR,
    [Parameter(Mandatory=$false)][switch]$PATCH,
    [Parameter(Mandatory=$false)][string]$BUILD,
    [Parameter(Mandatory=$false)][switch]$TAG_AND_PUSH,
    [Parameter(Mandatory=$false)][switch]$SHOW
)
if($HELP) {            
    echo "# version updater for package.json files";
    echo "bump version +1 in package.json";
    echo "# params:";
    echo " -HELP (not mandatory) => call this help";
    echo " -SHOW (not mandatory) => shows versions. DOES NOT MODIFY THEM";
    echo " -MAJOR (not mandatory) => +1 on major version. reset minor and patch to 0";
    echo " -MINOR (not mandatory) => +1 on minor version. reset patch to 0";
    echo " -PATCH (not mandatory) => +1 on patch version.";
    echo " none of above => +1 on patch version";
    echo " -BUILD (not mandatory) => exact version. If not specified, default is 0";
    echo " -TAG_AND_PUSH (not mandatory) => automatically tag with new version and push the *.csproj to repo";
    echo "# example:";
    echo ".\updateVersion.ps1";
    echo ".\updateVersion.ps1 -TAG_AND_PUSH";
    echo ".\updateVersion.ps1 -MINOR -TAG_AND_PUSH";
    echo ".\updateVersion.ps1 -MAJOR -TAG_AND_PUSH";
    echo ".\updateVersion.ps1 -BUILD 1.2.3.4 -TAG_AND_PUSH";
    return;
}
$projectInfos = ( Get-ChildItem -Filter package.json ).FullName
$newVersion = "";
foreach ($info in $projectInfos)
{
    # version info
    [int]$_major = 0;
    [int]$_minor = 0;
    [int]$_patch = 0;
    [int]$_build = 0;
    $version = "";
    # look for version
    foreach($line in Get-Content $info) {
        if($line -match """Version""\:\s*""(.*)"","){        
            $version = $matches[1].Split("{.}");
            $_major = [int]$version[0];
            $_minor = [int]$version[1];
            $_patch = [int]$version[2];
            $_build = [int]$version[3];
            if ($SHOW) {
            
                $file = Split-Path $info -leaf;
                Write-Host "${file}: " -NoNewline -ForegroundColor DarkGray
                Write-Host "${version}" -ForegroundColor Gray
                continue;           
            }
            
            if($MAJOR) {
                $_major = $_major + 1;
                $_minor = 0;
                $_patch = 0;
                $_build = 0;
            }
            if($MINOR) {
                $_minor = $_minor + 1;
                $_patch = 0;
                $_build = 0;
            }
            if($PATCH) {
                $_patch = $_patch + 1;
                $_build = 0;
            }
            if(-not $MAJOR -and -not $MINOR -and -not $PATCH -and -not [string]::IsNullOrWhiteSpace($BUILD)) {            
                $_build = $BUILD;
            }
            else {
                $_build = 0;
            }
            $version = "$_major.$_minor.$_patch.$_build";
        }
  }
  # replace version where needed
  (Get-Content $info) -replace "(?<=""Version""\:\s*"")([\d]+)([\.]{1}[\d]+)([\.]{1}[\d]+)([\.]{1}[\d]+)*(?="",)", "$version" | Set-Content $info
  #display version inforation to output
  echo "BUMP VERSION TO: $version ($info)";
  $newVersion = $version;
}
if($TAG_AND_PUSH) {
    git pull
    git add package.json
    git commit -m "bump version to $newVersion"
    git push
    git pull
    git tag -a "v$newVersion" -m "v$newVersion"    
    git push origin --tags
}