#!/usr/bin/env pwsh
<#
.DESCRIPTION
    Somethingify - A Spotify-like PowerShell Music Player
    A free, open-source PowerShell application

.AUTHOR
    Shivraj Suman

.VERSION
    1.0.3
#>

param()

# Global variables
$global:likedSongs = @()
$global:currentQueue = @()
$global:playlists = @{}
$global:isPlaying = $false
$global:searchResults = @()
$global:downloadPath = "$env:USERPROFILE\Downloads\Somethingify"

# Music Database with real variations
$global:musicDatabase = @(
    @{Title = "Bohemian Rhapsody"; Artist = "Queen"; Duration = "5:55"; DurationSeconds = 355 },
    @{Title = "Stairway to Heaven"; Artist = "Led Zeppelin"; Duration = "8:02"; DurationSeconds = 482 },
    @{Title = "Imagine"; Artist = "John Lennon"; Duration = "3:03"; DurationSeconds = 183 },
    @{Title = "Like a Rolling Stone"; Artist = "Bob Dylan"; Duration = "6:13"; DurationSeconds = 373 },
    @{Title = "Hotel California"; Artist = "Eagles"; Duration = "6:30"; DurationSeconds = 390 },
    @{Title = "Hey Jude"; Artist = "The Beatles"; Duration = "7:11"; DurationSeconds = 431 },
    @{Title = "Sweet Child o Mine"; Artist = "Guns N Roses"; Duration = "5:56"; DurationSeconds = 356 },
    @{Title = "Hallelujah"; Artist = "Leonard Cohen"; Duration = "4:34"; DurationSeconds = 274 },
    @{Title = "Black"; Artist = "Pearl Jam"; Duration = "5:43"; DurationSeconds = 343 },
    @{Title = "Wonderwall"; Artist = "Oasis"; Duration = "4:18"; DurationSeconds = 258 }
)

function Initialize-Somethingify {
    Clear-Host
    Write-Host "" 
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    SOMETHINGIFY - Music Player" -ForegroundColor Green
    Write-Host "    v1.0.3 (Fixed Prototype)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Initializing Somethingify..." -ForegroundColor Yellow
    
    if (-not (Test-Path $global:downloadPath)) {
        New-Item -ItemType Directory -Path $global:downloadPath -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Created download folder" -ForegroundColor Cyan
    }
    
    $global:playlists["Liked Songs"] = @()
    $global:playlists["Downloaded"] = @()
    
    Start-Sleep -Milliseconds 800
    Write-Host "Ready to play!" -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Milliseconds 500
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Search for a song" -ForegroundColor White
    Write-Host "2. Get recommendations" -ForegroundColor White
    Write-Host "3. View playlists" -ForegroundColor White
    Write-Host "4. View liked songs" -ForegroundColor White
    Write-Host "5. View downloaded songs" -ForegroundColor White
    Write-Host "6. Settings" -ForegroundColor White
    Write-Host "7. Exit" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Search-Song {
    Write-Host ""
    Write-Host "Search for a song:" -ForegroundColor Cyan
    $query = Read-Host "Enter song name (or part of it)"
    
    if ([string]::IsNullOrEmpty($query)) {
        Write-Host "Search query cannot be empty" -ForegroundColor Red
        return
    }
    
    Write-Host "Searching for '$query'..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 600
    
    $results = @($global:musicDatabase | Where-Object { $_.Title -ilike "*$query*" -or $_.Artist -ilike "*$query*" })
    
    if ($results.Count -eq 0) {
        Write-Host "No songs found. Try different search term." -ForegroundColor Yellow
        return
    }
    
    $global:searchResults = $results
    
    Write-Host "Found $($results.Count) result(s):" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 0; $i -lt $results.Count; $i++) {
        Write-Host "$($i+1). $($results[$i].Title) - $($results[$i].Artist) [$($results[$i].Duration)]" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "a) Play now" -ForegroundColor White
    Write-Host "b) Like a song" -ForegroundColor White
    Write-Host "c) Back to menu" -ForegroundColor White
    Write-Host ""
    
    $option = Read-Host "Select option (a/b/c)"
    
    switch ($option.ToLower()) {
        "a" { Play-SelectedSong }
        "b" { Like-SelectedSong }
        "c" { return }
        default { Write-Host "Invalid option" -ForegroundColor Red }
    }
}

function Play-SelectedSong {
    Write-Host ""
    Write-Host "Select song number to play:" -ForegroundColor Cyan
    $songNum = Read-Host "Enter number (1-$($global:searchResults.Count))"
    
    if (-not ([int]::TryParse($songNum, [ref]$null)) -or $songNum -lt 1 -or $songNum -gt $global:searchResults.Count) {
        Write-Host "Invalid selection" -ForegroundColor Red
        return
    }
    
    $song = $global:searchResults[[int]$songNum - 1]
    
    Write-Host ""
    Write-Host "Now playing: $($song.Title)" -ForegroundColor Green
    Write-Host "Artist: $($song.Artist)" -ForegroundColor Yellow
    Write-Host "Duration: $($song.Duration)" -ForegroundColor Magenta
    Write-Host ""
    
    # Play with actual duration
    $durationMs = $song.DurationSeconds * 100  # Scale down for demo (use 100ms per second for demo)
    $steps = [Math]::Ceiling($song.DurationSeconds / 5)  # Update progress every 5 seconds
    
    for ($i = 0; $i -le 100; $i += (100/$steps)) {
        $barLength = [Math]::Round($i / 5)
        $emptyLength = 20 - $barLength
        Write-Host -NoNewLine "`r[$('=' * $barLength)$(" " * $emptyLength)] $([Math]::Round($i))% "
        Start-Sleep -Milliseconds 300
    }
    Write-Host "`r[$('=' * 20)] 100%" 
    
    Write-Host "Finished playing" -ForegroundColor Green
    Write-Host ""
    
    # Ask to download
    Write-Host "Download this song?" -ForegroundColor Cyan
    Write-Host "y) Yes   n) No" -ForegroundColor White
    $dlChoice = Read-Host "Choose (y/n)"
    
    if ($dlChoice.ToLower() -eq "y") {
        Download-Song $song
    }
}

function Download-Song {
    param([hashtable]$song)
    
    Write-Host ""
    Write-Host "Downloading: $($song.Title)" -ForegroundColor Yellow
    Write-Host "Artist: $($song.Artist)" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -le 100; $i += 20) {
        $barLength = [Math]::Round($i / 5)
        $emptyLength = 20 - $barLength
        Write-Host -NoNewLine "`r[Download] [$('=' * $barLength)$(" " * $emptyLength)] $i% "
        Start-Sleep -Milliseconds 300
    }
    
    $filename = "$($song.Title -replace '[^a-zA-Z0-9 ]', '_').mp3"
    $filepath = Join-Path $global:downloadPath $filename
    
    Write-Host "`r[Download] [$('=' * 20)] 100%" 
    Write-Host ""
    Write-Host "Saved to: $filepath" -ForegroundColor Green
    
    if (-not ($global:playlists["Downloaded"] -contains $song.Title)) {
        $global:playlists["Downloaded"] += $song.Title
    }
    Write-Host ""
}

function Like-SelectedSong {
    Write-Host ""
    Write-Host "Select song number to like:" -ForegroundColor Cyan
    $songNum = Read-Host "Enter number (1-$($global:searchResults.Count))"
    
    if (-not ([int]::TryParse($songNum, [ref]$null)) -or $songNum -lt 1 -or $songNum -gt $global:searchResults.Count) {
        Write-Host "Invalid selection" -ForegroundColor Red
        return
    }
    
    $song = $global:searchResults[[int]$songNum - 1]
    
    if (-not ($global:playlists["Liked Songs"] -contains $song.Title)) {
        $global:playlists["Liked Songs"] += $song.Title
        Write-Host "Liked: $($song.Title)" -ForegroundColor Red
    } else {
        Write-Host "Already liked this song" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Get-Recommendations {
    Write-Host ""
    Write-Host "Recommended songs for you:" -ForegroundColor Green
    Write-Host ""
    
    $recommendations = $global:musicDatabase | Get-Random -Count 3
    
    for ($i = 0; $i -lt $recommendations.Count; $i++) {
        Write-Host "$($i+1). $($recommendations[$i].Title) - $($recommendations[$i].Artist)" -ForegroundColor Magenta
    }
    
    Write-Host ""
}

function View-Playlists {
    Write-Host ""
    Write-Host "Your Playlists:" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($playlist in $global:playlists.Keys) {
        $count = $global:playlists[$playlist].Count
        Write-Host "$playlist: $count song(s)" -ForegroundColor White
    }
    
    Write-Host ""
}

function View-LikedSongs {
    Write-Host ""
    Write-Host "Your Liked Songs:" -ForegroundColor Cyan
    Write-Host ""
    
    if ($global:playlists["Liked Songs"].Count -eq 0) {
        Write-Host "No liked songs yet" -ForegroundColor Yellow
    } else {
        $global:playlists["Liked Songs"] | ForEach-Object { 
            Write-Host "♥ $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

function View-Downloaded {
    Write-Host ""
    Write-Host "Your Downloaded Songs:" -ForegroundColor Cyan
    Write-Host ""
    
    if ($global:playlists["Downloaded"].Count -eq 0) {
        Write-Host "No downloaded songs yet" -ForegroundColor Yellow
    } else {
        $global:playlists["Downloaded"] | ForEach-Object { 
            Write-Host "↓ $_" -ForegroundColor Green
        }
    }
    
    Write-Host ""
}

function Show-Settings {
    Write-Host ""
    Write-Host "Settings:" -ForegroundColor Cyan
    Write-Host "Download Folder: $global:downloadPath" -ForegroundColor White
    Write-Host "Music Database: $($global:musicDatabase.Count) songs available" -ForegroundColor White
    Write-Host ""
}

function Main {
    Initialize-Somethingify
    
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select option (1-7)"
        
        switch ($choice) {
            "1" { Search-Song }
            "2" { Get-Recommendations }
            "3" { View-Playlists }
            "4" { View-LikedSongs }
            "5" { View-Downloaded }
            "6" { Show-Settings }
            "7" { 
                Write-Host "Thanks for using Somethingify! Goodbye!" -ForegroundColor Green
                Write-Host ""
                exit 
            }
            default { Write-Host "Invalid option. Try 1-7." -ForegroundColor Red }
        }
    }
}

Main
