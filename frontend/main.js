window.addEventListener('DOMContentLoaded', (event) =>{
    getVisitCount()
})

const functionApiUrl = 'https://drewdavisgetresumecounter.azurewebsites.net/api/GetResumeCounter?code=azRx9Y9P8A7JrilV2%2FrqOarjQagF3a2bxJWWF9uioza9pCMOuV8sKA%3D%3D';
const localfunctionApi = 'http://localhost:7071/api/GetResumeCounter';

const getVisitCount = () => {
    let count = 30;
    fetch(functionApiUrl).then(response => {
        return response.json()
    }).then(response =>{
        console.log("Website called function API.");
        count = response.count;
        document.getElementById("counter").innerText = count;
    }).catch(function(error){
        console.log(error);
    });
    return count;
}