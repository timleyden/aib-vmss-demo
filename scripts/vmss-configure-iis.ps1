Set-Content 'C:\inetpub\wwwroot\default.aspx' -Value "<% @ Page Language=`"C#`" %>`n<%foreach (string var in Request.ServerVariables)`n{`n  Response.Write(var + `" `" + Request[var] + `"<br>`");`n}`n%>" -NoNewline

if (Test-Path C:\inetpub\wwwroot\iisstart.htm)
{
  Rename-Item C:\inetpub\wwwroot\iisstart.htm iisstart.html.archive
}