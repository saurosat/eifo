const screenWidth = screen.width;
const jsonContentType = "application/json;charset=UTF-8";


String.prototype.hashCode = function() {
    var hash = 0,
      i, chr;
    if (this.length === 0) return hash;
    for (i = 0; i < this.length; i++) {
      chr = this.charCodeAt(i);
      hash = ((hash << 5) - hash) + chr;
      hash |= 0; // Convert to 32bit integer
    }
    return hash;
}

class BOClient extends Observable {
    constructor() {
        super();
    }

    setMetaProperty(key, value) {
        const meta = this.__BOClient__;
        const oldVal = meta[key];
        meta[key] = value;
        let callbacks = meta.on[key];
        if(callbacks && oldVal != value) {
            if(callbacks[value]) {
                const result = callbacks[value](this);
                if(!result) {
                    callbacks[value] = null;
                } else if(typeof result == "function") {
                    callbacks[value] = result;
                }
            } else {
                for(let i = 0; i < callbacks.length; i++) {
                    const callback = callbacks[i];
                    if(callback == null) {
                        continue;
                    }
                    const result = callback(this);
                    if(!result) {
                        callbacks[i] = null;
                    } else if(typeof result == "function") {
                        callback[i] = result;
                    }
                }
            }
        }
    }
    addCallback(func, key, value = null) {
        const meta = this.__BOClient__;
        if(meta.on[key] == null) {
            meta.on[key] = [];
        }
        const callbacks = meta.on[key];
        if(value == null) {
            callbacks[value] = func;
        } else {
            callbacks.push(func);
        }
    }

    getRequestConfig(method) {

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
        return { 
            headers: headers, 
            hostname: "localhost", 
            port: "8080", 
            protocol: "http:", 
            method: method 
        }
    }
}
// document.addEventListener('alpine:initialized', () => {
//     alert("initialized");
// });
function logout() {
    return Alpine.store("user").logout();
}

class UserAccount extends BOClient {
    constructor() {super();}

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
        this.contactMechId = cInfo.telecomNumber ? cInfo.telecomNumber.contactMechId : "";
        this.contactNumber = cInfo.telecomNumber ? cInfo.telecomNumber.contactNumber : "";
    }
    login(username, password) {
        if (username.length < 3 || password.length < 3) {
            return {error: "Username or password is missing"};
        }
        const ua = this;
        return LoginService.login({ username: this.username, password: this.password }, this.getRequestConfig('post'))
            .then((data) => {
                ua.setMetaProperty("loggedIn", true);
                ua.setInfo(data);
                ua.notifyAll();
                return {};
            })
            .catch((error) => {
                return {error: error.message }; //TODO: , statusCode: error.??
            });
    }
    loginAnonymous() {
        const ua = this;
        return LoginService.loginAnonymous({}, this.getRequestConfig('post'))
            .then((data) => {
                ua.setMetaProperty("loggedIn", true);
                ua.setInfo(data);
                ua.notifyAll();
                return {};
            })
            .catch((error) => {
                return {error: error.message }; //TODO: , statusCode: error.??
            });
    }
    logout() {
        const ua = this;
        return LoginService.logout().catch((error) => {
            return {error: error.message }; //TODO: , statusCode: error.??
        }).finally(() => {
            ua.setMetaProperty("token", sessionToken);
            ua.setMetaProperty("apiKey", '');
            ua.setMetaProperty("loggedIn", false);
    
            ua.username = '';
            ua.notifyAll();
        });
    }
    register() {
        //TODO 
    }
}
class Cart extends BOClient {
    constructor() {
        super();
        this.isLoaded = false;
        const self = this;
        this.addCallback(()=>{return self.load().then(() => true); }, "loggedIn", true)
        this.addCallback(()=>{self.reset(); return true; }, "loggedIn", false)
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
            this.addCallback(()=>{return self.load().then(() => true);}, "loggedIn", true)
            $dispatch('open-login');
            return self;
        }
        return ProductService.getCartInfo(this.getRequestConfig("post"))
                .then((data) => {
                    self.reset();
                    self.assign(data);
                    self.isLoaded = true;
                    return self;
                });
    }
    addProduct(product, quantity = 1) {
        const self = this;
        if(!this.loggedIn) {
            this.addCallback(()=>{return self.addProduct(product, quantity).then(() => false);}, "loggedIn", true)
            $dispatch('open-login');
            return self;
        }

        return ProductService.addProductCart(product, this.getRequestConfig("post"))
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
        return ProductService.checkoutCartOrder(body, this.getRequestConfig("post")).then(function (data) {
            self.paymentId = data.paymentId;
            self.paypalOrderId = data.paypalOrderId;
            return data.paypalOrderId;
        });
    }
    createPaypalButton() {
        if(this.paypalBtn) {
            return this.paypalBtn;
        }
        const cart = this;
        this.paypalBtn = paypal.Buttons({
            style: {
                layout: 'vertical',
                color: 'blue',
                shape: 'rect',
                label: 'paypal'
            },
            // Sets up the transaction when a payment button is clicked
            createOrder: function (data) {
                return cart.checkout(data);
            },
            // Finalize the transaction after payer approval
            onApprove: function (data) {
                return fetch(`myserver.com/api/orders/${data.orderID}/capture`, {
                    method: "POST",
                }).then((response) => response.json())
                    .then((orderData) => {
                        // Successful capture! For dev/demo purposes:
                        console.log(
                            "Capture result",
                            orderData,
                            JSON.stringify(orderData, null, 2),
                        );
                        var transaction = orderData.purchase_units[0].payments.captures[0];
                        // Show a success message within this page. For example:
                        // var element = document.getElementById('paypal-button-container');
                        // element.innerHTML = '<h3>Thank you for your payment!</h3>';
                        // Or go to another URL: actions.redirect('thank_you.html');
                    });
            },
            onError: function (error) {
                // Do something with the error from the SDK
            }
        });
        return this.paypalBtn;
    }
}
document.addEventListener('alpine:init', () => {
    BOClient.prototype.token = Alpine.$persist(sessionToken).using(sessionStorage);
    BOClient.prototype.store = Alpine.$persist(storeId).using(sessionStorage);
    BOClient.prototype.apiKey = Alpine.$persist('').using(sessionStorage);
    BOClient.prototype.loggedIn = Alpine.$persist(false).using(sessionStorage);
    BOClient.prototype.on = {};
    BOClient.prototype.__BOClient__ = BOClient.prototype;
    Alpine.store('__BOClient__', BOClient.prototype);   

    const userAccount = new UserAccount();
    userAccount.username = Alpine.$persist('').using(sessionStorage);
    userAccount.userId = Alpine.$persist('').using(sessionStorage);
    userAccount.partyId = Alpine.$persist('').using(sessionStorage);
    userAccount.firstName = Alpine.$persist('_NA_').using(sessionStorage);
    userAccount.lastName = Alpine.$persist('_NA_').using(sessionStorage);
    userAccount.locale = Alpine.$persist('').using(sessionStorage);
    userAccount.emailAddress = Alpine.$persist('_NA_').using(sessionStorage);
    userAccount.contactMechId = Alpine.$persist('').using(sessionStorage);
    userAccount.contactNumber = Alpine.$persist('').using(sessionStorage);
    Alpine.store('user', userAccount);

    const cartInfo = new Cart();
    cartInfo.paymentsTotal = Alpine.$persist(0);
    cartInfo.orderPromoCodeDetailList = Alpine.$persist([]);
    cartInfo.paymentInfoList = Alpine.$persist([]);
    cartInfo.orderItemList = Alpine.$persist([]);
    cartInfo.orderItemWithChildrenSet = Alpine.$persist([]);
    cartInfo.totalUnpaid = Alpine.$persist(0);
    cartInfo.orderPart = Alpine.$persist({});
    cartInfo.orderHeader = Alpine.$persist({});
    cartInfo.productsQuantity = Alpine.$persist(0);
    Alpine.store('cartInfo', cartInfo);

    Alpine.data('cartDialog', (ele, btn) => {
        const cartDialog = new Dialog(ele, btn);
        cartDialog.store = Alpine.store('cartInfo');
        cartDialog.init = function() {
            if(this.button) {
                const paypalBtn = this.store.createPaypalButton();
                paypalBtn.render(this.button);
            } 
        }
        return cartDialog;
    });

    Alpine.data('searchObj', () => ({
        cat: 'All',
        query: '',
        adjustSize() {
            const sel = this.$refs.panelSelect;
            sel.style.width = (sel.options[sel.selectedIndex].text.length + 5) + 'ex'
            const maxWidth = screenWidth / 3
            if (sel.clientWidth > maxWidth) {
                sel.style.width = maxWidth + "px";
            }
        },
        search() {

        }
    }));
    Alpine.data('userLogin', (dialog, componentUrl) => {
        const loginDialog = new Dialog(dialog);
        loginDialog.store = Alpine.store("user");
        loginDialog.init = function() {
            this.isDone = this.store.loggedIn;
            this.username = this.store.username;
            this.password = null;
            this.errorMsg = null;
            this.reqCfg = getReqCfg("post", userAccount);
            if(componentUrl) {
                loadHtml(this.dialog, componentUrl);
            }
        }

        loginDialog.login = function() {
            this.isLoading = true;
            const self = this;
            const store = this.store;
            return store.login(this.username, this.password).then((result) => {
                if(result.error) {
                    alert(result.error);
                }
                self.invoke();
            });
        }
        loginDialog.loginAnonymous = function() {
            this.isLoading = true;
            const self = this;
            const store = this.store;
            return store.loginAnonymous().then((result) => {
                if(result.error) {
                    alert(result.error);
                }
                self.invoke();
            });
        }
        return loginDialog;
    });
    Alpine.data('Promotion', () => ({
        discount: "",
        title: "",
        shortDesc: "",
        actionText: "",
        actionLink: "",
        set(promotionObj) {
            this.discount = promotionObj.discount;
            this.title = promotionObj.title;
            this.shortDesc = promotionObj.shortDesc;
            this.actionText = promotionObj.actionText;
            this.actionLink = promotionObj.actionLink;
        }
    }));
});