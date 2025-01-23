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
function getBytes(s) {
    let bytes = [];
    for(let i = 0; i < s.length; i++) {
        bytes.push(s.charCodeAt(i));
    }
    return bytes;
}
// function decodeUtf8(bytes) {
// 	var i = 0, s = '';
// 	while (i < bytes.length) {
// 		var c = bytes[i++];
// 		if (c > 127) {
// 			if (c > 191 && c < 224) {
// 				if (i >= bytes.length)
// 					throw new Error('UTF-8 decode: incomplete 2-byte sequence');
// 				c = (c & 31) << 6 | bytes[i++] & 63;
// 			} else if (c > 223 && c < 240) {
// 				if (i + 1 >= bytes.length)
// 					throw new Error('UTF-8 decode: incomplete 3-byte sequence');
// 				c = (c & 15) << 12 | (bytes[i++] & 63) << 6 | bytes[i++] & 63;
// 			} else if (c > 239 && c < 248) {
// 				if (i + 2 >= bytes.length)
// 					throw new Error('UTF-8 decode: incomplete 4-byte sequence');
// 				c = (c & 7) << 18 | (bytes[i++] & 63) << 12 | (bytes[i++] & 63) << 6 | bytes[i++] & 63;
// 			} else throw new Error('UTF-8 decode: unknown multibyte start 0x' + c.toString(16) + ' at index ' + (i - 1));
// 		}
// 		if (c <= 0xffff) s += String.fromCharCode(c);
// 		else if (c <= 0x10ffff) {
// 			c -= 0x10000;
// 			s += String.fromCharCode(c >> 10 | 0xd800)
// 			s += String.fromCharCode(c & 0x3FF | 0xdc00)
// 		} else throw new Error('UTF-8 decode: code point 0x' + c.toString(16) + ' exceeds UTF-16 reach');
// 	}
// 	return s;
// } 

function decodeUtf8(arrayBuffer) {
    var result = "";
    var i = 0;
    var c = 0;
    var c1 = 0;
    var c2 = 0;

    var data = new Uint8Array(arrayBuffer);

    // If we have a BOM skip it
    if (data.length >= 3 && data[0] === 0xef && data[1] === 0xbb && data[2] === 0xbf) {
        i = 3;
    }

    while (i < data.length) {
        c = data[i];

        if (c < 128) {
            result += String.fromCharCode(c);
            i++;
        } else if (c > 191 && c < 224) {
            if (i + 1 >= data.length) {
                throw "UTF-8 Decode failed. Two byte character was truncated.";
            }
            c2 = data[i + 1];
            result += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
            i += 2;
        } else {
            if (i + 2 >= data.length) {
                throw "UTF-8 Decode failed. Multi byte character was truncated.";
            }
            c2 = data[i + 1];
            c3 = data[i + 2];
            result += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
            i += 3;
        }
    }
    return result;
}