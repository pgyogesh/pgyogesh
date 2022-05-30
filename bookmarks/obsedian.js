javascript:if (window.location.href.indexOf('yugabyte.zendesk.com') === -1) {
    var ticket = prompt('Please enter your ticket number');
    if (ticket) {
        window.location.href = 'obsidian://open?vault=Random&file=Tickets%2F' + ticket;
    }
}
else
{
    var url = window.location.href; new_url = url.replace("https://yugabyte.zendesk.com/agent/tickets/", "obsidian://open?vault=Random&file=Tickets%2F");; window.location.href = new_url;
}