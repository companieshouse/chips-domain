<%@ page language="java" contentType="text/html;charset=UTF-8"%>
<%
    // Obtain the list of allowed properties that can be modified
    String allowedPropertiesString = System.getenv("CSI_MODIFIABLE_JAVA_SYSTEM_PROPERTIES");
    if (allowedPropertiesString == null) {
      allowedPropertiesString = "";
    }
    List<String> allowedProperties = Arrays.asList(allowedPropertiesString.split(","));
    String propertyName = request.getParameter("propertyname");
    String propertyValue = request.getParameter("propertyvalue");
    if (propertyName != null && !propertyName.isBlank() && propertyValue != null) {
      if (allowedProperties.contains(propertyName)) {
        System.out.println("Setting " + propertyName + "=" + propertyValue);
        System.setProperty(propertyName, propertyValue);
      } else {
        System.out.println("WARNING: setSysProp.jsp - Attempt to set non-allowed property: " + propertyName);
      }
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
