<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Welcome Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #4CAF50;
        }
        .message {
            padding: 15px;
            background-color: #e8f5e9;
            border-left: 4px solid #4CAF50;
            margin: 20px 0;
        }
        a {
            color: #4CAF50;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello, ${userName}!</h1>

        <div class="message">
            <p>${message}</p>
        </div>

        <p><strong>Server Info:</strong> <%= application.getServerInfo() %></p>
        <p><strong>Servlet:</strong> HelloServlet</p>
        <p><strong>JSP:</strong> welcome.jsp</p>

        <p><a href="index.jsp">← Go back</a></p>
    </div>
</body>
</html>