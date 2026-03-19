window.addEventListener('DOMContentLoaded', (event) =>{
    getVisitCount()
})

const functionApiUrl = '__FUNCTION_API_URL__';
const localfunctionApi = 'http://localhost:7071/api/GetResumeCounter';

const getApiUrl = () => {
    if (functionApiUrl && functionApiUrl.startsWith('http')) {
        return functionApiUrl;
    }

    const isLocalHost = ['localhost', '127.0.0.1', '[::1]'].includes(window.location.hostname);
    return isLocalHost ? localfunctionApi : '';
};

const setCounterStatus = (message = '') => {
    const counterElement = document.getElementById('counter');

    if (!counterElement) {
        return;
    }

    let statusElement = document.getElementById('counter-status');

    if (!statusElement) {
        statusElement = document.createElement('span');
        statusElement.id = 'counter-status';
        counterElement.insertAdjacentElement('afterend', statusElement);
    }

    statusElement.textContent = message ? ` (${message})` : '';
};

const getVisitCount = () => {
    let count = 30;
    const apiUrl = getApiUrl();

    if (!apiUrl) {
        setCounterStatus('counter not configured');
        return count;
    }

    fetch(apiUrl).then(async response => {
        const contentType = response.headers.get('content-type') || '';

        if (!response.ok) {
            throw new Error(`Counter API request failed (${response.status}) at ${apiUrl}`);
        }

        if (!contentType.includes('application/json')) {
            const bodyPreview = (await response.text()).slice(0, 120);
            throw new Error(`Counter API returned non-JSON content at ${apiUrl}: ${bodyPreview}`);
        }

        return response.json();
    }).then(response =>{
        console.log("Website called function API.");
        count = response.count;
        document.getElementById("counter").innerText = count;
        setCounterStatus('');
    }).catch(function(error){
        console.log(error);
        setCounterStatus('API unavailable');
    });
    return count;
}