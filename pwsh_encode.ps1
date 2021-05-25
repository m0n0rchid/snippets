$text = Read-Host -Prompt 'String to Encode: '
$bytes = [System.Text.Encoding]::Unicode.GetBytes($text)
$EncodedText = [Convert]::ToBase64String($bytes)
Write-Host $EncodedText
