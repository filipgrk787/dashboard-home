// Dark mode toggle
const logoImg = document.getElementById('logo-img');

document.getElementById('darkModeToggle').addEventListener('click', () => {
    document.body.classList.toggle('dark');
    
    if (document.body.classList.contains('dark')) {
        logoImg.src = "/static/assets/img/filipgrk-logo-white.png"; // logo for dark mode
    } else {
        logoImg.src = "/static/assets/img/filipgrk-logo.png"; // logo for light mode
    }
});

function updateStatus(ip, elementId) {
    fetch(`/ping-check?ip=${ip}`)
    .then(response => response.json())
    .then(data => {
        const statusElement = document.getElementById(elementId);
        if (data.status.startsWith("online")) {
            let color;
            if (data.status === "online-fast") {
                color = "green";
            } else if (data.status === "online-medium") {
                color = "orange";
            } else {
                color = "red";
            }
            statusElement.innerHTML = `<span style="color: ${color}; font-weight: bold;">● ${data.latency} ms</span>`;
        } else {
            statusElement.innerHTML = `<span style="color: red; font-weight: bold;">● Offline</span>`;
        }
    })
    .catch(error => {
        console.error('Error checking status:', error);
        const statusElement = document.getElementById(elementId);
        statusElement.innerHTML = `<span style="color: red; font-weight: bold;">● Offline</span>`;
    });
}