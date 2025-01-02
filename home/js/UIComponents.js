function invokeCallbackStack(callbackStack, value) {
    console.log("CallStack size: " + callbackStack.length);
    const tempStack = [];
    while(callbackStack.length > 0) {
        const callback = callbackStack.pop();
        if(callback.value === null || callback.value === undefined || callback.value == value) {
            result = callback.func().then((result) => {
                if(result) {
                    if(result.callback) {
                        tempStack.push(result);
                    } else {
                        tempStack.push(callback);
                    }    
                }
            });
        } else {
            tempStack.push(callback);
        }
    }
    for(let i = tempStack.length - 1; i >=0; i--) {
        callbackStack.push(tempStack[i]);
    }
}

// function handleResponse(response) {
//     return response.data;
// }
class Client {
    static EMPTY_STR = "";

    constructor(store) {
        this.store = store;
        const defaultToken = this.store.defaultToken;
        if(!defaultToken) defaultToken = Client.EMPTY_STR;
        this.defaultToken = defaultToken;
    }
    setConfig(key, value, defaultValue = Client.EMPTY_STR) {
        if(value === null || value === undefined) value = defaultValue;
        const cfg = this.store;
        const oldVal = cfg[key];
        cfg[key] = value; 
        if(cfg.on && cfg.on[key] && value != oldVal) {
            let callbackStack = cfg.on[key];
            if(callbackStack && oldVal != value) {
                invokeCallbackStack(callbackStack, value);
            }                
        }
    }
    get axios() {
        return this.store.axios;
    }
    get baseURL() {
        return this.store.baseURL;
    }
    get timeout() {
        return this.store.timeout;
    }
    get storeId() {
        return this.store.storeId;
    }
    get token() {
        return this.store.token;
    }
    set token(tokenStr) {
        this.setConfig("token", tokenStr, this.defaultToken);
    }
    get apiKey() {
        return this.store.apiKey;
    }
    set apiKey(apiKey) {
        this.setConfig("apiKey", apiKey);
    }
    get loggedIn() {
        return this.store.loggedIn;
    }
    set loggedIn(isLoggedIn) {
        this.setConfig("loggedIn", isLoggedIn ? true : false);
    }
    addCallback(func, key, value = null, callbackId = null) {
        const cfg = this.store;
        if(!cfg.on) {
            cfg.on = {};
        }
        if(cfg.on[key] == null) {
            cfg.on[key] = [];
        }
        const callbacks = cfg.on[key];
        if(callbackId) {
            for(let i = callbacks.length - 1; i >= 0; i--) {
                if(callbacks[i].id == callbackId) {
                    callbacks.splice(i, 1);
                }
            }
        }
        callbacks.push({value: value, func: func, id: callbackId});
    }

    getHeader() {
        const contentType = this.contentType;
        if(!contentType) {
            contentType = "application/json;charset=UTF-8";
        }
        return { "Content-Type": contentType };
    }
    getRequestConfig() {
        return {headers: this.getHeader()};
    }

    handleResponse(response) {
        return response.data;
    }
    get(url) {
        return this.axios.get(url, this.getRequestConfig()).then(this.handleResponse);
    }
    put(url, data) {
        return this.axios.put(url, data, this.getRequestConfig()).then(this.handleResponse);
    }
    post(url, data) {
        return this.axios.post(url, data, this.getRequestConfig()).then(this.handleResponse);
    }
    delete(url) {
        return this.axios.delete(url, this.getRequestConfig()).then(this.handleResponse);
    }
}
class FOClient extends Client {}
class BOClient extends Client {
    constructor(config) {
        super(config);
        const cfg = this.store;
        if(!cfg.axios) {
            const axiosConfig = {
                baseURL: cfg.baseURL,
                timeout: cfg.timeout ? cfg.timeout : 1000,
                withCredentials: cfg.withCredentials ? true : false
            };
            cfg.axios = axios.create(axiosConfig);
        }
    }
    get postalAddressMap() {
        return this.store.postalAddressMap;
    }
    saveShippingAddrress(address) {
        const self = this;
        return this.put("/customer/shippingAddresses", address).then((data) => {
            self.postalAddressMap[data.postalContactMechId] = data;
            return data;
        });
    }
    getCountries() {
        return this.get("/geos").then(data => data.resultList ? data.resultList : []);
    }
    getRegions(country) {
        return this.get("/geos/" + country + "/regions").then(data => data.resultList ? data.resultList : []);
    }
    getTimeZone() {
        return this.get("/timeZone").then(data => data.resultList ? data.resultList : []);
    }
    getLocale() {
        return this.get("/locale");
    }
    getHeader() {
        let headers = { 
            "Content-Type": this.contentType, 
            "store": this.storeId, 
            "moquiSessionToken": this.token, 
            "SessionToken" : this.token, 
            "X-CSRF-Token": this.token 
        };
        if(this.apiKey != null) {
            headers["api_key"] = this.apiKey;
        }
        return headers;
    }
}

class UserAccount extends BOClient {
    static CONFIG_KEYS = ["username", "userId", "partyId", "firstName", "lastName", "emailAddress", "locale"];
    constructor(userInfo) {
        super(userInfo);
        const self = this;
        for(const key of UserAccount.CONFIG_KEYS) {
            Object.defineProperty(self, key, {
                get: function() { return self.store[key]; },
                set: function(value) { 
                    self.setConfig(key, value);
                }
            })
        }
        this.setInfo(userInfo);
    }
    login(loginData) {
        const self = this;
        if(!loginData.username) {
            return this.post("/loginAnonymous", loginData).then((data) => {
                data.loggedIn = true;
                self.setInfo(data);
                return self;
            });
        }
        return this.post("/login", loginData).then((data) => {
                data.loggedIn = true;
                self.setInfo(data);
                return self;
            });
    }
    logout() {
        const self = this;
        return this.get("/logout").then(() => {
            self.setInfo({moquiSessionToken: self.defaultToken, loggedIn: false});
            return self;
        });
    }

    setInfo(data) {
        if(!data) data = {};

        this.loggedIn = data.loggedIn ? true : false;
        this.token = data.moquiSessionToken;
        this.apiKey = data.apiKey;
        
        let cInfo = data.customerInfo;
        if(!cInfo) cInfo = {};
        const postalAddressMap = this.postalAddressMap;
        if(postalAddressMap) {
            Object.keys(postalAddressMap).forEach(key => delete postalAddressMap[key]);
        }

        const postalAddressList = cInfo.postalAddressList;
        if(postalAddressList && postalAddressList.length > 0) {
            for(const postalAddress of postalAddressList) {
                postalAddressMap[postalAddress.postalContactMechId] = postalAddress;
            }
        };

        for(const key of UserAccount.CONFIG_KEYS) {
            this[key] = cInfo[key];
        }
    }

    register() {
        const userInfo = {
            firstName: this.firstName,
            middleName: this.middleName,
            lastName: this.lastName,
            username: this.username,
            emailAddress: this.emailAddress,
            newPassword: this.newPassword,
            newPasswordVerify: this.newPasswordVerify
        };
        const self = this;
        return this.post("/register", userInfo).then((data) => {
            data.loggedIn = true;
            self.setInfo(data);
            return self;
        });
    }
}
class Cart extends BOClient {
    constructor(cartInfo) {
        super(cartInfo);
        const self = this;
        this.addCallback(()=>{self.reset(); return Promise.resolve(true); }, "loggedIn", false, "resetCart");
        this.addCallback(()=>{return self.load().then(() => true); }, "loggedIn", true, "loadCart");
    }
    get isCartLoaded() {
        return this.store.isCartLoaded;
    }
    set isCartLoaded(isCartLoaded) {
        this.setConfig("isCartLoaded", isCartLoaded ? true : false);
    }
    get paymentsTotal() {
        return this.store.paymentsTotal;
    }
    set paymentsTotal(total) {
        this.setConfig("paymentsTotal", total, 0);
    }
    get totalUnpaid() {
        return this.store.totalUnpaid;
    }
    set totalUnpaid(total) {
        this.setConfig("totalUnpaid", total, 0);
    }
    get productsQuantity() {
        return this.store.productsQuantity;
    }
    set productsQuantity(quantity) {
        this.setConfig("productsQuantity", quantity, 0);
    }
    
    get orderPromoCodeDetailList() {
        return this.store.orderPromoCodeDetailList;
    }
    set orderPromoCodeDetailList(list) {
        this.setConfig("orderPromoCodeDetailList", list, []);
    }
    get paymentInfoList() {
        return this.store.paymentInfoList;
    }
    set paymentInfoList(list) {
        this.setConfig("paymentInfoList", list, []);
    }
    get orderItemList() {
        return this.store.orderItemList;
    }
    set orderItemList(list) {
        this.setConfig("orderItemList", list, []);
    }
    get orderItemWithChildrenSet() {
        return this.store.orderItemWithChildrenSet;
    }
    set orderItemWithChildrenSet(list) {
        this.setConfig("orderItemWithChildrenSet", list, []);
    }
    get orderHeader() {
        return this.store.orderHeader;
    }
    set orderHeader(orderHeader) {
        this.setConfig("orderHeader", orderHeader, {});
    }
    get orderPart() {
        return this.store.orderPart;
    }
    set orderPart(orderPart) {
        this.setConfig("orderPart", orderPart, {});
    }

    assign(data) {
        if(!data.orderItemList) return;
        for(var i = 0; i < data.orderItemList.length; i++) {
            let oItem = data.orderItemList[i];
            if(oItem.itemTypeEnumId == 'ItemProduct') {
                this.productsQuantity += oItem.quantity;
            }
            oItem.image = "/" + oItem.productId + "." + sessionToken + ".128x128._NA_.jpg"
        }
        Object.assign(this, data)
    }
    reset() {
        this.paymentsTotal = 0;
        this.totalUnpaid = 0;
        this.productsQuantity = 0;
        this.orderPromoCodeDetailList = [];
        this.paymentInfoList = [];
        this.orderItemList = [];
        this.orderItemWithChildrenSet = [];
        this.orderPart = {};
        this.orderHeader = {};
    }
    load() {
        if(!this.loggedIn) {
            return this;
        }
        const self = this;
        return this.get("/cart/info?timeStamp\x3d" + (new Date).getTime())
                .then((data) => {
                    self.reset();
                    self.assign(data);
                    self.isCartLoaded = true;
                    return self;
                });
    }
    addProduct(product, quantity = 1) {
        const self = this;
        if(!this.loggedIn) {
            this.addCallback(()=>{return self.addProduct(product, quantity).then(() => false);}, "loggedIn", true)
            if(this.loginForm) {
                this.loginForm.open();
            }
            return self;
        }

        return this.post("/cart/add", product)
            .then(function (data) {
                self.reset();
                self.assign(data);
                return self;
            });
    }
    removeProduct(product, index = -1) {
        let pIndex = index >= 0 ? index : this.orderItemList.findIndex(item => item.productId === product.productId)
        this.orderItemList.splice(pIndex, 1)
    }

    checkout(data) {
        if(this.paypalOrderId) {
            return this.paypalOrderId;
        }
        const self = this;
        const body = {
            orderId: this.orderHeader.orderId,
            paymentSource: data.paymentSource
        };
        if(this.ortherPart && this.ortherPart.orderPartSeqId) {
            body.orderPartSeqId = this.ortherPart.orderPartSeqId;
        }
        return this.post("/cart/checkout", body, this.store.requestConfig).then(function (data) {
            self.paymentId = data.paymentId;
            self.paypalOrderId = data.paypalOrderId;
            return data.paypalOrderId;
        });
    }
    place(data) {
        const self = this;
        return self.post("/cart/place", data).then((response) => {
            self.reset(); 
            return response;
        });
    }

}

class LazyList extends BOClient {
    constructor(loader) {
        this.items = loader();
    }
}

class Executor {
    constructor(callable) {
        this.callable = callable;
        this.isDone = false;
    }
    invoke() {
        if(this.callable) {
            this.callable();
        }
        this.isDone = true;
    }
    update() {
        this.invoke();
    }
}
class Closable extends Executor {
    constructor(dialog = null, button = null, componentUrl = null) {
        super()
        this.isOpen = false;
        this.isDone = false;
        this._initialized_ = !this.componentUrl;
        this.setButton(button);
        this.setDialog(dialog);
        this.setComponentUrl(componentUrl);
    }
    setDialog(dialog) {
        this.dialog = dialog;
    }
    setButton(button) {
        if(typeof button == "string") {
            this.buttonId = button;
            this.button = document.getElementById(this.buttonId);
        } else {
            this.button = button;
        }
    }
    setComponentUrl(componentUrl) {
        this.componentUrl = componentUrl;
    }
    init() {
        if(!this._initialized_) {
            return loadHtml(this.dialog, this.componentUrl).then(() => {this._initialized_ = true;});
        }
        return Promise.resolve("Already loaded");
    }
    toggle() {
        return this.isOpen ? this.close() : this.open();
    }
    open() {
        this.isOpen = true;
        if(this.dialog) this.dialog.focus();
    }
    close() {
        this.isOpen = false;
        if(this.button) this.button.focus();
        super.invoke();
    }
}
class Dialog extends Closable {
    constructor(dialog = null, button = null, componentUrl = null) {
        super(dialog, button, componentUrl);
        this.isOpen = false;
        this.isLoading = false;
        this.isDone = false;
        this.isChanged = false;
    }
    close() {
        this.isOpen = false;
        if(this.button) this.button.focus();
    }
    invoke() {
        this.isOpen = false;
        this.isLoading = false;
        this.isChanged = this.isDone;
        if(this.button) this.button.focus();
        // this.isDone = true;
        super.invoke();
    }
}


class LoginForm extends Dialog {
    constructor(userInfo, dialog, componentUrl) {
        super(dialog, null, componentUrl);
        this.userAccount = new UserAccount(userInfo);
        this.errorMsg = "";
        this.isDone = this.userAccount.loggedIn;
        this.username = this.userAccount.username;
        this.password = null;
        this.errorMsg = null;
        this._initialized_ = this.isDone;
    }
    init() {
        return super.init();
    }

    doLogin(loginData) {
        this.isLoading = true;
        const self = this;
        return this.userAccount.login(loginData)
            .then((userAccount) => {
                self.userAccount = userAccount;
                self.errorMsg = "";
                self.invoke();
                return this.userAccount;
            })
            .catch((error) => {
                self.errorMsg = error.message;
                alert(self.errorMsg);
                return null;
            });
    }
    login() {
        if (this.username.length < 3 || this.password.length < 3) {
            this.errorMsg = "Username or password is missing";
            alert(this.errorMsg);
            return null;
        }
        return this.doLogin({ username: this.username, password: this.password });
    }
    loginAnonymous() {
        return this.doLogin({});
    }
}

class AddressForm extends Dialog {
    constructor(dialog, button, componentUrl, addressClient) {
        super(dialog, button, componentUrl);
        this.client = addressClient;
        this.addressMap = this.client.postalAddressMap;
        let addressInfo = null;
        for(const address in this.addressMap) {
            addressInfo = address;
            break;
        }
        this.setAddressInfo(addressInfo);
    }
    newAddressInfo() {
        return {
            emailAddress: "",
            postalContactMechId: "_NA_",
            countryGeoId: "_NA_",
            stateProvinceGeoId: "_NA_",
            telecomContactMechId: "",
            emailContactMechId: "",
            emailAddress: "",
            postalContactMechPurposeId: "PostalShippingDest", 
            postalAddress: {}, 
            telecomNumber: {}
        };
    }
    setAddressInfo(addressInfo) {
        if(this.isChanged) {
            const dirtyObj = this.getDirtyObj();
            if(dirtyObj) {
                if(confirm("Do you want to save changes made on current address? ")) {
                    this.save(dirtyObj);
                }
            }    
        }
        if(!addressInfo) {
            addressInfo = this.newAddressInfo();
        }

        this.addressInfo = addressInfo;
        this.postalContactMechId = addressInfo.postalContactMechId;
        this.telecomContactMechId = addressInfo.telecomContactMechId;
        this.emailContactMechId = addressInfo.emailContactMechId;
        this.emailAddress = addressInfo.emailAddress;

        if(!addressInfo.postalAddress) {
            addressInfo.postalAddress = {}
        }
        const postalAddress = addressInfo.postalAddress;
        const addressFields = this.getAddressFields();
        for(let fieldName of addressFields) {
            this[fieldName] = postalAddress[fieldName];
        }

        if(!addressInfo.telecomNumber) {
            addressInfo.telecomNumber = {}
        }
        const telecomNumber = addressInfo.telecomNumber;
        const telecomFields = this.getTelecomFields();
        for(let fieldName of telecomFields) {
            this[fieldName] = telecomNumber[fieldName];
        }
    }
    getAddressFields() {
        return ["toName", "address1", "address2", "unitNumber", "postalCode", "postalCodeExt", "countryGeoId", "stateProvinceGeoId", "city", "emailContactMechId", "telecomContactMechId"];
    }
    getTelecomFields() {
        return ["contactNumber", "telecomExtension", "areaCode", "countryCode"];
    }

    onUpdated(data) {
        const addressInfo = this.addressInfo;
        addressInfo.emailAddress = this.emailAddress;

        const postalAddress = addressInfo.postalAddress;
        const addressFields = this.getAddressFields();
        for(let fieldName of addressFields) {
            postalAddress[fieldName] = this[fieldName];
        }
        if(!hasValue(postalAddress, "contactMechId")) {
            postalAddress.contactMechId = data.postalContactMechId;
        }

        const telecomNumber = addressInfo.telecomNumber;
        const telecomFields = this.getTelecomFields();
        for(let fieldName of telecomFields) {
            telecomNumber[fieldName] = this[fieldName];
        }
        if(!hasValue(telecomNumber, "contactMechId")) {
            telecomNumber.contactMechId = data.telecomContactMechId;
        }

        if(!hasValue(addressInfo, "postalContactMechId")) {
            addressInfo.postalContactMechId = data.postalContactMechId;
            addressInfo.telecomContactMechId = data.telecomContactMechId;
            addressInfo.emailContactMechId = data.emailContactMechId;
        }
    }
    getDirtyObj() {
        const dirtyObj = {};
        const addressInfo = this.addressInfo;

        const postalAddress = addressInfo.postalAddress;
        const addressFields = this.getAddressFields();
        for(let fieldName of addressFields) {
            if(postalAddress[fieldName] != this[fieldName]) dirtyObj[fieldName] = this[fieldName];
        }

        const telecomNumber = addressInfo.telecomNumber;
        const telecomFields = this.getTelecomFields();
        for(let fieldName of telecomFields) {
            if(telecomNumber[fieldName] != this[fieldName]) dirtyObj[fieldName] = this[fieldName];
        }
        if(addressInfo.emailAddress != this.emailAddress) {
            dirtyObj.emailAddress = this.emailAddress;
        }

        if(isObjectEmpty(dirtyObj)) {
            return null;
        }
        dirtyObj.postalContactMechId = addressInfo.postalContactMechId;
        dirtyObj.postalContactMechPurposeId = addressInfo.postalContactMechPurposeId;
        dirtyObj.telecomContactMechId = addressInfo.telecomContactMechId;
        dirtyObj.emailContactMechId = addressInfo.emailContactMechId;
        return dirtyObj;
    }

    save(dirtyObj = null) {
        if(dirtyObj === null || dirtyObj === undefined) {
            dirtyObj = this.getDirtyObj();
        }
        if(dirtyObj) {
            const isSubLoadingProcess = this.isLoading;
            this.isLoading = true;
            const self = this;
            return this.client.saveShippingAddrress(dirtyObj)
                .then((data) => {
                    self.onUpdated(data); 
                    if(!isSubLoadingProcess) self.invoke();
                    return self.addressInfo;
                })
                .catch((error) => {
                    alert(error.message); 
                    return null;
                });
        }
        return null;
    }
}
class CheckoutForm extends AddressForm{
    constructor(cartInfo, dialog, button, componentUrl) {
        super(dialog, button, componentUrl, new Cart(cartInfo));
    }
    init() {
        const self = this;
        return super.init().then(() => {
            if(self.button) {
                const paypalBtn = self.createPaypalButton();
                paypalBtn.render(self.button);
            } 
        });
    }
    open() {
        const cartInfo = this.client;
        if(!this.loggedIn) {
            const self = this;
            this.client.addCallback(() => {self.open();}, "isCartLoaded", true);
            if(this.loginForm) this.loginForm.open();
            else alert("Cart is not loaded");
            return;
        }
        super.open();
    }

    doCheckout(paymentData) {
        const addressInfo = this.addressInfo;
        if(!addressInfo || !addressInfo.postalContactMechId) {
            alert("Please fill in shipping address information");
            return false;
        }
        paymentData.postalContactMechId = addressInfo.postalContactMechId;
        paymentData.telecomContactMechId = addressInfo.telecomContactMechId;
        paymentData.carrierPartyId = this.carrierPartyId;
        paymentData.shipmentMethodEnumId = this.shipmentMethodEnumId;
        return this.client.checkout(paymentData);
    }
    checkout(paymentData) {
        this.isLoading = true;
        const dirtyAddress = this.getDirtyObj();
        if(dirtyAddress) {
            const self = this;
            return this.save().then(() => {
                self.isLoading = true;
                return self.doCheckout(paymentData);
            }).catch((error) => {
                //alert(error.message);
                console.log(error);
                return null;
            });
        }
        return this.doCheckout(paymentData);
    }
    createPaypalButton() {
        if(this.paypalBtn) {
            return this.paypalBtn;
        }
        const self = this;
        this.paypalBtn = paypal.Buttons({
            style: {
                layout: 'vertical',
                color: 'blue',
                shape: 'rect',
                label: 'paypal'
            },
            // Sets up the transaction when a payment button is clicked
            createOrder: function (data) {
                return self.checkout(data);
            },
            // Finalize the transaction after payer approval
            onApprove: function (data) {
// {
//     "orderID": "46A0181991189924V",
//     "payerID": "A5A3LAGYR8SLY",
//     "paymentID": "46A0181991189924V",
//     "billingToken": null,
//     "facilitatorAccessToken": "A21AAL-yxW0sexl-0Erd3Dk8Ek3lek3zwlvHWmy2Y3Fq3Ziu9wruFIY917eJ7cylrTUY3Mb3AfFuGAh-5CIO4lG6yOu85LxQw",
//     "paymentSource": "card"
// }
                return self.client.place(data)
                            .then((response) => { self.close(); })
                            .catch(error => alert(error.message));
            },
            onError: function (error) {
                // Do something with the error from the SDK
                alert(error);
            }
        });
        return this.paypalBtn;
    }
}

class Carousel {
    constructor(container, singleItem = false, timeout = 0) {
        this.current = 0;
        this.length = 0;
        this.singleItem = singleItem;
        this.timeout = timeout;
        this.container = container;
    }
    recalculate() {
        let children = this.container.children;
        this.length = children.length;
        if(!this.singleItem) {
            let leftOffsets = [];
            this.containerStyle = getComputedStyle(this.container)
            let x = 0;
            for(let i = 0; i < children.length; i++) {
                leftOffsets[i] = x;
                x += children[i].offsetWidth;
            }
            this.lastOffset = x;
            this.leftOffsets = leftOffsets;
        } 
    }
    next() {
        if(this.length === 0) {
            this.recalculate();
        }
        if(this.singleItem) {
            this.current++;
            if (this.current === this.length) this.current = 0;
            this.container.style.transform = "translateX(" + (-100*this.current) + "%)"
        } else {
            if(!this.offset) {
                this.offset = this.leftOffsets[this.current];
            }
            let rect = this.container.getBoundingClientRect();
            let maxOffset = this.lastOffset - rect.width;
            if(this.offset >= maxOffset) {
                this.offset = 0;
                this.current = 0;
            } else {
                this.offset += rect.width;
                let reachingTail = (this.offset > maxOffset);
                if(reachingTail) { // just gt, not gteq
                    this.offset = maxOffset;
                } 
                //search current by offset:
                for(; this.current < this.leftOffsets.length; this.current++) {
                    let curOffset = this.leftOffsets[this.current]
                    if(curOffset > this.offset) {
                        this.current --;
                        break;
                    } else if(curOffset == this.offset) {
                        break;
                    }
                    
                }
                if(!reachingTail) {
                    this.offset = this.leftOffsets[this.current]
                }
            }
            this.container.style.transform = "translateX(-" + this.offset + "px)"
        }
    }
    prev() {
        if(this.length === 0) {
            this.recalculate();
        }
        if(this.singleItem) {
            this.current--;
            if (this.current === -1) this.current = this.length - 1; 
            this.container.style.transform = "translateX(" + (-100*this.current) + "%)"
        } else {
            if(!this.offset) {
                this.offset = this.leftOffsets[this.current + 1];
            }

            let rect = this.container.getBoundingClientRect();
            let maxOffset = this.lastOffset - rect.width;
            if(this.offset == 0 || this.current == 0) {
                this.offset = maxOffset;
                for(this.current = this.length; this.current >= 0 && this.leftOffsets[this.current] > this.offset; this.current--);
            } else {
                this.offset -= rect.width;
                if(this.offset < 0) { // just gt, not gteq
                    this.offset = 0;
                    this.current = 0;
                } else {
                    for(; this.current > 0 && this.leftOffsets[this.current] > this.offset; this.current--);
                }
            }
            this.container.style.transform = "translateX(-" + this.offset + "px)"
        }
    }

}

class Wizard extends Executor {
    constructor() {
        super();
        this.viewIndex = 0;
        this.stepIndex = 0;
        /**
         * A map with key is the result code of previous step and value is the next step needed to be
         * done for that result
         */
        this.steps = [];
    }
    //currentStatus() {return this.statusCodes[this.statusCodes.length - 1]}
    update(closableDlg) {
        if(closableDlg.isOpen || !closableDlg.isDone || this.viewIndex == this.steps.length - 1) {
            return;
        }
        
        
        if(closableDlg.isChanged) {
            //Invalidate all dialogs behind
            for(let i = this.viewIndex + 1; i <= this.stepIndex; i++) {
                this.steps[i].isDone = false;
            }
            this.stepIndex = this.viewIndex; 
        }
        if(this.viewIndex <= this.stepIndex) {
            this.viewIndex++;
        }
        if(this.stepIndex < this.viewIndex) {
            this.stepIndex++;
        }
        this.steps[this.viewIndex].invoke();
    }
    next() {
        if(this.viewIndex < this.stepIndex){
            this.viewIndex++;
            this.invoke();
        } 
    }
    prev() {
        if(this.viewIndex > 0) {
            this.viewIndex--;
            this.invoke();
        }
    }
    invoke() {
        this.steps[this.viewIndex].invoke();
    }

    addStep(step) {
        let executor = (typeof step == "function") ? new Executor(step) : step;
        this.steps.push(executor);
        executor.attach(this)
    }
}
