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

function handleResponse(response) {
    return response.data;
}
class BOClient {
    static {
        this.setMetaObject({});
    }
    static setMetaObject(meta) {
        const proto = BOClient.prototype;
        for(const key in meta) {
            Object.defineProperty(proto, key, {
                get: function() { return proto.meta[key]; }
            })
        }
        meta.proto = proto;
        proto.on = {};
        proto.meta = meta;
    }
    constructor() {
        this.axios = axios.create({
            baseURL: 'http://localhost:8080/rest/s1/foi',
            //timeout: 1000,
            withCredentials: true
        });
        this.handleResponse = function(response) {
            return res
        }
    }
    get(url) {
        return this.axios.get(url, this.getRequestConfig()).then(handleResponse);
    }
    put(url, data) {
        return this.axios.put(url, data, this.getRequestConfig()).then(handleResponse);
    }
    post(url, data) {
        return this.axios.post(url, data, this.getRequestConfig()).then(handleResponse);
    }
    delete(url) {
        return this.axios.delete(url, this.getRequestConfig()).then(handleResponse);
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

    setMetaProperty(key, value) {
        const meta = this.meta;
        const oldVal = meta[key];
        const proto = meta.proto;
        // const oldVal = meta[key];
        meta[key] = value;
        if(!proto.hasOwnProperty(key)) {
            Object.defineProperty(proto, key, {
                get: function() { return proto.meta[key]; }
            })
        }
        let callbackStack = proto.on[key];
        if(callbackStack && oldVal != value) {
            invokeCallbackStack(callbackStack, value);
        }
    }
    addCallback(func, key, value = null, callbackId = null) {
        const meta = this.meta;
        //const oldVal = meta[key];
        const proto = meta.proto;
        if(proto.on[key] == null) {
            proto.on[key] = [];
        }
        const callbacks = proto.on[key];
        if(callbackId) {
            for(let i = callbacks.length - 1; i >= 0; i--) {
                if(callbacks[i].id == callbackId) {
                    callbacks.splice(i, 1);
                }
            }
        }
        callbacks.push({value: value, func: func, id: callbackId});
    }

    getRequestConfig() {

        let headers = { 
            "Content-Type": "application/json;charset=UTF-8", 
            "store": this.store, 
            "moquiSessionToken": Alpine.raw(this.token), 
            "SessionToken" : this.token, 
            "X-CSRF-Token": this.token 
        };
        if(this.apiKey != null) {
            headers["api_key"] = this.apiKey;
        }
        return {headers: headers};
    }
}

class UserAccount extends BOClient {
    constructor() {
        super();
        this.postalAddressMap = {};
    }

    setInfo(data) {
        if(data.moquiSessionToken) {
            this.setMetaProperty("token", data.moquiSessionToken);
        }
        if(data.apiKey) {
            this.setMetaProperty("apiKey", data.apiKey);
        }

        let cInfo = data.customerInfo;
        this.username = !cInfo.username ? "" : cInfo.username;
        this.userId = !cInfo.userId ? "" : cInfo.userId;
        this.partyId = !cInfo.partyId ? "" : cInfo.partyId;
        this.firstName = !cInfo.firstName ? "" : cInfo.firstName;
        this.lastName = !cInfo.lastName ? "" : cInfo.lastName;
        this.locale = !cInfo.locale ? "" : cInfo.locale;
        this.emailAddress = !cInfo.emailAddress ? "" : cInfo.emailAddress;
        //this.postalAddressList = cInfo.postalAddressList ? cInfo.postalAddressList : [];
        if(cInfo.postalAddressList) {
            for(const postalAddress of cInfo.postalAddressList) {
                this.postalAddressMap[postalAddress.postalContactMechId] = postalAddress;
            }
        }
    }

    logout() {
        const ua = this;
        return this.get("/logout")
        .then(() => {
            ua.setMetaProperty("token", sessionToken);
            ua.setMetaProperty("apiKey", '');
            ua.setMetaProperty("loggedIn", false);
            ua.username = '';
            ua.userId = '';
            ua.partyId = '';
            ua.firstName = '';
            ua.lastName = '';
            ua.locale = '';
            ua.emailAddress = '';
            ua.contactMechId = '';
            ua.contactNumber = '';
        
        })
        .catch((error) => {
            return {error: error.message }; //TODO: , statusCode: error.??
        });
    }
    register() {
        //TODO 
    }
}
class Cart extends BOClient {
    constructor() {
        super();
        this.setMetaProperty("isCartLoaded", false);
        const self = this;
        this.addCallback(()=>{self.reset(); return true; }, "loggedIn", false, "resetCart");
        this.addLoadCallback();
    }
    addLoadCallback() {
        const self = this;
        this.addCallback(()=>{return self.load().then(() => true); }, "loggedIn", true, "loadCart");
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
        const self = this;
        if(!this.loggedIn) {
            alert("Cart is not loaded");
            return self;
        }
        return this.get("/cart/info?timeStamp\x3d" + (new Date).getTime())
                .then((data) => {
                    self.reset();
                    self.assign(data);
                    self.setMetaProperty("isCartLoaded", true);
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
        return this.post("/cart/checkout", body, this.getRequestConfig()).then(function (data) {
            self.paymentId = data.paymentId;
            self.paypalOrderId = data.paypalOrderId;
            return data.paypalOrderId;
        });
    }
    place(data) {
    }

}

class LazyList extends BOClient {
    constructor(loader) {
        this.items = loader();
    }
}

class Executor extends BOClient {
    constructor(callable) {
        super()
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
    constructor(userAccount, dialog, componentUrl) {
        super(dialog, null, componentUrl);
        this.userAccount = userAccount;
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

    doLogin(url, loginData) {
        this.isLoading = true;
        const self = this;
        const userAccount = this.userAccount;
        return this.post(url, loginData)
            .then((data) => {
                userAccount.setInfo(data);
                self.errorMsg = "";
                self.invoke();
                userAccount.setMetaProperty("loggedIn", true);
            })
            .catch((error) => {
                this.errorMsg = error.message;
                alert(this.errorMsg);
            });
    }
    login() {
        if (this.username.length < 3 || this.password.length < 3) {
            this.errorMsg = "Username or password is missing";
            alert(this.errorMsg);
            return;
        }
        return this.doLogin("/login", { username: this.username, password: this.password });
    }
    loginAnonymous() {
        return this.doLogin("/loginAnonymous", {});
    }
}

class AddressForm extends Dialog {
    constructor(dialog, button, componentUrl, addressInfo) {
        super(dialog, button, componentUrl);
        this.addressInfo = addressInfo ? addressInfo : this.newAddressInfo();
        for(let fieldName of this.getAddressFields()) {
            this[fieldName] = "";
        }
        for(let fieldName of this.getTelecomFields()) {
            this[fieldName] = "";
        }
        this.emailAddress = "";
        this.postalContactMechId = "_NA_";
        this.countryGeoId = "_NA_";
        this.stateProvinceGeoId = "_NA_"
        this.telecomContactMechId = "";
        this.emailContactMechId = "";
        this.emailAddress = "";
        this.addressMap = {};
    }
    newAddressInfo() {
        return {postalContactMechPurposeId: "PostalShippingDest", postalAddress: {}, telecomNumber: {}};
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
        if(!this.addressInfo) {
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
        if(!postalAddress.contactMechId) {
            postalAddress.contactMechId = data.postalContactMechId;
        }

        const telecomNumber = addressInfo.telecomNumber;
        const telecomFields = this.getTelecomFields();
        for(let fieldName of telecomFields) {
            telecomNumber[fieldName] = this[fieldName];
        }
        if(!telecomNumber.contactMechId) {
            telecomNumber.contactMechId = data.telecomContactMechId;
        }

        if(!addressInfo.postalContactMechId) {
            addressInfo.postalContactMechId = data.postalContactMechId;
            addressInfo.telecomContactMechId = data.telecomContactMechId;
            addressInfo.emailContactMechId = data.emailContactMechId;
            this.addressMap[addressInfo.postalContactMechId] = addressInfo;
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
            return this.put("/customer/shippingAddresses", dirtyObj)
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
        super(dialog, button, componentUrl);
        this.cartInfo = cartInfo;
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
        const cartInfo = this.cartInfo;
        if(!this.loggedIn) {
            const self = this;
            this.cartInfo.addCallback(() => {self.open();}, "isCartLoaded", true);
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
        return this.cartInfo.checkout(paymentData);
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
                return self.post("/cart/place", data)
                            .then(() => {self.cartInfo.reset(); self.close(); })
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
