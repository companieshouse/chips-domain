<%@ page language="java" contentType="text/html;charset=UTF-8"%>
<%@ page import="org.apache.logging.log4j.LogManager"%>
<%@ page import="org.apache.logging.log4j.Level"%>
<%@ page import="org.apache.logging.log4j.core.LoggerContext"%>
<%@ page import="org.apache.logging.log4j.core.config.Configuration"%>
<%@ page import="org.apache.logging.log4j.core.config.LoggerConfig"%>

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
        LoggerContext ctx = (LoggerContext) LogManager.getContext(false);
        Configuration log4JConfiguration = ctx.getConfiguration();
        LoggerConfig loggerConfig = log4JConfiguration.getLoggerConfig(targetLogger); 
        loggerConfig.setLevel(Level.toLevel(targetLogLevel));
        ctx.updateLoggers();

        System.out.println("Log4j2 log level for logger: " + targetLogger + " changed to " + targetLogLevel);
        %>
        <p>Log4j2 log level for logger: <%= targetLogger %> changed to <%= targetLogLevel %></p>
        <%
      }  
    %>
  </body>
</html>
