<%@ page language="java" contentType="text/html;charset=UTF-8"%>
<%@ page import="org.apache.logging.log4j.Level"%>
<%@ page import="org.apache.logging.log4j.core.config.Configurator"%>

<html>
  <head>
    <title>Log4J2 Administration utility</title>
  </head>
  <body>
    <%
      String targetOperation   = (String)request.getParameter("operation");
      String targetLogger      = (String)request.getParameter("logger");
      String targetLogLevel    = (String)request.getParameter("newLogLevel");

      if("changeLogLevel".equals(targetOperation))
      {
        Configurator.setLevel(targetLogger, Level.toLevel(targetLogLevel));
        System.out.println("Log4j2 log level for logger: " + targetLogger + " changed to " + targetLogLevel);
        %>
        <p>Log4j2 log level for logger: <%= targetLogger %> changed to <%= targetLogLevel %></p>
        <%
      }  
    %>
  </body>
</html>
