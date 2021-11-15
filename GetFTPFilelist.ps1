# Function to get directory listing 
Function Get-FTPFileList { 
    Param (
        [System.Uri]$server,
        [string]$username,
        [string]$password,
        [string]$directory,
        [switch]$show
    )
    
    TRY {
        $uri =  "$server$directory"                                                                 #Create URI by joining server name and directory path
        $FTPRequest = [System.Net.FtpWebRequest]::Create($uri)                                      #Create an instance of FtpWebRequest
        $FTPRequest.Credentials = New-Object System.Net.NetworkCredential($username, $password)     #Set the username and password credentials for authentication
        $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails               #Set method to ListDirectoryDetails to get full list
                                                                                                    #For short listing change ListDirectoryDetails to ListDirectory
        $FTPResponse = $FTPRequest.GetResponse()                                                    #Get FTP response
        $ResponseStream = $FTPResponse.GetResponseStream()                                          #Get Reponse data stream
        $StreamReader = New-Object System.IO.StreamReader $ResponseStream                           #Read data Stream
        $files = New-Object System.Collections.ArrayList                                            #Read each line of the stream and add it to an array list
        While ($file = $StreamReader.ReadLine())
        {
            [void] $files.add("$file")
        }
    }
    catch {
        #Show error message if any
        write-host -message $_.Exception.InnerException.Message
    }
        #Close the stream and response
        IF (-not [string]::IsNullOrEmpty($StreamReader)) {
            $StreamReader.close()   #| Out-Null
        }
        $ResponseStream.close() #| Out-Null
        $FTPResponse.Close()   # | Out-Null

        [array]$objs = $null
        ForEach ($file in $files) {
            
            IF ($show.IsPresent) {
                Write-Host $file -ForegroundColor Yellow
            }

            SWITCH ($file) {
                {$_.startsWith("d")} {$Type = "Directory"}
                Default {$Type = "File"}
            }
            
            $obj = $null
            $Size = $null

            $Param = @{
                Type        = $Type
                Name        = ($file -split " ")[-1]
                Directory   = $uri
                FullName    = $uri+"/"+$(($file -split " ")[-1])
                Size        = $null
            }
            $obj = New-Object -TypeName psobject -Property $param
            IF ($show.IsPresent) {
                write-host $obj -ForegroundColor Magenta
            }
            
            ## GET SIZE OFF FTP FILE IF NOT OF TYPE DIRECTORY
            IF (($obj.Type -ne "Directory") -and (-not [string]::IsNullOrEmpty($obj.name)) ) {
                $FTPSizeRequest = [System.Net.FtpWebRequest]::Create($obj.FullName)
                $FTPSizeRequest.Credentials = New-Object System.Net.NetworkCredential($username, $password)
                $FTPSizeRequest.Method = [System.Net.WebRequestMethods+Ftp]::GetFileSize
                IF (-not [string]::IsNullOrEmpty($FTPSizeRequest)) {
                    $FTPSizeResponse = $FTPSizeRequest.GetResponse() 
                    ($Size = $FTPSizeResponse.ContentLength) | out-null
                    $FTPSizeResponse.Dispose()
                }
                
                IF($show.IsPresent) {
                    write-host $Size -ForegroundColor Blue
                }
                
                $obj.size = $Size
            }
            $objs += $obj
        }
        $objs
}
