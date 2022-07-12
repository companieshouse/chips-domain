<%@ page language="java" contentType="text/html;charset=UTF-8"%>

<%
	  String propertyName = request.getParameter("propertyname");
	  String propertyValue = request.getParameter("propertyvalue");
	  if (propertyName != null && propertyValue != null) {
	    System.out.println("Setting " + propertyName + "=" + propertyValue);
            System.setProperty(propertyName, propertyValue);
  	  }
%>
<html>
 <head>
  <title>Updating System Property</title>
 </head>
 <body>
  <div class="mainpage">
  <form>
    propertyName: <input type="text" name="propertyname" value='<%=propertyName%>'/>
    <br/>
    <br/>
    propertyValue: <input type="text" name="propertyvalue" value='<%=propertyValue%>'/>
    <br/>
    <br/>
    <input type="submit" value="Set value"/>
  </form>
  </div>
 </body>
</html>
