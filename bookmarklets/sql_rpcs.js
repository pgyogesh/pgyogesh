javascript: (function () {
    var xhr = new XMLHttpRequest();
    var url = window.location.href;
    if (url.indexOf('13000/rpcz') === -1) {
        alert("Invalid Endpoint, Expected URL: http://<host>:13000/rpcz");
        return;
    }
    else {
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var table = "<table><thead><tr><th>DB Name</th><th>Query</th><th>Process Start Time</th><th>Process Running For MS</th><th>Transaction Start Time</th><th>Transaction Running For MS</th><th>Query Start Time</th><th>Query Running For MS</th><th>Application Name</th><th>Backend Type</th><th>Backend Status</th><th>Host</th><th>Port</th></tr></thead><tbody>";
                data.connections.forEach(function (connection) {
                    var db_name = connection.db_name || "";
                    var query = connection.query || "";
                    var process_start_time = connection.process_start_time || "";
                    var process_running_for_ms = connection.process_running_for_ms || "";
                    var transaction_start_time = connection.transaction_start_time || "";
                    var transaction_running_for_ms = connection.transaction_running_for_ms || "";
                    var query_start_time = connection.query_start_time || "";
                    var query_running_for_ms = connection.query_running_for_ms || "";
                    var application_name = connection.application_name || "";
                    var backend_type = connection.backend_type || "";
                    var backend_status = connection.backend_status || "";
                    var host = connection.host || "";
                    var port = connection.port || "";
                    table += "<tr><td>" + db_name + "</td><td>" + query + "</td><td>" + process_start_time + "</td><td>" + process_running_for_ms + "</td><td>" + transaction_start_time + "</td><td>" + transaction_running_for_ms + "</td><td>" + query_start_time + "</td><td>" + query_running_for_ms + "</td><td>" + application_name + "</td><td>" + backend_type + "</td><td>" + backend_status + "</td><td>" + host + "</td><td>" + port + "</td></tr>";
                });
                table += "</tbody></table>";
                var popup = window.open("", "YSQL Connections", "height=auto,width=auto");
                popup.document.write("<html><head><title>YSQL Connections</title><style>table{border-collapse: collapse;width: 100%;}th, td {text-align: left;padding: 8px;}th {background-color: #000041;color: white;font-style: normal;}td {border: 0.1px solid #ff6e42;}</style></head><body>" + table + "</body></html>");
            }
        }
    };
    xhr.send();
})();