<#
.SYNOPSIS
	Copy WebView2Loader.dll (Microsoft Edge WebView2 loader) into the folder of the web_browser library.

.DESCRIPTION
	Downloads the NuGet package Microsoft.Web.WebView2 (BSD-3-Clause licence, see LICENSE.txt in the package),
	and copies the WebView2Loader.dll of the selected architecture into -Destination.

	The web_browser library does not need WebView2Loader.dll: without it, the WebView2 Runtime is located from
	the registry. When present next to an executable (or in the PATH), it is used to create the web view.

		Src/library/web_browser/get_webview2_loader.ps1
		Src/library/web_browser/get_webview2_loader.ps1 -Architecture x86 -Version 1.0.4314.35
		Src/library/web_browser/get_webview2_loader.ps1 -Destination C:\temp\EIFGENs\app\W_code

.PARAMETER Architecture
	x64, x86 or arm64. Default: from ISE_PLATFORM (win64: x64, windows: x86, arm64), otherwise x64.

.PARAMETER Version
	Version of the NuGet package Microsoft.Web.WebView2. Default: the latest stable version.

.PARAMETER Destination
	Folder receiving WebView2Loader.dll. Default: the folder of this script (the web_browser library).
#>
param(
	[ValidateSet('x64', 'x86', 'arm64')]
	[string] $Architecture,
	[string] $Version,
	[string] $Destination = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$package = 'microsoft.web.webview2'
$feed = "https://api.nuget.org/v3-flatcontainer/$package"

if (-not $Architecture) {
	$Architecture = switch ($env:ISE_PLATFORM) {
		'windows' { 'x86' }
		{ $_ -like '*arm64*' } { 'arm64' }
		default { 'x64' }
	}
}

if (-not $Version) {
		# Latest version without pre-release suffix.
	$versions = (Invoke-RestMethod "$feed/index.json").versions | Where-Object { $_ -notmatch '-' }
	$Version = $versions | Sort-Object { [version] $_ } | Select-Object -Last 1
}

$work = Join-Path ([IO.Path]::GetTempPath()) ("webview2-" + [guid]::NewGuid())
New-Item -ItemType Directory $work | Out-Null
try {
	$archive = Join-Path $work 'package.zip'
	Write-Host "Downloading $package $Version ..."
	Invoke-WebRequest "$feed/$Version/$package.$Version.nupkg" -OutFile $archive
	$content = Join-Path $work 'content'
	Expand-Archive $archive -DestinationPath $content
	$dll = Join-Path $content "runtimes\win-$Architecture\native\WebView2Loader.dll"
	if (-not (Test-Path $dll)) {
		throw "WebView2Loader.dll for $Architecture not found in $package $Version."
	}
	New-Item -ItemType Directory -Force $Destination | Out-Null
	Copy-Item $dll $Destination -Force
	Write-Host "WebView2Loader.dll ($Architecture, $package $Version) copied to $((Resolve-Path $Destination).Path)"
} finally {
	Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}
