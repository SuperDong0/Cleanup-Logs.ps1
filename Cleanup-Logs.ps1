<#
.NOTES
	Name: Cleanup-Logs.ps1.ps1
	Original Author: Stanislav Buldakov
    contributor: Stanislav Buldakov
	Requires: PowerShell 4.0 and .Net Framework 4.5
	Version History:
	07/06/2017 - Initial Public Release.
.SYNOPSIS
	Finds log-files in local server folders, compress them, and move to archive folder.
.DESCRIPTION
	This script finds log-files older than some date in list of folders offered by user.
	Log-files can be compressed and moved to some local or network folder.
	Log-files can be deleted without archiving.
.PARAMETER workFolder
	This optional parameter allows point out work folder that contains Folders.txt file with list of folder to archive. Default value is "C:\Scripts\CleanLogFiles".
.PARAMETER timeLimit
	This optional parameter allows specify retention period for log-files. Default time limit is 90 days.
.PARAMETER Archive
	This optional parameter allows specify should script move compressed log-files to archive. Default value is $true, files should be moved.
.PARAMETER archiveFolder
	This optional parameter allows point out target folder that contains compressed log-files. Default value is "C:\Scripts\CleanLogFiles\Archive".
.PARAMETER DeleteFiles
	This optional parameter allows specify should script delete compressed log-files to archive. Default value is $true, files should be deleted.
.EXAMPLE
	.\Cleanup-Logs.ps1
	Finds list of folders for archiving in file C:\Scripts\CleanLogFiles\Folders.txt, finds in these folders log-files older than 90 days, compress them, move compressed 
	files to folder C:\Scripts\CleanLogFiles\Archive and deletes them.
.EXAMPLE
	.\Cleanup-Logs.ps1 -timeLimit 60 -archiveFolder \\server\LogArchive\servername
	Finds list of folders for archiving in file C:\Scripts\CleanLogFiles\Folders.txt, finds in these folders log-files older than 60 days, compress them, move compressed 
	files to network folder \\server\LogArchive\servername and deletes them.
.LINK
    https://www.buldakov.ru
#>
param (
	[string] $workFolder = "C:\Scripts\CleanLogFiles",
	[double] $timeLimit = 90,
	[bool] $Archive = $true,
	[string] $archiveFolder = "C:\Scripts\CleanLogFiles\Archive",
	[bool] $DeleteFiles = $true
)

[datetime] $dateLimit = (Get-Date).AddDays(-$timeLimit)
[string] $logPath = $workFolder
[string] $logName = "CleanupLogs.log"
[string] $folderList = [system.IO.path]::Combine($workFolder, "Folders.txt")
[array] $folders = Get-Content $folderList
[int] $logSize = 1mb * 10

function Write-Log
{
	[CmdletBinding()] param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)] $entries,
		[string] $logFilePath = [system.IO.path]::Combine($logPath, $logName)
	)
	
	process {
		foreach ($entry in $entries) {
			"$(Get-Date -Format 'yyyy.MM.dd HH:mm:ss')`t$entry" | Out-File -Append -FilePath $logFilePath
		}
	}
}

function Create-Folder ($destination)
{
	try
	{
		New-Item -Path $destination -ItemType Directory -ErrorAction Stop
		"[INFO] $destination folder was created" | Write-Log
	}
	catch
	{
		"[ERROR] $destination folder was not created", $_.Exception.Message | Write-Log
	}
}

function Move-ToArchive ($files, $destination)
{
	foreach ($file in $files)
	{
		try
		{
			Move-Item $file.FullName -Destination $destination -Force -ErrorAction Stop
			"[INFO] File $($file.FullName) was moved to folder $destination" | Write-Log
		}
		catch
		{
			"[ERROR] File $($file.FullName) was not moved to folder $destination", $_.Exception.Message | Write-Log
		}		
	}
}

function Delete-File ($files)
{
	foreach ($file in $files)
	{
		try
		{
			Remove-Item -Path $file.FullName -Force -ErrorAction Stop
			"[INFO] File $($file.FullName) was removed" | Write-Log 
		}
		catch
		{
			"[ERROR] File $($file.FullName) was not removed", $_.Exception.Message | Write-Log 
		}
	}
}

function Compress-File ($files)
{
	Add-Type -AssemblyName System.IO.Compression
	Add-Type -AssemblyName System.IO.Compression.FileSystem

	foreach ($file in $files)
	{
		try 
		{
			[string] $zipFileName = $file.FullName + ".zip"
			[System.IO.Compression.ZipArchive] $zipFile = [System.IO.Compression.ZipFile]::Open($zipFileName, ([System.IO.Compression.ZipArchiveMode]::Create))
			[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipFile, $file.FullName, (Split-Path $file.FullName -Leaf))
			$zipFile.Dispose()
			"[INFO] Log file $($file.FullName) was compressed to $zipFileName" | Write-Log
		}
		catch
		{
			"[ERROR] Log file $($file.FullName) was not compressed to $zipFileName", $_.Exception.Message | Write-Log
		}
	}
}

function Rotate-Log
{
	param (
		[string] $logFilePath 	= $logPath,
		[string] $logFileName 	= $logName,
		[int]	 $logSizeParam 	= $logSize
	)
	
	if (!(Test-Path -Path $logFilePath -PathType Container)) 
	{
		[void] (New-Item -Path $logFilePath -ItemType Container)
	}
	else 
	{
		$logFile = Get-ChildItem -Path $logFilePath -Filter $logFileName | where {$_.Length -gt $logSizeParam}
		if ($logfile) 
		{
			try 
			{
				$fileToCompress = (Rename-Item -LiteralPath $logFile.fullName -PassThru -ErrorAction Stop -NewName ($logFileName.replace('.log',"[$(Get-Date -Format 'yyyyMMddHHmm')].log"))).fullName
				$fileToCompress = Get-ChildItem -LiteralPath $fileToCompress -File
				Compress-File -files $fileToCompress
				$fileToCompress | Remove-Item -Force
				"[INFO] Log file $($fileToCompress.FullName) was removed" | Write-Log
			}
			catch 
			{
				"[ERROR] Unable to rename log file", $_.Exception.Message | Write-Log
			}
		}
		Get-ChildItem -Path $logFilePath -Filter '*.zip' -File | where {$_.lastWriteTime -le (Get-Date).AddMonths(-2)} | Remove-Item
	}
}

cls

Rotate-Log

"[INFO] Script started" | Write-Log

foreach ($folder in $folders)
{
	#Test existance of folder with logs
	if (Test-Path $folder)
	{
		#Get list of files in folder older than date limit
		$files = Get-ChildItem -Path $folder -File | ? {$_.LastWriteTime -lt $dateLimit}
		"[INFO] Found $($files.Count) files for processing in $folder" | Write-Log 
		
		if ($Archive)
		{
			if (!(Test-Path -Path $destinationFolder -PathType Container))
			{
				Create-Folder -destination $destinationFolder
			}
			Compress-File -files $files
			$compressedFiles = Get-ChildItem -Path $folder -Filter '*.zip' -File
			#Calculate target folder for archiving. If older is not exists
			$targetFolder = Get-Item -Path $folder
			$destinationFolder = $archiveFolder + '\' + $targetFolder.BaseName
			Move-ToArchive -files $compressedFiles -destination $destinationFolder
		}
		
		if ($DeleteFiles)
		{
			Delete-File -files $files
		}
	}
	else
	{
		"[WARNING] Folder $folder does not exists" | Write-Log
	}
}

"[INFO] Script finished", ("-" * 80) | Write-Log