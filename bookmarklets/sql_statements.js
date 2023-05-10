javascript: (function () {
    var xhr = new XMLHttpRequest();
    var url = window.location.href;
    if (url.indexOf('13000/statements') === -1) {
        alert("Invalid Endpoint, Expected URL: http://<host>:13000/statements");
        return;
    }
    else {
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var table = "<table class='sortable'><thead><tr><th>Query ID</th><th>Query</th><th>Calls</th><th>Total Time</th><th>Min Time</th><th>Max Time</th><th>Mean Time</th><th>Stddev Time</th><th>Rows</th></tr></thead><tbody>";
                data.statements.forEach(function (statement) {
                    var query_id = statement.query_id || "";
                    var query = statement.query || "";
                    var calls = statement.calls || "";
                    var total_time = statement.total_time || "";
                    var min_time = statement.min_time || "";
                    var max_time = statement.max_time || "";
                    var mean_time = statement.mean_time || "";
                    var stddev_time = statement.stddev_time || "";
                    var rows = statement.rows || "";
                    table += "<tr><td>" + query_id + "</td><td>" + query + "</td><td>" + calls + "</td><td>" + total_time + "</td><td>" + min_time + "</td><td>" + max_time + "</td><td>" + mean_time + "</td><td>" + stddev_time + "</td><td>" + rows + "</td></tr>";
                });
                table += "</tbody></table>";
                var popup = window.open("", "YSQL All Statements", "height=auto,width=auto");
                popup.document.write("<html><head><title>YSQL All Statements</title><style>table{border-collapse: collapse;width: 100%;}th, td {text-align: left;padding: 8px;}th {background-color: #000041;color: white;font-style: normal;}td {border: 0.1px solid #ff6e42;}</style></head><body>" + table + "</body></html>");
            }
        }
    }
    xhr.send();
})();