// When clicked on this bookmark, it will open the Graphana for universe. If tab is not cloudadmin.teleport,
// it will prompt to enter the universe UUID.
javascript:if (window.location.href.indexOf('https://cloudadmin.teleport.cloud.yugabyte.com/ga/universes/') === -1) {
    var universe = prompt('Please enter Universe UUID');
    if (universe) {
        window.open("https://grafana.teleport.cloud.yugabyte.com/d/universes/universes?orgId=1&refresh=1m&var-universe_uuid=" + universe, "_blank");
    }
}
else
{
    var url = window.location.href; 
    new_url = url.replace("https://cloudadmin.teleport.cloud.yugabyte.com/ga/universes/", "https://grafana.teleport.cloud.yugabyte.com/d/universes/universes?orgId=1&refresh=1m&var-universe_uuid=");
    window.open(new_url, "_blank");
}