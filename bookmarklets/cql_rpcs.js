javascript: (function () {
  var xhr = new XMLHttpRequest();
  var url = window.location.href;
  if (url.indexOf('12000/rpcz') === -1) {
    alert("Invalid Endpoint, Expected URL: http://<host>:12000/rpcz");
    return;
  }
  else {
    xhr.open("GET", url, true);
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4 && xhr.status === 200) {
        var data = JSON.parse(xhr.responseText);
        var table = "<table><thead><tr><th>Remote IP</th><th>Keyspace</th><th>State</th><th>Processed Call Count</th><th>Elapsed Millis</th><th>SQL</th><th>Params</th></tr></thead><tbody>";
        data.inbound_connections.forEach(function (connection) {
          var remoteIp = connection.remote_ip || "";
          var state = connection.state || "";
          var processedCallCount = connection.processed_call_count || "";
          var keyspace = connection.connection_details?.cql_connection_details?.keyspace || "";
          var elapsedMillis = connection.calls_in_flight ? connection.calls_in_flight[0]?.elapsed_millis || "" : "";
          var sql_string = connection.calls_in_flight ? connection.calls_in_flight[0]?.cql_details?.call_details[0]?.sql_string || "" : "";
          var params = connection.calls_in_flight ? connection.calls_in_flight[0]?.cql_details?.call_details[0]?.params || "" : "";
          table += "<tr><td>" + remoteIp + "</td><td>" + keyspace + "</td><td>" + state + "</td><td>" + processedCallCount + "</td><td>" + elapsedMillis + "</td><td>" + sql_string + "</td><td>" + params + "</td></tr>";
        });
        table += "</tbody></table>";
        var popup = window.open("", "YCQL Connections", "height=auto,width=auto");
        popup.document.write("<html><head><title>YCQL Connections</title><style>table{border-collapse: collapse;width: 100%;}th, td {text-align: left;padding: 8px;}th {background-color: #000041;color: white;font-style: normal;}td {border: 0.1px solid #ff6e42;}</style></head><body> <p> Remember: If SQLs are running in batch, Only one SQL is dislayed for each connection </p>" + table + "</body></html>");
      }
    }
  };
  xhr.send();
})();
