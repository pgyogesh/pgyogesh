javascript: (function () {
    var xhr = new XMLHttpRequest();
    var url = window.location.href;
    if (url.indexOf('9000/rpcz') === -1) {
        alert("Invalid Endpoint, Expected URL: http://<host>:9000/rpcz");
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
                var outbound_table = "<table><thead><tr><th>Remote IP</th><th>State</th><th>Processed Call Count</th><th>Sending Bytes</th></tr></thead><tbody>";
                data.outbound_connections.forEach(function (outbound_connections) {
                    var remote_ip = outbound_connections.remote_ip || "";
                    var state = outbound_connections.state || "";
                    var processed_call_count = outbound_connections.processed_call_count || "";
                    var sending_bytes = outbound_connections.sending_bytes || "";
                    outbound_table += "<tr><td>" + remote_ip + "</td><td>" + state + "</td><td>" + processed_call_count + "</td><td>" + sending_bytes + "</td></tr>";
                });
                var popup = window.open("", "yb-tserver connections", "height=500,width=800");
                popup.document.write("<html><head><title>yb-tserver connections</title><style>table{border-collapse: collapse;width: 100%;}th, td {text-align: left;padding: 8px;}th {background-color: #000041;color: white;font-style: normal;}td {border: 0.1px solid #ff6e42;}</style></head><body> <h3> Inbound Connections: " + inbound_table + "<br> <h3> Outbound Connections: </h3>" + outbound_table + "</body></html>");
            }
        }
    }
    xhr.send();
})();