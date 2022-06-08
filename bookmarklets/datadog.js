// When clicked on this bookmark, it will open the datadog for universe. If tab is not cloudadmin.teleport,
// it will prompt to enter the universe UUID.
javascript:if (window.location.href.indexOf('https://cloudadmin.teleport.cloud.yugabyte.com/ga/universes/') === -1) {
    var universe = prompt('Please enter Universe UUID');
    if (universe) {
        window.open("https://app.datadoghq.com/logs?query=cluster-id%3A" + universe, "_blank");
    }
}
else
{
    var url = window.location.href; 
    new_url = url.replace("https://cloudadmin.teleport.cloud.yugabyte.com/ga/universes/", "https://app.datadoghq.com/logs?query=cluster-id%3A");
    window.open(new_url, "_blank");
}