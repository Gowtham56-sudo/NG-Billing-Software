Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

AppDir = FSO.GetParentFolderName(WScript.ScriptFullName)

' 1. Determine Python executable (use packaged venv if available)
PythonExe = "python"
If FSO.FileExists(AppDir & "\python_voice_server\venv\Scripts\python.exe") Then
    PythonExe = AppDir & "\python_voice_server\venv\Scripts\python.exe"
End If

' 2. Launch Python Voice AI Engine completely hidden (WindowStyle 0)
ServerScript = AppDir & "\python_voice_server\server.py"
If FSO.FileExists(ServerScript) Then
    WshShell.Run """" & PythonExe & """ """ & ServerScript & """", 0, False
End If

' 3. Wait 2 seconds for WebSocket server initialization
WScript.Sleep 2000

' 4. Launch POS Billing Application and wait for exit
AppExe = AppDir & "\nextgen_billing_software.exe"
If FSO.FileExists(AppExe) Then
    ' Run Flutter App normally and wait until it is closed
    WshShell.Run """" & AppExe & """", 1, True
Else
    MsgBox "Could not find nextgen_billing_software.exe in " & AppDir, vbCritical, "NextGen Billing Error"
End If

' 5. Clean up background Python Voice server on exit
On Error Resume Next
WshShell.Run "taskkill /F /IM python.exe /FI ""WINDOWTITLE eq NextGen*""", 0, True
