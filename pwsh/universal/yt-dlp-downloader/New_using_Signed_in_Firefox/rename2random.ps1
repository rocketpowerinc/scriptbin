# Rename all files in current directory to unique random 15-character names
# Keeps original extensions

$chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
$used = @{}

Get-ChildItem -File | ForEach-Object {

  do {
    $name = -join (1..15 | ForEach-Object {
        $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
      })
  } while (
    $used.ContainsKey($name) -or
    (Test-Path -LiteralPath "$name$($_.Extension)")
  )

  $used[$name] = $true

  Rename-Item -LiteralPath $_.FullName -NewName "$name$($_.Extension)"
}