$pluginPath = "$env:APPDATA\..\Local\Pub\Cache\hosted\pub.dev\flutter_keyboard_visibility-5.4.1\android"
$patchPath = "flutter_keyboard_visibility_patch.gradle"

# Check if plugin directory exists
if (Test-Path $pluginPath) {
    Write-Host "Found plugin at $pluginPath"
    
    # Backup the original file
    Copy-Item "$pluginPath\build.gradle" "$pluginPath\build.gradle.backup"
    Write-Host "Created backup of original build.gradle file"
    
    # Apply the patch
    Copy-Item $patchPath "$pluginPath\build.gradle"
    Write-Host "Applied patch to build.gradle"
    
    Write-Host "Patch applied successfully. Now try running 'flutter clean' and 'flutter pub get' then build your app again."
} else {
    Write-Host "Could not find flutter_keyboard_visibility plugin at $pluginPath"
    Write-Host "Please check if the plugin is installed or if the path is correct."
} 