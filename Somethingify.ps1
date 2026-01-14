#!/usr/bin/env pwsh
<#
.DESCRIPTION
    Somethingify - A Spotify-like PowerShell Music Player
    A free, open-source PowerShell application that brings Spotify-like
    features to your terminal.

.AUTHOR
    Shivraj Suman

.VERSION
    1.0.0
#>

param()

# Initialize global variables
$global:likedSongs = @()
$global:currentQueue = @()
$global:playlists = @{}
$global:currentPlaylist = $null
$global:isPlaying = $false

function Initialize-Somethingify {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    SOMETHINGIFY - Music Player" -ForegroundColor Green
    Write-Host "    v1.0.0" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Loading Somethingify... Please wait." -ForegroundColor Yellow
    
    # Initialize default playlists
    $global:playlists["Liked Songs"] = @()
    $global:playlists["Recently Played"] = @()
    
    Start-Sleep -Milliseconds 500
    Write-Host "Ready to play!" -ForegroundColor Green
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Search for a song" -ForegroundColor White
    Write-Host "2. Get recommendations" -ForegroundColor White
    Write-Host "3. Create a playlist" -ForegroundColor White
    Write-Host "4. View liked songs" -ForegroundColor White
    Write-Host "5. Play queue" -ForegroundColor White
    Write-Host "6. View playlists" -ForegroundColor White
    Write-Host "7. Settings" -ForegroundColor White
    Write-Host "8. Exit" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Search-Song {
    Write-Host "" 
    Write-Host "Search for a song:" -ForegroundColor Cyan
    $query = Read-Host "Enter song name"
    
    if ([string]::IsNullOrEmpty($query)) {
        Write-Host "Search query cannot be empty" -ForegroundColor Red
        return
    }
    
    Write-Host "Searching for '$query'..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 800
    
    # Simulated search results
    $searchResults = @(
        @{Title = "$query (Original Mix)"; Artist = "Various Artists"; Duration = "3:45" },
        @{Title = "$query (Remix)"; Artist = "Various Artists"; Duration = "4:20" },
        @{Title = "$query Cover"; Artist = "Various Artists"; Duration = "3:55" }
    )
    
    Write-Host "Found $($searchResults.Count) results:" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 0; $i -lt $searchResults.Count; $i++) {
        Write-Host "$($i+1). $($searchResults[$i].Title) - $($searchResults[$i].Artist) [$($searchResults[$i].Duration)]" -ForegroundColor Cyan
    }
    
    Write-Host ""
}

function Get-Recommendations {
    Write-Host ""
    Write-Host "Getting personalized recommendations..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 1000
    
    $recommendations = @(
        @{Title = "Amazing Song"; Artist = "Great Artist"; Genre = "Pop" },
        @{Title = "Fantastic Track"; Artist = "Cool Band"; Genre = "Rock" },
        @{Title = "Epic Music"; Artist = "Top Producer"; Genre = "Electronic" }
    )
    
    Write-Host "Based on your listening habits, we recommend:" -ForegroundColor Green
    Write-Host ""
    
    foreach ($rec in $recommendations) {
        Write-Host "♪ $($rec.Title) by $($rec.Artist) [$($rec.Genre)]" -ForegroundColor Magenta
    }
    
    Write-Host ""
}

function Create-Playlist {
    Write-Host ""
    Write-Host "Create a new playlist:" -ForegroundColor Cyan
    $playlistName = Read-Host "Enter playlist name"
    
    if ([string]::IsNullOrEmpty($playlistName)) {
        Write-Host "Playlist name cannot be empty" -ForegroundColor Red
        return
    }
    
    if ($global:playlists.ContainsKey($playlistName)) {
        Write-Host "Playlist '$playlistName' already exists" -ForegroundColor Yellow
        return
    }
    
    $global:playlists[$playlistName] = @()
    Write-Host "Playlist '$playlistName' created successfully!" -ForegroundColor Green
    Write-Host ""
}

function View-LikedSongs {
    Write-Host ""
    Write-Host "Your Liked Songs:" -ForegroundColor Cyan
    
    $likedSongs = $global:playlists["Liked Songs"]
    
    if ($likedSongs.Count -eq 0) {
        Write-Host "No liked songs yet. Start liking songs to build your collection!" -ForegroundColor Yellow
    } else {
        $likedSongs | ForEach-Object { Write-Host "♥ $_" -ForegroundColor Red }
    }
    
    Write-Host ""
}

function Play-Queue {
    Write-Host ""
    Write-Host "Playing queue..." -ForegroundColor Cyan
    
    if ($global:currentQueue.Count -eq 0) {
        Write-Host "Queue is empty. Add some songs first!" -ForegroundColor Yellow
        return
    }
    
    $global:isPlaying = $true
    
    foreach ($song in $global:currentQueue) {
        Write-Host "Now playing: $song" -ForegroundColor Green
        Write-Host "[====================] 100%" -ForegroundColor Cyan
        Start-Sleep -Milliseconds 1500
    }
    
    $global:isPlaying = $false
    Write-Host "Finished playing queue" -ForegroundColor Green
    Write-Host ""
}

function View-Playlists {
    Write-Host ""
    Write-Host "Your Playlists:" -ForegroundColor Cyan
    
    if ($global:playlists.Count -eq 0) {
        Write-Host "No playlists yet. Create one!" -ForegroundColor Yellow
    } else {
        $i = 1
        foreach ($playlistName in $global:playlists.Keys) {
            $songCount = $global:playlists[$playlistName].Count
            Write-Host "$i. $playlistName ($songCount songs)" -ForegroundColor Cyan
            $i++
        }
    }
    
    Write-Host ""
}

function Show-Settings {
    Write-Host ""
    Write-Host "Settings:" -ForegroundColor Cyan
    Write-Host "1. Volume Control" -ForegroundColor White
    Write-Host "2. Audio Quality" -ForegroundColor White
    Write-Host "3. Theme" -ForegroundColor White
    Write-Host "4. Back" -ForegroundColor White
    Write-Host ""
}

function Main {
    Initialize-Somethingify
    
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Select an option (1-8)"
        
        switch ($choice) {
            "1" { Search-Song }
            "2" { Get-Recommendations }
            "3" { Create-Playlist }
            "4" { View-LikedSongs }
            "5" { Play-Queue }
            "6" { View-Playlists }
            "7" { Show-Settings }
            "8" { 
                Write-Host "Thanks for using Somethingify! Goodbye!" -ForegroundColor Green
                exit 
            }
            default { Write-Host "Invalid option. Please select 1-8." -ForegroundColor Red }
        }
    }
}

# Run the main application
Main
