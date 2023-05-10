javascript: (function () {
    var xhr = new XMLHttpRequest();
    var url = window.location.href;
    if (url.indexOf('7000/rpcz') === -1) {
        alert("Invalid Endpoint, Expected URL: http://<host>:7000/rpcz");
        return;
    }
    else {
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function () {
            if (xhr.readyState === 4 && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var inbound_table = "<table><thead><tr><th>Remote IP</th><th>State</th><th>Processed Call Count</th></tr></thead><tbody>";
                data.inbound_connections.forEach(function (inbound_connections) {
                    var remote_ip = inbound_connections.remote_ip || "";
                    var state = inbound_connections.state || "";
                    var processed_call_count = inbound_connections.processed_call_count || "";
                    inbound_table += "<tr><td>" + remote_ip + "</td><td>" + state + "</td><td>" + processed_call_count + "</td></tr>";
                });
                inbound_table += "</tbody></table>";
                var popup = window.open("", "JSON to Table", "height=auto,width=auto");
                popup.document.write("<html><head><title>yb-tserver connections</title><style>table{border-collapse: collapse;width: 100%;}th, td {text-align: left;padding: 8px;}th {background-color: #000041;color: white;font-style: normal;}td {border: 0.1px solid #ff6e42;}</style></head><body>" + inbound_table + "</body></html>");
            }
        }
    }
        xhr.send();
    }
)();