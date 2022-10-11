//prompts to enter pattern to search
javascript: var pattern = prompt("What you want me to search for?");
if (pattern) {
    url = "https://github.com/yugabyte/yugabyte-db/search?q=" + pattern; 
    window.location.href = url;
}