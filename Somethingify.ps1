#!/usr/bin/env pwsh
<#
.DESCRIPTION
    Somethingify - Ad-Free YouTube Music PowerShell Player
    Stream and download music directly from YouTube (no Spotify API required)
    100% Free, No Ads, No Authentication
    
.AUTHOR
    Shivraj Suman
    
.VERSION
    3.0.0 (Ad-Free)
#>

param()

$CONFIG = @{
    PlaylistDir = "$env:USERPROFILE\Somethingify\playlists"
    CacheDir = "$env:USERPROFILE\Somethingify\cache"
    DownloadDir = "$env:USERPROFILE\Music\Somethingify"
    VLCPath = "C:\Program Files\VideoLAN\VLC\vlc.exe"
}

$global:CurrentTrack = $null
$global:IsPlaying = $false
$global:Playlists = @{}
$global:VLCProcess = $null
$global:SearchCache = @{}

function Initialize-Somethingify {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   SOMETHINGIFY v3.0 - Ad-Free Music" -ForegroundColor Green
    Write-Host "   Free YouTube Streaming" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Checking dependencies..." -ForegroundColor Yellow
    
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] yt-dlp not found!" -ForegroundColor Red
        Write-Host "Install with: pip install yt-dlp" -ForegroundColor Yellow
        Write-Host ""
        exit
    } else {
        Write-Host "[OK] yt-dlp installed" -ForegroundColor Green
    }
    
    @($CONFIG.PlaylistDir, $CONFIG.CacheDir, $CONFIG.DownloadDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    Write-Host "[OK] Directories ready" -ForegroundColor Green
    Write-Host ""
}

function Search-YouTubeMusic {
    param([string]$Query)
    
    Write-Host "Searching YouTube Music..." -ForegroundColor Yellow
    
    try {
        $searchQuery = "$Query audio official"
        $json = yt-dlp -j --flat-playlist "ytsearch10:$searchQuery" 2>$null | ConvertFrom-Json
        return $json
    } catch {
        Write-Host "Search error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Play-Song {
    param([object]$Track)
    
    if (-not $Track) {
        Write-Host "No track selected" -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "Now playing:" -ForegroundColor Green
    Write-Host "Title: $($Track.title)" -ForegroundColor Cyan
    Write-Host "Channel: $($Track.channel)" -ForegroundColor Yellow
    Write-Host "Duration: $($Track.duration) seconds" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "Getting audio URL..." -ForegroundColor Yellow
    $audioUrl = yt-dlp -f best --get-url $Track.url 2>$null
    
    if ($audioUrl) {
        Write-Host "Playing..." -ForegroundColor Green
        if (Test-Path $CONFIG.VLCPath) {
            $global:VLCProcess = Start-Process -FilePath $CONFIG.VLCPath -ArgumentList $audioUrl -PassThru
            Write-Host "VLC is playing (close window to stop)" -ForegroundColor Yellow
            $global:VLCProcess.WaitForExit()
        } else {
            Write-Host "Opening in default player..." -ForegroundColor Yellow
            Start-Process $audioUrl
        }
    } else {
        Write-Host "Failed to get audio" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Download-Song {
    param([object]$Track)
    
    Write-Host ""
    Write-Host "Downloading: $($Track.title)" -ForegroundColor Yellow
    
    $filename = "$($Track.title -replace '[^a-zA-Z0-9 ]', '_').mp3"
    $filepath = Join-Path $CONFIG.DownloadDir $filename
    
    try {
        Write-Host "URL: $($Track.url)" -ForegroundColor Gray
        yt-dlp -f best -x --audio-format mp3 -o "$filepath" $Track.url
        Write-Host "Downloaded to: $filepath" -ForegroundColor Green
    } catch {
        Write-Host "Download failed" -ForegroundColor Red
    }
    Write-Host ""
}

function Create-Playlist {
    param([string]$Name)
    
    $playlistPath = Join-Path $CONFIG.PlaylistDir "$Name.json"
    
    if (Test-Path $playlistPath) {
        Write-Host "Playlist exists" -ForegroundColor Yellow
        return
    }
    
    @{name = $Name; songs = @(); created = (Get-Date)} | ConvertTo-Json | Set-Content $playlistPath
    Write-Host "[OK] Playlist created: $Name" -ForegroundColor Green
}

function Add-ToPlaylist {
    param([string]$PlaylistName, [object]$Track)
    
    $playlistPath = Join-Path $CONFIG.PlaylistDir "$PlaylistName.json"
    
    if (-not (Test-Path $playlistPath)) {
        Write-Host "Playlist not found" -ForegroundColor Red
        return
    }
    
    $playlist = Get-Content $playlistPath | ConvertFrom-Json
    $playlist.songs += @{title = $Track.title; url = $Track.url; channel = $Track.channel}
    $playlist | ConvertTo-Json -Depth 10 | Set-Content $playlistPath
    
    Write-Host "[OK] Added to playlist" -ForegroundColor Green
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Search and play music" -ForegroundColor White
    Write-Host "2. Create playlist" -ForegroundColor White
    Write-Host "3. My playlists" -ForegroundColor White
    Write-Host "4. Exit" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Search-Menu {
    Write-Host ""
    Write-Host "Search YouTube Music:" -ForegroundColor Cyan
    $query = Read-Host "Song name or artist"
    
    if ([string]::IsNullOrEmpty($query)) {
        return
    }
    
    $results = Search-YouTubeMusic -Query $query
    
    if (-not $results) {
        Write-Host "No results found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found results:" -ForegroundColor Green
    Write-Host ""
    
    if ($results -is [array]) {
        for ($i = 0; $i -lt $results.Count; $i++) {
            Write-Host "$($i+1). $($results[$i].title) - $($results[$i].channel)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "1. $($results.title) - $($results.channel)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    $choice = Read-Host "Select (number) or Enter to skip"
    
    if ($choice) {
        if ($results -is [array]) {
            $selected = $results[[int]$choice - 1]
        } else {
            $selected = $results
        }
        
        Write-Host ""
        Write-Host "a) Play  b) Download  c) Add to playlist  d) Back" -ForegroundColor Yellow
        
        $option = Read-Host "Choose"
        
        switch ($option.ToLower()) {
            "a" { Play-Song $selected }
            "b" { Download-Song $selected }
            "c" { 
                $name = Read-Host "Playlist name"
                Add-ToPlaylist $name $selected
            }
        }
    }
}

function Main {
    Initialize-Somethingify
    
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select (1-4)"
        
        switch ($choice) {
            "1" { Search-Menu }
            "2" { 
                $name = Read-Host "Playlist name"
                Create-Playlist $name
            }
            "3" { 
                $playlists = Get-ChildItem $CONFIG.PlaylistDir -Filter "*.json" -ErrorAction SilentlyContinue
                if ($playlists.Count -eq 0) {
                    Write-Host "No playlists" -ForegroundColor Yellow
                } else {
                    $playlists | ForEach-Object {
                        Write-Host "[Playlist] $($_.BaseName)" -ForegroundColor Cyan
                    }
                }
                Write-Host ""
            }
            "4" { 
                Write-Host "Goodbye!" -ForegroundColor Green
                exit
            }
            default { Write-Host "Invalid" -ForegroundColor Red }
        }
    }
}

Main
