$response;
$global:deletedCount = 0;
$global:keepCount = 0;
$global:totalCount = 0;
$global:totalFileSize = 0;

function Show-Available-Inputs($error) {
    write-host $error -foregroundcolor "red"
    write-host "   Parameter 1: Folder Path Location";
    write-host "   Parameter 2: Day of month to not delete file. Otherwise write '$ null' with no spaces";
    write-host "   Parameter 3: File Name Wildcard (ex: .txt). Otherwise write '$ null' with no spaces";
}

function Parse-Command-Line($TheArgs) 
{
    $paramCount = $TheArgs.length;
    
    if($paramCount -lt 3) 
    {
        Show-Available-Inputs "Must pass in parameters:";
    } 
    elseIf ($paramCount -eq 3) 
    {
        ParseDirectory $TheArgs[0] $TheArgs[1] $TheArgs[2];
    } 
    elseIf($paramCount -gt 3)
    {
        Show-Available-Inputs "Too many parameters:";
    }
}

function ParseDirectory($folderLocation, $doNotDeleteFilesOnThisDayOfMonth, $fileNameWildCard)
{
    if (($doNotDeleteFilesOnThisDayOfMonth -is [int]) -or ($doNotDeleteFilesOnThisDayOfMonth -eq $null))
    {
        GetFiles $folderLocation $doNotDeleteFilesOnThisDayOfMonth;
    }
    else
    {
        write-host -NoNewLine "Invalid Value:" -foregroundcolor "red";
        write-host " Day of the month must be an integer";
    }
    UserResponse;
}

function DeleteFile($folderLocation, $fileName, $fileSize)
{
    if ($response -eq "Y")
    {
        $fullFileName = $folderLocation + '\' + $fileName;
        #Remove-Item $fullFileName
        write-host -NoNewLine "DELETED " -foregroundcolor "red";
        write-host $fileName;
    }
    $global:totalFileSize = $global:totalFileSize + $fileSize;
    $global:deletedCount++;
}

function GetFiles($folderLocation, $doNotDeleteFilesOnThisDayOfMonth)
{
    if(Test-Path $folderLocation)
    {
        $currDate = Get-Date;
        $files = Get-ChildItem $folderLocation;
        
        if($files -ne $null)
        {
            foreach($file in $files)
            {
                $fileName = $file.Name;
                $fileLWT = $file.LastWriteTime;
                $fileSize = $file.Length;
                $fileExtension = $file.Extension;
                
                if($fileExtension.Length -eq 0)
                {
                    $subDirectory = $folderLocation + '\' + $fileName;
                    GetFiles $subDirectory $doNotDeleteFilesOnThisDayOfMonth; 
                }
                else
                {
                    if((($fileLWT).Month -lt ($currDate).Month) -and (($fileLWT).Year -le ($currDate).Year))
                    {
                        if ($doNotDeleteFilesOnThisDayOfMonth -eq $null)
                        {
                            if ($fileNameWildCard -eq $null)
                            {
                                DeleteFile $folderLocation $fileName $fileSize;
                            }
                            else
                            {
                                if ($fileExtension -eq $fileNameWildCard)
                                {
                                    DeleteFile $folderLocation $fileName $fileSize;
                                }
                                else
                                {
                                    $global:keepCount++;
                                }
                            }
                        }
                        elseif($doNotDeleteFilesOnThisDayOfMonth -is [int])
                        {
                            if (($fileLWT).Day -ne $doNotDeleteFilesOnThisDayOfMonth)
                            {
                                if ($fileNameWildCard -eq $null)
                                {
                                    DeleteFile $folderLocation $fileName $fileSize;
                                }
                                else
                                {
                                    if ($fileExtension -eq $fileNameWildCard)
                                    {
                                        DeleteFile $folderLocation $fileName $fileSize;
                                    }
                                    else
                                    {
                                        $global:keepCount++;
                                    }
                                }
                            }
                            else
                            {
                                $global:keepCount++;
                            }
                        }
                    }
                    else
                    {
                        $global:keepCount++;
                    }
                    $global:totalCount++;
                }
            }
        }
    }
    else
    {
        write-host -NoNewLine "Error:" -foregroundcolor "red";
        write-host " File Location Does Not Exist";
    }
}


function UserResponse()
{
    $totalFileSizeGB = "{0:N3}" -f ($global:totalFileSize/1GB)

    if ($response -eq "Y")
    {
        write-host "Deleted Files Count =" $global:deletedCount;
        write-host "Deleted Files Size =" $totalFileSizeGB "GB ("$global:totalFileSize "bytes )";
        write-host "";
        $response = $null;
        return;
    }
    else
    {
        write-host "";
        write-host "To be Deleted Files Count ="  $global:deletedCount;
        write-host "To be Deleted Files Size =" $totalFileSizeGB "GB ("$global:totalFileSize "bytes )";
        write-host "Valid Records =" $global:keepCount;
        write-host "-----------------";
        write-host "Total Count =" $global:totalCount;
        write-host "";
        $response = Read-Host 'Proceed with deleteing files? Y/N'
    }

    if ($response -eq "Y")
    {
        $global:deletedCount = 0;
        $global:totalFileSize = 0;
        ParseDirectory $folderLocation $doNotDeleteFilesOnThisDayOfMonth $fileNameWildCard
        write-host "Files have been deleted";
    }
    elseif($response -eq "N")
    {
        write-host "Files not deleted";
    }
    else
    {
        write-host "Invalid Response" -foregroundcolor "red";
    }
}

Parse-Command-Line $args;