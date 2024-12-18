function shortenStr(str, toIndex, suffix = "...") {
    if(str == null) return "";
    str = str.trim();
    if(str.length == 0) return " ";
    if(toIndex <= 0) return str.charAt(0);
    if(toIndex + suffix.length >= str.length) return str;
    return str.substring(0, toIndex) + suffix;
}
function trimStr(str) {
    if(str == null) return "";
    return str.trim();
}
function getAddressDisplayStr(address) {
    if(!address) {
        return "Add new address ";
    }
    if(address.postalCode) {
        let str =  "Postal code: " + address.postalCode;
        if(address.postalCodeExt) str += "-" + address.postalCodeExt;
        if(address.postalCodeGeoId) str += " - " + address.postalCodeGeoId;
        return str;
    }
    return shortenStr(address.unitNumber, 10) + " " + shortenStr(address.address1, 20) 
        + " at " + trimStr(address.city) + ", " + trimStr(address.stateProvinceGeoId);
}
function isObjectEmpty(o) {
    for(let key in o) return false;
    return true;
}

function loadHtml(containerEle, url) {
    if(!url) return;
    return fetch(url)
        .then((res) => res.text())
        .then((htmlText) => { containerEle.innerHTML = htmlText;})
        .catch((error) => {alert(error);});
}    
function hasValue(obj, propertyName) {
    const propValue = getValue(obj, propertyName);
    return propValue && propValue != "_NA_";
}
function getValue(obj, propertyName) {
    if(obj == null) return null;
    return obj[propertyName];
}
