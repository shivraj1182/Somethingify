#!/usr/bin/env pwsh
<#
.DESCRIPTION
    Somethingify - Real PowerShell Spotify Clone
    Uses Spotify API for metadata and yt-dlp for audio streaming
    
.AUTHOR
    Shivraj Suman
    
.VERSION
    2.0.0-beta (Real Implementation)
#>

param()

# ==================== CONFIG ====================
$CONFIG = @{
    SpotifyClientId = "YOUR_SPOTIFY_CLIENT_ID"
    SpotifyClientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
    PlaylistDir = "$env:USERPROFILE\Somethingify\playlists"
    CacheDir = "$env:USERPROFILE\Somethingify\cache"
    DownloadDir = "$env:USERPROFILE\Music\Somethingify"
    VLCPath = "C:\Program Files\VideoLAN\VLC\vlc.exe"
}

# ==================== GLOBAL VARIABLES ====================
$global:CurrentTrack = $null
$global:IsPlaying = $false
$global:Playlists = @{}
$global:SpotifyToken = $null
$global:VLCProcess = $null

# ==================== INITIALIZATION ====================
function Initialize-Somethingify {
    Clear-Host
    Write-Host "" 
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   SOMETHINGIFY - Real Spotify Clone" -ForegroundColor Green
    Write-Host "   v2.0.0-beta" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check dependencies
    Write-Host "Checking dependencies..." -ForegroundColor Yellow
    
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️  yt-dlp not found. Install with: pip install yt-dlp" -ForegroundColor Red
        Write-Host "Without yt-dlp, audio streaming won't work." -ForegroundColor Yellow
    } else {
        Write-Host "✓ yt-dlp installed" -ForegroundColor Green
    }
    
    if (-not (Test-Path $CONFIG.VLCPath)) {
        Write-Host "⚠️  VLC not found. Install from: https://www.videolan.org/" -ForegroundColor Red
        Write-Host "Without VLC, playback won't work." -ForegroundColor Yellow
    } else {
        Write-Host "✓ VLC installed" -ForegroundColor Green
    }
    
    # Create directories
    @($CONFIG.PlaylistDir, $CONFIG.CacheDir, $CONFIG.DownloadDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    Write-Host "✓ Directories initialized" -ForegroundColor Green
    Write-Host ""
    Write-Host "SETUP REQUIRED:" -ForegroundColor Cyan
    Write-Host "1. Get Spotify API credentials from: https://developer.spotify.com" -ForegroundColor White
    Write-Host "2. Run: Set-SpotifyCredentials" -ForegroundColor White
    Write-Host ""
    Start-Sleep -Milliseconds 1000
}

# ==================== SPOTIFY API ====================
function Set-SpotifyCredentials {
    Write-Host ""
    Write-Host "Enter your Spotify API credentials:" -ForegroundColor Cyan
    $clientId = Read-Host "Client ID"
    $clientSecret = Read-Host "Client Secret" -AsSecureString
    
    $CONFIG.SpotifyClientId = $clientId
    $CONFIG.SpotifyClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($clientSecret))
    
    # Get token
    Get-SpotifyToken
    Write-Host "✓ Credentials saved" -ForegroundColor Green
    Write-Host ""
}

function Get-SpotifyToken {
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($CONFIG.SpotifyClientId):$($CONFIG.SpotifyClientSecret)"))
    
    try {
        $response = Invoke-RestMethod -Uri "https://accounts.spotify.com/api/token" `
            -Method POST `
            -Headers @{Authorization = "Basic $auth"} `
            -Body @{grant_type = "client_credentials"} `
            -ErrorAction Stop
        
        $global:SpotifyToken = $response.access_token
        return $true
    } catch {
        Write-Host "✗ Failed to get Spotify token" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Search-Spotify {
    param([string]$Query, [string]$Type = "track")
    
    if (-not $global:SpotifyToken) {
        Write-Host "Please configure Spotify credentials first" -ForegroundColor Red
        return $null
    }
    
    try {
        $uri = "https://api.spotify.com/v1/search?q=$([uri]::EscapeDataString($Query))&type=$Type&limit=10"
        $response = Invoke-RestMethod -Uri $uri `
            -Headers @{Authorization = "Bearer $($global:SpotifyToken)"} `
            -ErrorAction Stop
        
        return $response.tracks.items
    } catch {
        Write-Host "Search failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ==================== AUDIO STREAMING ====================
function Get-AudioURL {
    param([string]$SongTitle, [string]$Artist)
    
    Write-Host "Fetching audio URL..." -ForegroundColor Yellow
    
    try {
        $searchQuery = "$SongTitle $Artist audio"
        $url = (yt-dlp -f best --get-url "ytsearch:$searchQuery" 2>$null | Select-Object -First 1)
        return $url
    } catch {
        Write-Host "Failed to get audio URL" -ForegroundColor Red
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
    Write-Host "Title: $($Track.name)" -ForegroundColor Cyan
    Write-Host "Artist: $($Track.artists[0].name)" -ForegroundColor Yellow
    Write-Host "Album: $($Track.album.name)" -ForegroundColor Magenta
    Write-Host "Popularity: $($Track.popularity)/100" -ForegroundColor White
    Write-Host ""
    
    $audioUrl = Get-AudioURL -SongTitle $Track.name -Artist $Track.artists[0].name
    
    if ($audioUrl) {
        Write-Host "Playing audio..." -ForegroundColor Green
        # Start VLC with URL
        if (Test-Path $CONFIG.VLCPath) {
            $global:VLCProcess = Start-Process -FilePath $CONFIG.VLCPath -ArgumentList $audioUrl -PassThru
            Write-Host "Press any key to stop..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Stop-Process -Id $global:VLCProcess.Id -ErrorAction SilentlyContinue
        } else {
            Write-Host "VLC not found. Install VLC to play audio." -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

function Download-Song {
    param([object]$Track)
    
    Write-Host "Downloading..." -ForegroundColor Yellow
    $filename = "$($Track.artists[0].name) - $($Track.name).mp3"
    $filepath = Join-Path $CONFIG.DownloadDir $filename
    
    try {
        yt-dlp -f best -o "$filepath" "ytsearch:$($Track.name) $($Track.artists[0].name)"
        Write-Host "Downloaded to: $filepath" -ForegroundColor Green
    } catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ==================== PLAYLISTS ====================
function Create-Playlist {
    param([string]$Name)
    
    $playlistPath = Join-Path $CONFIG.PlaylistDir "$Name.json"
    
    if (Test-Path $playlistPath) {
        Write-Host "Playlist already exists" -ForegroundColor Yellow
        return
    }
    
    @{name = $Name; songs = @(); created = (Get-Date)} | ConvertTo-Json | Set-Content $playlistPath
    Write-Host "✓ Playlist created: $Name" -ForegroundColor Green
}

function Add-ToPlaylist {
    param([string]$PlaylistName, [object]$Track)
    
    $playlistPath = Join-Path $CONFIG.PlaylistDir "$PlaylistName.json"
    
    if (-not (Test-Path $playlistPath)) {
        Write-Host "Playlist not found" -ForegroundColor Red
        return
    }
    
    $playlist = Get-Content $playlistPath | ConvertFrom-Json
    $playlist.songs += $Track
    $playlist | ConvertTo-Json -Depth 10 | Set-Content $playlistPath
    
    Write-Host "✓ Added to playlist" -ForegroundColor Green
}

# ==================== MAIN MENU ====================
function Show-MainMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Search songs" -ForegroundColor White
    Write-Host "2. Create playlist" -ForegroundColor White
    Write-Host "3. My playlists" -ForegroundColor White
    Write-Host "4. Settings" -ForegroundColor White
    Write-Host "5. Exit" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Search-Menu {
    Write-Host ""
    Write-Host "Search on Spotify:" -ForegroundColor Cyan
    $query = Read-Host "Enter song name or artist"
    
    if ([string]::IsNullOrEmpty($query)) {
        return
    }
    
    Write-Host "Searching..." -ForegroundColor Yellow
    $results = Search-Spotify -Query $query
    
    if (-not $results) {
        Write-Host "No results found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found $($results.Count) tracks:" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 0; $i -lt $results.Count; $i++) {
        Write-Host "$($i+1). $($results[$i].name) - $($results[$i].artists[0].name)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    $choice = Read-Host "Select track (number) or press Enter to skip"
    
    if ($choice -and $choice -ge 1 -and $choice -le $results.Count) {
        $selected = $results[[int]$choice - 1]
        
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "a) Play" -ForegroundColor White
        Write-Host "b) Download" -ForegroundColor White
        Write-Host "c) Add to playlist" -ForegroundColor White
        Write-Host "d) Back" -ForegroundColor White
        
        $option = Read-Host "Choose (a/b/c/d)"
        
        switch ($option.ToLower()) {
            "a" { Play-Song $selected }
            "b" { Download-Song $selected }
            "c" { 
                $playlistName = Read-Host "Playlist name"
                Add-ToPlaylist $playlistName $selected
            }
        }
    }
}

function Main {
    Initialize-Somethingify
    
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select option (1-5)"
        
        switch ($choice) {
            "1" { Search-Menu }
            "2" { 
                $name = Read-Host "Playlist name"
                Create-Playlist $name
            }
            "3" { 
                Get-ChildItem $CONFIG.PlaylistDir -Filter "*.json" | ForEach-Object {
                    Write-Host "• $($_.BaseName)" -ForegroundColor Cyan
                }
            }
            "4" { Set-SpotifyCredentials }
            "5" { 
                Write-Host "Goodbye!" -ForegroundColor Green
                exit
            }
            default { Write-Host "Invalid option" -ForegroundColor Red }
        }
    }
}

Main
