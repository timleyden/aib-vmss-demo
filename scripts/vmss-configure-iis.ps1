$content = @"
<% @ Page Language="C#" %>
<%
Response.Write(System.Environment.MachineName+"</br>");
foreach (string var in Request.ServerVariables)
{
    Response.Write(var + " " + Request[var] + "</br>");
}
%>
"@
Set-Content -Path C:\inetpub\wwwroot\default.aspx -Value $content -NoNewLine
if (Test-Path C:\inetpub\wwwroot\iisstart.htm)
{
  Rename-Item C:\inetpub\wwwroot\iisstart.htm iisstart.html.archive
}