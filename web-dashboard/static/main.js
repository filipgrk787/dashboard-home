document.addEventListener("DOMContentLoaded", () => {
    fetch('/data')
        .then(res => res.json())
        .then(json => {
            const stats = json.stats;
            const data = json.data;

            // Update stats
            document.getElementById('avgLatency').textContent = `${stats.avg_latency} ms`;
            document.getElementById('successRate').textContent = `${stats.success_rate} %`;
            document.getElementById('packetLoss').textContent = `${stats.packet_loss} %`;

            // Last updated
            if (data.length > 0) {
                const lastTimestamp = data[data.length - 1].timestamp;
                document.getElementById('lastUpdated').textContent = `🔄 Last updated: ${lastTimestamp}`;
            }

            // Chart setup
            const recentData = data.slice(-200); // Show last 200 pings only
            const labels = recentData.map(d => d.timestamp);
            const latency = recentData.map(d => d.latency);
            
            const ctx = document.getElementById('latencyChart').getContext('2d');

            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Latency (ms)',
                        data: latency,
                        fill: true,
                        tension: 0.4,
                        borderColor: '#0d6efd',
                        backgroundColor: 'rgba(13, 110, 253, 0.15)',
                        pointRadius: 3,
                        pointBackgroundColor: '#0d6efd',
                        pointHoverRadius: 5
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: {
                        mode: 'nearest',
                        axis: 'x',
                        intersect: false
                    },
                    plugins: {
                        tooltip: { mode: 'index', intersect: false },
                        legend: { display: false }
                    },
                    scales: {
                        y: {
                            beginAtZero: false,
                            ticks: { stepSize: 10 },
                            title: { display: true, text: 'ms' }
                        },
                        x: {
                            type: 'time',
                            time: {
                                parser: 'yyyy-MM-dd HH:mm:ss',
                                tooltipFormat: 'HH:mm:ss',
                                displayFormats: {
                                    minute: 'HH:mm',
                                    hour: 'HH:mm'
                                }
                            },
                            ticks: {
                                autoSkip: true,
                                maxRotation: 0,
                                minRotation: 0
                            },
                            title: {
                                display: true,
                                text: 'Time'
                            }
                        }
                    }
                }
            });
        });

    // Dark mode toggle
    const toggle = document.getElementById("darkToggle");
    toggle.addEventListener("click", () => {
        document.body.classList.toggle("bg-dark");
        document.body.classList.toggle("text-white");
        document.querySelectorAll(".card").forEach(card => {
            card.classList.toggle("bg-dark");
            card.classList.toggle("text-white");
            card.classList.toggle("border-light");
        });
    });

    // Auto-refresh every 60 seconds
    setInterval(() => {
        window.location.reload();
    }, 60000);
});
