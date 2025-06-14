// Global variables
let distanceChart;
let currentTimeRange = 24; // hours
let isConnected = false;
let lastDistance = null;
let updateInterval;

// Chart configuration
const chartConfig = {
    type: 'line',
    data: {
        labels: [],
        datasets: [{
            label: 'Distance (cm)',
            data: [],
            borderColor: '#00D4FF',
            backgroundColor: 'rgba(0, 212, 255, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.4,
            pointBackgroundColor: '#00D4FF',
            pointBorderColor: '#ffffff',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            pointHoverBackgroundColor: '#8B5CF6',
            pointHoverBorderColor: '#ffffff',
            pointHoverBorderWidth: 3
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                backgroundColor: 'rgba(15, 23, 42, 0.9)',
                titleColor: '#00D4FF',
                bodyColor: '#F1F5F9',
                borderColor: '#00D4FF',
                borderWidth: 1,
                cornerRadius: 10,
                displayColors: false,
                callbacks: {
                    title: function(context) {
                        return 'Distance Reading';
                    },
                    label: function(context) {
                        return `${context.parsed.y.toFixed(1)} cm`;
                    },
                    afterLabel: function(context) {
                        const time = context.label;
                        return `Time: ${time}`;
                    }
                }
            }
        },
        scales: {
            x: {
                display: true,
                grid: {
                    color: 'rgba(0, 212, 255, 0.1)',
                    borderColor: 'rgba(0, 212, 255, 0.3)'
                },
                ticks: {
                    color: '#94A3B8',
                    maxTicksLimit: 10
                }
            },
            y: {
                display: true,
                grid: {
                    color: 'rgba(0, 212, 255, 0.1)',
                    borderColor: 'rgba(0, 212, 255, 0.3)'
                },
                ticks: {
                    color: '#94A3B8',
                    callback: function(value) {
                        return value + ' cm';
                    }
                },
                beginAtZero: false
            }
        },
        interaction: {
            intersect: false,
            mode: 'index'
        },
        animation: {
            duration: 1000,
            easing: 'easeInOutQuart'
        }
    }
};

// Initialize the distance chart
function initDistanceChart() {
    console.log('Initializing distance chart...');
    const ctx = document.getElementById('distanceChart').getContext('2d');
    distanceChart = new Chart(ctx, chartConfig);
}

// Update connection status
function updateConnectionStatus(status, message = '') {
    const statusEl = document.getElementById('connection-status');
    const statusIcon = document.getElementById('status-icon');
    
    if (status === 'connected') {
        isConnected = true;
        statusEl.innerHTML = '<small class="text-success"><i class="fas fa-wifi me-1"></i>Connected</small>';
        if (statusIcon) {
            statusIcon.className = 'fas fa-heartbeat status-online';
        }
    } else if (status === 'error') {
        isConnected = false;
        statusEl.innerHTML = `<small class="text-danger"><i class="fas fa-exclamation-triangle me-1"></i>Error: ${message}</small>`;
        if (statusIcon) {
            statusIcon.className = 'fas fa-heart-broken status-offline';
        }
    } else {
        isConnected = false;
        statusEl.innerHTML = '<small class="text-warning"><i class="fas fa-circle-notch fa-spin me-1"></i>Connecting...</small>';
        if (statusIcon) {
            statusIcon.className = 'fas fa-heartbeat status-warning';
        }
    }
}

// Show/hide loading indicator
function setLoading(show) {
    const loading = document.getElementById('loading');
    if (show) {
        loading.classList.remove('hidden');
    } else {
        loading.classList.add('hidden');
    }
}

// Animate number counting
function animateNumber(elementId, targetValue, suffix = '', duration = 1000) {
    const element = document.getElementById(elementId);
    if (!element) return;
    
    const startValue = parseFloat(element.textContent.replace(/[^\d.-]/g, '')) || 0;
    const difference = targetValue - startValue;
    const startTime = performance.now();
    
    function updateNumber(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Easing function for smooth animation
        const easeOutQuart = 1 - Math.pow(1 - progress, 4);
        const currentValue = startValue + (difference * easeOutQuart);
        
        if (typeof targetValue === 'number' && targetValue % 1 !== 0) {
            element.textContent = currentValue.toFixed(1) + suffix;
        } else {
            element.textContent = Math.round(currentValue) + suffix;
        }
        
        if (progress < 1) {
            requestAnimationFrame(updateNumber);
        } else {
            element.textContent = targetValue + suffix;
        }
    }
    
    requestAnimationFrame(updateNumber);
}

// Update current reading display
function updateCurrentReading(data) {
    console.log('Updating current reading:', data);
    
    if (data.distance !== null) {
        // Animate the distance value
        animateNumber('current-distance', data.distance, '');
        animateNumber('gauge-distance', data.distance, '');
        
        // Update status
        const statusElement = document.getElementById('sensor-status');
        const lastReadingElement = document.getElementById('last-reading');
        
        if (data.status === 'online') {
            statusElement.textContent = 'ONLINE';
            statusElement.className = 'stats-value status-online';
            lastReadingElement.textContent = `${data.seconds_ago}s ago`;
        } else {
            statusElement.textContent = 'OFFLINE';
            statusElement.className = 'stats-value status-offline';
            lastReadingElement.textContent = data.message || 'No data';
        }
        
        lastDistance = data.distance;
    } else {
        document.getElementById('current-distance').textContent = '--';
        document.getElementById('gauge-distance').textContent = '--';
        document.getElementById('sensor-status').textContent = 'NO DATA';
        document.getElementById('sensor-status').className = 'stats-value status-warning';
        document.getElementById('last-reading').textContent = data.message || 'No readings';
    }
}

// Update historical chart
function updateChart(historyData) {
    console.log('Updating chart with', historyData.count, 'readings');
    
    if (!historyData.readings || historyData.readings.length === 0) {
        console.log('No historical data available');
        return;
    }
    
    // Clear existing data
    distanceChart.data.labels = [];
    distanceChart.data.datasets[0].data = [];
    
    // Add new data points
    historyData.readings.forEach(reading => {
        const time = new Date(reading.timestamp);
        const timeLabel = time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        
        distanceChart.data.labels.push(timeLabel);
        distanceChart.data.datasets[0].data.push(reading.distance);
    });
    
    // Update chart with animation
    distanceChart.update('active');
}

// Update statistics display
function updateStatistics(stats) {
    console.log('Updating statistics:', stats);
    
    if (stats.count > 0) {
        // Animate main statistics
        animateNumber('stat-min', stats.min, ' cm');
        animateNumber('stat-max', stats.max, ' cm');
        animateNumber('stat-avg', stats.average, ' cm');
        animateNumber('stat-range', stats.range, ' cm');
        
        // Update daily readings
        animateNumber('daily-readings', stats.count, '');
        
        // Calculate and display reading rate (readings per minute)
        const readingRate = (stats.count / (24 * 60)).toFixed(1);
        document.getElementById('reading-rate').textContent = `${readingRate}/min`;
        
        // Update performance metrics
        if (stats.performance) {
            animateNumber('uptime-percent', stats.performance.uptime, '%');
            document.getElementById('accuracy-percent').textContent = `${stats.performance.accuracy}% accuracy`;
            
            // Update progress bars
            const qualityPercent = stats.performance.data_quality === 'Excellent' ? 95 : 75;
            document.getElementById('quality-bar').style.width = `${qualityPercent}%`;
        }
        
        // Update stability if movement data is available
        if (stats.movement) {
            const stabilityPercent = Math.round(stats.movement.stability);
            document.getElementById('stability-bar').style.width = `${stabilityPercent}%`;
        }
        
        // Display achievements
        if (stats.achievements && stats.achievements.length > 0) {
            const achievementsHtml = stats.achievements.map(achievement => 
                `<span class="achievement-badge">${achievement}</span>`
            ).join('');
            document.getElementById('achievements').innerHTML = achievementsHtml;
        }
    }
}

// Update activity feed
function updateActivityFeed(activities) {
    console.log('Updating activity feed:', activities);
    
    const feedElement = document.getElementById('activity-feed');
    
    if (!activities.activities || activities.activities.length === 0) {
        feedElement.innerHTML = '<div class="text-center text-muted">No recent activity</div>';
        return;
    }
    
    const activitiesHtml = activities.activities.map(activity => `
        <div class="activity-item">
            <div class="activity-icon">${activity.icon}</div>
            <div class="flex-grow-1">
                <div>${activity.message}</div>
            </div>
            <div class="activity-time">${activity.time}</div>
        </div>
    `).join('');
    
    feedElement.innerHTML = activitiesHtml;
}

// Fetch current reading
async function fetchCurrentReading() {
    try {
        console.log('Fetching current reading...');
        const response = await fetch('/api/current', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Cache-Control': 'no-cache'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Current reading data:', data);
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        updateCurrentReading(data);
        return data;
        
    } catch (error) {
        console.error('Error fetching current reading:', error);
        updateConnectionStatus('error', error.message);
        throw error;
    }
}

// Fetch historical data
async function fetchHistory(hours = 24) {
    try {
        console.log(`Fetching ${hours} hours of history...`);
        const response = await fetch(`/api/history?hours=${hours}`, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Cache-Control': 'no-cache'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('History data:', data);
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        updateChart(data);
        return data;
        
    } catch (error) {
        console.error('Error fetching history:', error);
        throw error;
    }
}

// Fetch statistics
async function fetchStatistics() {
    try {
        console.log('Fetching statistics...');
        const response = await fetch('/api/stats', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Cache-Control': 'no-cache'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Statistics data:', data);
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        updateStatistics(data);
        return data;
        
    } catch (error) {
        console.error('Error fetching statistics:', error);
        throw error;
    }
}

// Fetch activity feed
async function fetchActivity() {
    try {
        console.log('Fetching activity feed...');
        const response = await fetch('/api/activity', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Cache-Control': 'no-cache'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('Activity data:', data);
        
        if (data.error) {
            throw new Error(data.error);
        }
        
        updateActivityFeed(data);
        return data;
        
    } catch (error) {
        console.error('Error fetching activity:', error);
        throw error;
    }
}

// Update all dashboard data
async function updateDashboard() {
    try {
        // Fetch all data concurrently
        const [currentData, historyData, statsData, activityData] = await Promise.all([
            fetchCurrentReading(),
            fetchHistory(currentTimeRange),
            fetchStatistics(),
            fetchActivity()
        ]);
        
        updateConnectionStatus('connected');
        
    } catch (error) {
        console.error('Error updating dashboard:', error);
        updateConnectionStatus('error', error.message);
    }
}

// Change time range for chart
function changeTimeRange(hours) {
    console.log(`Changing time range to ${hours} hours`);
    currentTimeRange = hours;
    
    // Update button states
    document.querySelectorAll('.btn-outline-primary, .btn-primary').forEach(btn => {
        btn.className = 'btn btn-sm btn-outline-primary';
    });
    event.target.className = 'btn btn-sm btn-primary';
    
    // Fetch new data
    fetchHistory(hours);
}

// Health check
async function healthCheck() {
    try {
        console.log('Performing health check...');
        const response = await fetch('/health');
        
        if (!response.ok) {
            throw new Error(`Health check failed: ${response.status}`);
        }
        
        const health = await response.json();
        console.log('Health check result:', health);
        
        if (health.status !== 'healthy') {
            throw new Error(health.dynamodb || 'Service unhealthy');
        }
        
        return health;
        
    } catch (error) {
        console.error('Health check failed:', error);
        throw error;
    }
}

// Initialize dashboard
async function initDashboard() {
    console.log('Initializing dashboard...');
    
    try {
        setLoading(true);
        updateConnectionStatus('connecting');
        
        // Perform health check
        await healthCheck();
        
        // Initialize chart
        initDistanceChart();
        
        // Initial data fetch
        await updateDashboard();
        
        // Set up regular updates
        updateInterval = setInterval(updateDashboard, 5000); // Update every 5 seconds
        
        setLoading(false);
        console.log('Dashboard initialized successfully');
        
    } catch (error) {
        console.error('Dashboard initialization failed:', error);
        setLoading(false);
        updateConnectionStatus('error', error.message);
        
        // Show error message
        document.body.innerHTML = `
            <div class="container mt-5">
                <div class="alert alert-danger">
                    <h4><i class="fas fa-exclamation-triangle"></i> Dashboard Initialization Error</h4>
                    <pre>${error.message}</pre>
                    <p>Please check the browser console for more details.</p>
                    <button class="btn btn-primary mt-3" onclick="location.reload()">
                        <i class="fas fa-redo"></i> Retry Connection
                    </button>
                </div>
            </div>`;
    }
}

// Cleanup function
function cleanup() {
    if (updateInterval) {
        clearInterval(updateInterval);
        updateInterval = null;
    }
}

// Handle page visibility changes
document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
        // Page is hidden, reduce update frequency
        if (updateInterval) {
            clearInterval(updateInterval);
            updateInterval = setInterval(updateDashboard, 30000); // Update every 30 seconds
        }
    } else {
        // Page is visible, restore normal update frequency
        if (updateInterval) {
            clearInterval(updateInterval);
            updateInterval = setInterval(updateDashboard, 5000); // Update every 5 seconds
        }
    }
});

// Handle page unload
window.addEventListener('beforeunload', cleanup);

// Start the dashboard when the page loads
window.addEventListener('load', initDashboard);

// Make functions globally available
window.changeTimeRange = changeTimeRange;

// Chart.js global configuration
Chart.defaults.font.family = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif";
Chart.defaults.color = '#94A3B8';
Chart.defaults.borderColor = 'rgba(0, 212, 255, 0.1)';
