<#STEPS TO IMPLEMENT: 

  1. Modify section at top and save to .ps1 on computer that's always on.
  2. Open "Task Scheduler" and create a new basic task. 
  3. Triggers - daily (we'll make it hourly aftewards)
  4. Action - Run a Program 
    - Program: powershell.exe
    - Add arguments: -File "C:\PathToYourPS1\Filename.ps1"
  5. Finish / open properties when done.
  6. Click "Run logged in or not". 
  7. Go to "Actions" and double click your daily action. Set "repeat every X" for more often runs.

  You may want to also verify the BODY payload matches your desired settings, but it should since it's pulling a lot from an existing entry.

#CHANGELOG
  2024-12-18 - v1.0 - Release
#>

#####Change these#####
    $ZONE_ID = "<YOUR ZONE-ID>"
    $CLOUDFLARE_EMAIL = "youremail@domain.com"
    $CLOUDFLARE_API_KEY = "<YOUR API-KEY>"
    $UNIQUEZONEIDENTIFIER = "Something in the NAME of your zone that is unique. Such as a subdomain name like 'homeassist'.domain.com"
####################


#####No need to modify below this line#####
$MYIP = (Invoke-WebRequest ifconfig.me/ip).Content
try{
    # GET DNS RECORDS
        $LISTDNSRECORDS_URI = "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records";
        $params = @{
          Uri     = $LISTDNSRECORDS_URI
          Headers = @{'X-Auth-Email' = "$CLOUDFLARE_EMAIL"; 'X-Auth-Key' = "$CLOUDFLARE_API_KEY"}
        }

        $response = Invoke-WebRequest @params
        $Content = $response.Content | ConvertFrom-Json
        $Content = $content.result

    #Overwrite ZONE NAME zone.
        $UNIQUEZONEIDENTIFIER = $Content | where {$_.name -like "*$UNIQUEZONEIDENTIFIER*"}

        if($UNIQUEZONEIDENTIFIER.content -ne $MYIP){
            $UpdateDateAndTime = Get-Date -Format yyyy-MM-dd-hhmm
            $DNS_RECORD_ID = $UNIQUEZONEIDENTIFIER.id
            $OVERWRITE_URI = "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID";

            $params = @{
              Uri         = $OVERWRITE_URI
              Method      = 'PUT'
              ContentType = 'application/json'
              Headers     = @{'X-Auth-Email' = "$CLOUDFLARE_EMAIL"; 'X-Auth-Key' = "$CLOUDFLARE_API_KEY"}
              Body        = @(
                @{
                "comment" = "Last Updated: $UpdateDateAndTime"
                "content" = $MYIP
                "name" = $UNIQUEZONEIDENTIFIER.name
                "proxied" = $true
                "ttl" = 1
                "type" = "A"
                } | ConvertTo-Json -Depth 10
              )
            }
        
            Write-Host "`n`n - SOURCE IP Address $($UNIQUEZONEIDENTIFIER.content) `n - CURRENT IP ADDRESS $MYIP `n - UPDATE NEEDED. Making update: `n" -fore yellow
            $response = Invoke-WebRequest @params
    
        }
        elseif($UNIQUEZONEIDENTIFIER.content -eq $myip){
            Write-Host "No update needed.`n" -Fore green
            
        }
    
    Write-Host "Success - Verify on DNS Dashboard (note will show updated time)" -Fore green
}
catch{ Write-Host "ERROR $($_.Exception)" -Fore red}
