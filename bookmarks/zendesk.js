javascript: var ticket = prompt("Enter 4 digit ticket number");
if (ticket) {
    url = "https://support.yugabyte.com/agent/tickets/" + ticket; 
    window.location.href = url;
}