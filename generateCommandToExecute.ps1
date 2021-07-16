$cmd=@"

`$defaultaspx = `@"
<% `@ Page Language="C#" %>
<%
foreach (string var in Request.ServerVariables)
{
  Response.Write(var + " " + Request[var] + "<br>");
}
%>
"`@

Set-Content C:\inetpub\wwwroot\default.aspx -Value `$defaultaspx  -NoNewline
if(test-path C:\inetpub\wwwroot\iisstart.htm){
    rename-Item C:\inetpub\wwwroot\iisstart.htm iisstart.html.archive
}
"@
$bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
$encodedCommand = [Convert]::ToBase64String($bytes)


write-output "powershell.exe -ExecutionPolicy Unrestricted -EncodedCommand `"$($encodedCommand)`"" > base64encodedcmd.txt
notepad base64encodedcmd.txt