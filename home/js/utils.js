function loadHtml(containerEle, url) {
    if(!url) return;
    fetch(url)
        .then((res) => res.text())
        .then((htmlText) => { containerEle.innerHTML = htmlText;})
        .catch((error) => {alert(error);});
}    
